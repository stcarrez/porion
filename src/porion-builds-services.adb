-----------------------------------------------------------------------
--  porion-builds-services -- build service to manage builds
--  Copyright (C) 2021, 2022 Stephane Carrez
--  Written by Stephane Carrez (Stephane.Carrez@gmail.com)
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
-----------------------------------------------------------------------
with Ada.Calendar;
with Ada.Directories;
with Ada.Containers.Hashed_Maps;
with Util.Log.Loggers;
with Util.Strings;
with Util.Files;
with Util.Serialize.IO.JSON;
with Util.Properties;
with Util.Systems.Os;
with Util.Strings.Formats;
with ADO.Statements;
with ADO.Queries;
with ADO.Objects;
with ADO.SQL;
with ADO.Utils;
with ADO.Sessions;
with Porion.Logs;
with Porion.Sources;
with Porion.Nodes.Models;
with Porion.Nodes.Services;
with Porion.Projects.Models;
with Porion.Builders;
package body Porion.Builds.Services is

   use type Ada.Calendar.Time;
   use type ADO.Identifier;
   use type Porion.Nodes.Usage_Type;
   use type Porion.Builds.Models.Execution_Type;
   use type Porion.Builds.Models.Build_Status_Type;

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builds.Services");

   procedure Start_Build (Service     : in out Context_Type;
                          Recipe      : in Porion.Builds.Models.Recipe_Ref;
                          Executor    : in out Porion.Executors.Executor_Type'Class) is
      Query         : ADO.Queries.Context;
      Found         : Boolean;
      Updated       : Boolean;
      Create_Reason : Boolean := False;
   begin
      Service.Recipe := Recipe;
      Service.Build_Node := Porion.Nodes.Models.Node_Ref (Recipe.Get_Node);
      Service.Branch := Porion.Projects.Models.Branch_Ref (Recipe.Get_Branch);
      if Service.Build_Node.Is_Null then
         Nodes.Services.Load_Default_Node (Service);
      end if;

      Service.Ident.Name := To_UString (Service.Project.Get_Name);
      Service.Ident.Branch := To_UString (Service.Branch.get_Name);
      Service.Ident.Recipe := To_UString (Service.Recipe.Get_Name);
      Service.Ident.Node := To_UString (Service.Build_Node.get_Name);

      Service.Build := Porion.Builds.Models.Null_Build;
      Service.Build.Set_Number (Service.Branch.Get_Last_Build_Number + 1);

      Service.Build.Set_Project (Service.Project);
      Service.Build.Set_Branch (Service.Branch);
      Service.Build.Set_Node (Service.Build_Node);
      Service.Build.Set_Recipe (Service.Recipe);
      Service.Build.Set_Tag (String '(Service.Branch.Get_Tag));
      Service.Build.Set_Create_Date (Ada.Calendar.Clock);
      if not Executor.Is_Dry_Run then
         Service.Build.Save (Service.DB);
         Service.Branch.Reload (Service.Db, Updated);
         Service.Branch.Set_Last_Build_Number (Service.Build.Get_Number);
         Service.Branch.Save (Service.DB);

         --  Get or create a build queue entry for the recipe.
         if Service.Queue.Is_Null then
            Query.Clear;
            Query.Set_filter ("o.recipe_id = :recipe_id");
            Query.Bind_Param ("recipe_id", Recipe.Get_Id);
            Service.Queue.Find (Service.DB, Query, Found);
            if not Found then
               Service.Queue.Set_Recipe (Service.Recipe);
               Service.Queue.Set_Node (Service.Build_Node);
               Service.Queue.Set_Create_Date (Service.Build.Get_Create_Date);
               Create_Reason := True;
            end if;
         end if;
         Service.Queue.Set_Update_Date (Service.Build.Get_Create_Date);
         Service.Queue.Set_Building (True);
         Service.Queue.Save (Service.DB);
         if Create_Reason then
            declare
               Reason : Models.Build_Reason_Ref;
            begin
               Reason.Set_Queue (Service.Queue);
               Reason.Set_Create_Date (Service.Queue.Get_Create_Date);
               Reason.Set_Reason (Models.REASON_MANUAL);
               Reason.Save (Service.DB);
            end;
         end if;
         Update_Build_Reason (Service, Is_Finished => False);
         Service.DB.Commit;
      else
         Service.DB.Rollback;
         Service.Queue := Porion.Builds.Models.Null_Build_Queue;
      end if;

      Log.Info ("Created build{0} for {1}", Natural'Image (Service.Build.Get_Number),
                Service.Project.Get_Name);
   end Start_Build;

   procedure Build (Service  : in out Context_Type;
                    Executor : in out Porion.Executors.Executor_Type'Class;
                    Found    : out Boolean) is
      Query  : ADO.Queries.Context;
      Recipe : Porion.Builds.Models.Recipe_Ref;
   begin
      if not Service.Build_Node.Is_Null then
         Query.Set_Filter ("o.building = 0 AND o.node_id = :node_id "
                           & " ORDER BY o.`order` ASC LIMIT 1");
         Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
      else
         Query.Set_Filter ("o.building = 0 ORDER BY o.`order` ASC LIMIT 1");
      end if;
      Service.Queue.Find (Service.DB, Query, Found);
      if not Found then
         Log.Info ("Build queue is empty");
         return;
      end if;

      begin
         Recipe := Builds.Models.Recipe_Ref (Service.Queue.Get_Recipe);
         Service.Project := Projects.Models.Project_Ref (Recipe.Get_Project);
         Service.Branch := Projects.Models.Branch_Ref (Recipe.Get_Branch);
         Service.Build_Node := Nodes.Models.Node_Ref (Recipe.Get_Node);

      exception
         when ADO.Objects.Not_Found =>
            Service.Queue.Delete (Service.DB);
            return;
      end;

      Build (Service, Recipe, Executor);
   end Build;

   procedure Build (Service  : in out Context_Type;
                    Recipe   : in Porion.Builds.Models.Recipe_Ref;
                    Executor : in out Porion.Executors.Executor_Type'Class) is
      Steps : Build_Step_Vector;
   begin
      Start_Build (Service, Recipe, Executor);

      Load_Recipe (Service, Recipe, Steps);

      Build (Service, Steps, Executor);
   end Build;

   function Get_Build_Directory (Service : in Context_Type) return String is
      Name        : constant String := Service.Project.Get_Name;
      Branch_Name : constant String := Service.Branch.Get_Name;
      Repository  : constant String := Service.Build_Node.Get_Repository_Dir;
   begin
      if Repository'Length > 0 then
         return Util.Files.Compose (Repository, Util.Files.Compose (Name, Branch_Name));
      else
         return Configs.Get_Build_Directory (Name, Branch_Name);
      end if;
   end Get_Build_Directory;

   --  ------------------------------
   --  Get the directory that contains the logs for the build.
   --  ------------------------------
   function Get_Log_Directory (Service : in Context_Type) return String is
      Name        : constant String := Service.Project.Get_Name;
      Branch_Name : constant String := Service.Branch.Get_Name;
   begin
      return Configs.Get_Build_Log_Directory (Name, Branch_Name, Service.Build.Get_Number);
   end Get_Log_Directory;

   procedure Build (Service     : in out Context_Type;
                    Steps       : in Build_Step_Vector;
                    Executor    : in out Porion.Executors.Executor_Type'Class) is
      Ident       : constant String := Projects.To_String (Service.Ident);
      Branch_Name : constant String := Service.Branch.Get_Name;
      Path        : constant String := Get_Build_Directory (Service);
      Log_Dir     : constant String := Get_Log_Directory (Service);
      Config      : Util.Properties.Manager;
      Status      : Builds.Models.Build_Status_Type := Builds.Models.BUILD_RUNNING;
      Usage       : Nodes.Usage_Type := (others => 0);
      Env         : Util.Strings.Maps.Map;
   begin
      Log.Info ("Build {0} in {1}", Ident, Path);

      Load_Environment (Service, Service.Recipe, Env);

      Executor.Set_Build_Node (Service.Build_Node, Env);

      Executor.Set_Step (Builds.STEP_CHECKOUT);
      if not Executor.Is_Dry_Run then
         Executor.Create_Directory (Path, False);
      end if;

      Config.Set ("branch", Branch_Name);
      Config.Set ("repository_url", String '(Service.Project.Get_Scm_Url));
      Config.Set ("build_dir", Path);

      Executor.Create_Logger (Log_Dir, "build.log");
      Executor.Log (Porion.Logs.LOG_INFO, "Build '" & Ident & "' in " & Path);
      Porion.Sources.Checkout (Service.Project.Get_Scm, Config, Path, Executor);

      for Step of Steps loop
         if Step.Step.Get_Execution /= Builds.Models.EXEC_DISABLED then
            declare
               Exec_Step   : Builds.Models.Build_Step_Ref;
               Step_Status : Integer;
            begin
               if not Executor.Is_Dry_Run then
                  Exec_Step.Set_Start_Date (Ada.Calendar.Clock);
                  Exec_Step.Set_Build (Service.Build);
                  Exec_Step.Set_Recipe_Step (Step.Step);
                  Exec_Step.Save (Service.DB);
               end if;
               Executor.Set_Step (Step.Step.Get_Step);
               Executor.Set_Status (0);
               Builders.Run (Step.Step.Get_Builder, Service.DB, Step.Config,
                             Service.Build, Path, Executor);

               if not Executor.Is_Dry_Run then
                  declare
                     Finish     : constant Ada.Calendar.Time := Ada.Calendar.Clock;
                     Time       : constant Duration := Finish - Exec_Step.Get_Start_Date;
                     New_Usage  : constant Nodes.Usage_Type := Executor.Get_Usage;
                     Step_Usage : constant Nodes.Usage_Type := New_Usage - Usage;
                  begin
                     Usage := New_Usage;
                     Step_Status := Executor.Get_Status;
                     Exec_Step.Set_Exit_Status (Step_Status);
                     Exec_Step.Set_End_Date ((Is_Null => False, Value => Finish));
                     Exec_Step.Set_Step_Duration (Millisecond_Type (Time * 1_000.0));
                     Exec_Step.Set_User_Time (Millisecond_Type (Step_Usage.User_Time));
                     Exec_Step.Set_Sys_Time (Millisecond_Type (Step_Usage.Sys_Time));
                     Exec_Step.Save (Service.DB);
                  end;
                  if Step_Status /= 0
                    and Step.Step.Get_Execution = Builds.Models.EXEC_NO_ERROR
                  then
                     Status := Porion.Builds.Models.BUILD_FAIL;
                     exit;
                  end if;
               end if;
            end;
         end if;
      end loop;

      if not Executor.Is_Dry_Run then
         if Status = Builds.Models.BUILD_RUNNING then
            Status := Builds.Models.BUILD_PASS;
         end if;

         --  Save the resource usage in the build.
         declare
            Usage   : constant Nodes.Usage_Type := Executor.Get_Usage;
            Updated : Boolean;
         begin
            Service.Build.Reload (Service.DB, Updated);
            Service.Build.Set_User_Time (Millisecond_Type (Usage.User_Time));
            Service.Build.Set_Sys_Time (Millisecond_Type (Usage.Sys_Time));
         end;
         Update_Build (Service, Status);
      end if;
   end Build;

   --  ------------------------------
   --  Cancel the building status on the build queues for the given node.
   --  ------------------------------
   procedure Cancel_Building (Service : in out Context_Type;
                              Node    : in String) is
      Query : ADO.Queries.Context;
      List  : Porion.Builds.Models.Build_Queue_Vector;
   begin
      Log.Info ("Cancel building status for build node {0}", Node);

      Query.Set_Filter ("o.building = 1 AND o.node_id = :node_id");
      Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
      Porion.Builds.Models.List (List, Service.DB, Query);
      for Queue of List loop
         Queue.Set_Building (False);
         Queue.Save (Service.DB);
      end loop;
   end Cancel_Building;

   procedure Build_Queue (Service : in out Context_Type;
                          Node    : in String) is
      Build_Executor : Porion.Builds.Models.Build_Executor_Ref;
      Query          : ADO.Queries.Context;
      Found          : Boolean;
      Executor       : Porion.Executors.Executor_Type;
   begin
      Log.Info ("Building queue for build node {0}", Node);

      Nodes.Services.Load_Node (Service, Node);
      Query.Set_Filter ("o.node_id = :node_id");
      Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
      Build_Executor.Find (Service.DB, Query, Found);
      if Found then
         if Util.Systems.Os.Sys_Kill (Build_Executor.Get_Pid, 0) = 0 then
            Log.Info ("A build executor is already running for {0} under pid {1}",
                      Node, Util.Strings.Image (Build_Executor.Get_Pid));
            return;
         end if;
      end if;

      --  First, cancel the building status because we know there is no executor
      --  running for this build node.
      Cancel_Building (Service, Node);

      Build_Executor.Set_Pid (Util.Systems.Os.Sys_Getpid);
      Build_Executor.Set_Node (Service.Build_Node);
      Build_Executor.Set_Start_Date (Ada.Calendar.Clock);
      Build_Executor.Save (Service.DB);

      loop
         Service.Project := Projects.Models.Null_Project;
         Build (Service, Executor, Found);
         exit when not Found;
      end loop;

      Build_Executor.Delete (Service.DB);
   end Build_Queue;

   --  ------------------------------
   --  Returns True if the recipe is contained in the build queue.
   --  ------------------------------
   function Contains (List   : in Porion.Builds.Models.Build_Queue_Vector;
                      Recipe : in Porion.Builds.Models.Recipe_Ref) return Boolean is
      (for some Queue of List => Queue.Get_Recipe.Get_Id = Recipe.Get_Id);

   --  ------------------------------
   --  Update the build queue to trigger builds and/or re-order the build queue according
   --  to the build dependency.
   --  ------------------------------
   procedure Update_Build_Queue (Service : in out Context_Type;
                                 Trigger_Builds : in Boolean) is

      package Map_Depends is
        new Ada.Containers.Hashed_Maps (Key_Type => ADO.Identifier,
                                        Element_Type => ADO.Utils.Identifier_Vector,
                                        Hash => ADO.Utils.Hash,
                                        Equivalent_Keys => ADO."=",
                                        "=" => ADO.Utils.Identifier_Vectors."=");

      function Get_Dependencies (Queue : in Models.Build_Queue_Ref) return Map_Depends.Cursor;
      function "<" (Left, Right : in Models.Build_Queue_Ref) return Boolean;

      Recipes : Porion.Builds.Models.Recipe_Vector;
      Queues  : Porion.Builds.Models.Build_Queue_Vector;
      Query   : ADO.Queries.Context;
      Deps    : Map_Depends.Map;

      function Get_Dependencies (Queue : in Models.Build_Queue_Ref) return Map_Depends.Cursor is
         Recipe : constant Models.Recipe_Ref'Class := Queue.Get_Recipe;
         Id     : constant ADO.Identifier := Recipe.Get_Project.Get_Id;
         Pos    : Map_Depends.Cursor := Deps.Find (Id);
      begin
         if not Map_Depends.Has_Element (Pos) then
            declare
               List : ADO.Utils.Identifier_Vector;
               Stmt : ADO.Statements.Query_Statement :=
                  Service.DB.Create_Statement ("SELECT d.project_id FROM porion_dependency AS d "
                                               & "WHERE d.owner_id = :project_id");
            begin
               Stmt.Bind_Param ("project_id", Id);
               Stmt.Execute;
               while Stmt.Has_Elements loop
                  List.Append (Stmt.Get_Identifier (0));
                  Stmt.Next;
               end loop;
               Deps.Include (Id, List);
               Pos := Deps.Find (Id);
            end;
         end if;
         return Pos;
      end Get_Dependencies;

      function "<" (Left, Right : in Models.Build_Queue_Ref) return Boolean is
         Left_Deps  : Map_Depends.Cursor;
         Right_Deps : Map_Depends.Cursor;
      begin
         Left_Deps  := Get_Dependencies (Left);
         Right_Deps := Get_Dependencies (Right);
         if Left.Get_Node.Get_Id = Right.Get_Node.Get_Id then
            if Map_Depends.Has_Element (Left_Deps) and Map_Depends.Has_Element (Right_Deps) then
               if Map_Depends.Element (Left_Deps).Contains (Map_Depends.Key (Right_Deps)) then
                  return False;
               end if;
               if Map_Depends.Element (Right_Deps).Contains (Map_Depends.Key (Left_Deps)) then
                  return True;
               end if;
            end if;
         end if;

         --  Left and Right don't depend on each other: sort on the creation date.
         return Left.Get_Create_Date < Right.Get_Create_Date;

      exception
         when ADO.Objects.Not_Found =>
            return Left.Get_Create_Date < Right.Get_Create_Date;
      end "<";

      package Sort_Queue is
         new Models.Build_Queue_Vectors.Generic_Sorting ("<" => "<");

   begin
      --  Step 1: find the recipes that depend on the project that was built.
      if Trigger_Builds then
         Query.Set_Join ("INNER JOIN porion_dependency AS dep ON o.project_id = dep.owner_id");
         Query.Set_Filter ("dep.project_id = :project_id AND o.node_id = :node_id");
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
         Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
         Porion.Builds.Models.List (Recipes, Service.DB, Query);

         Log.Info ("Found {0} recipes triggered by dependencies",
                   Util.Strings.Image (Natural (Recipes.Length)));
         if Recipes.Is_Empty then
            return;
         end if;
         Query.Clear;
      end if;

      --  Step 2: get the current build queue for the current build node.
      if Trigger_Builds then
         Query.Set_Filter ("o.node_id = :node_id ORDER BY o.`order`");
         Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
      end if;
      Porion.Builds.Models.List (Queues, Service.DB, Query);

      --  Step 3: check and add the triggered recipes in the build queue.
      if Trigger_Builds then
         declare
            Now : constant Ada.Calendar.Time := Ada.Calendar.Clock;
         begin
            for Recipe of Recipes loop
               if not Contains (Queues, Recipe) then
                  declare
                     Queue : Porion.Builds.Models.Build_Queue_Ref;
                  begin
                     Queue.Set_Recipe (Recipe);
                     Queue.Set_Node (Service.Build_Node);
                     Queue.Set_Create_Date (Now);
                     Queues.Append (Queue);
                  end;
               end if;
            end loop;
         end;
      end if;

      --  Step 4: reorder the build queue according to project dependencies.
      Sort_Queue.Sort (Queues);

      --  Step 5: save the new build queue order.
      declare
         Order : Natural := 0;
      begin
         for Queue of Queues loop
            Queue.Set_Order (Order);
            Queue.Save (Service.DB);
            Order := Order + 1;
         end loop;
      end;
   end Update_Build_Queue;

   --  ------------------------------
   --  Update the build reason when starting the build or once it is finished.
   --  ------------------------------
   procedure Update_Build_Reason (Service     : in out Context_Type;
                                  Is_Finished : in Boolean) is
      List   : Builds.Models.Build_Reason_Vector;
      Query  : ADO.Queries.Context;
   begin
      Query.Set_Filter ("o.queue_id = :queue_id");
      Query.Bind_Param ("queue_id", Service.Queue.Get_Id);
      Builds.Models.List (List, Service.DB, Query);

      for Reason of List loop
         if Is_Finished then
            Reason.Set_Queue (Builds.Models.Null_Build_Queue);
         else
            Reason.Set_Build (Service.Build);
         end if;
         Reason.Save (Service.DB);
      end loop;
   end Update_Build_Reason;

   procedure Update_Build (Service : in out Context_Type;
                           Status  : in Builds.Models.Build_Status_Type) is
      procedure Update_Last;

      Last_Builds : Builds.Models.Last_Build_Vector;
      Query       : ADO.Queries.Context;

      procedure Update_Last is
         Found : Boolean := False;
      begin
         for Last_Build of Last_Builds loop
            if Last_Build.Get_Status = Status then
               Last_Build.Set_Build (Service.Build);
               Last_Build.Set_Last_Build (True);
               Last_Build.Save (Service.DB);
               Found := True;
            elsif Last_Build.Get_Last_Build then
               Last_Build.Set_Last_Build (False);
               Last_Build.Save (Service.DB);
            end if;
         end loop;

         if not Found then
            declare
               Last_Build : Models.Last_Build_Ref;
            begin
               Last_Build.Set_Status (Status);
               Last_Build.Set_Build (Service.Build);
               Last_Build.Set_Recipe (Service.Recipe);
               Last_Build.Set_Branch (Service.Branch);
               Last_Build.Set_Last_Build (True);
               Last_Build.Save (Service.DB);
            end;
         end if;
      end Update_Last;

      Now  : constant Ada.Calendar.Time := Ada.Calendar.Clock;
      Time : constant Duration := Now - Service.Build.Get_Create_Date;
   begin
      Service.DB.Begin_Transaction;
      Service.Build.Set_Status (Status);
      Service.Build.Set_Finish_Date ((Is_Null => False,
                                      Value   => Now));
      Service.Build.Set_Build_Duration (Millisecond_Type (Time * 1_000.0));
      Service.Build.Save (Service.DB);

      Query.Set_Filter ("o.recipe_id = :config_id"
                        & " AND o.branch_id = :branch_id");
      Query.Bind_Param ("config_id", Service.Recipe.Get_Id);
      Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
      Porion.Builds.Models.List (Last_Builds, Service.DB, Query);

      Update_Last;

      case Status is
         when Builds.Models.BUILD_PASS =>
            Service.Recipe.Set_Status (Builds.Models.CONFIG_BUILD_PASS);
            Service.Recipe.Save (Service.DB);
            Update_Build_Queue (Service, Trigger_Builds => True);

         when Builds.Models.BUILD_FAIL =>
            Service.Recipe.Set_Status (Builds.Models.CONFIG_BUILD_FAIL);
            Service.Recipe.Save (Service.DB);

         when others =>
            null;

      end case;

      --  Build is finished, remove the queue
      if not Service.Queue.Is_Null then
         Update_Build_Reason (Service, Is_Finished => True);
         Service.Queue.Delete (Service.DB);
         Service.Queue := Porion.Builds.Models.Null_Build_Queue;
      end if;

      Update_Branch_Ratings (Service);
      Update_Project_Ratings (Service);
      Service.DB.Commit;
   end Update_Build;

   function To_Permille (Value, Total : in Natural) return Permille_Type is
      (Permille_Type ((Value * 1000) / Total));

   --  ------------------------------
   --  Update the ratings on the branch when a build is finished.
   --  ------------------------------
   procedure Update_Branch_Ratings (Service : in out Context_Type) is

      procedure Do_Branch_Ratings (Service : in out Context_Type);

      procedure Do_Branch_Ratings (Service : in out Context_Type) is
         List         : Porion.Builds.Models.Build_Status_Vector;
         Query        : ADO.Queries.Context;
         Recipe_Count : Natural := 0;
         Total_Rate   : Natural := 0;
         Success_Rate : Natural := 0;
         Build_Count  : Natural := 0;
         Pass_Rate    : Natural := 0;
         Fail_Rate    : Natural := 0;
         Timeout_Rate : Natural := 0;
         Test_Rate    : Natural := 0;
         Tag          : constant UString := Service.Branch.Get_Tag;
      begin
         --  Step 1: get the recipes and builds for the project branch.
         Query.Set_Query (Porion.Builds.Models.Query_Project_Build_Status);
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
         Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
         Porion.Builds.Models.List (List, Service.DB, Query);
         if List.Is_Empty then
            Log.Warn ("No branch found for project {0}", Service.Project.Get_Name);
            return;
         end if;

         --  Step 2: compute the pass/fail rates while applying the rate factor
         --  defined on each recipe.  We only consider the builds that match
         --  our current branch tag.
         for Status of List loop
            declare
               Rate : constant Natural := Natural (Status.Rate_Factor);
            begin
               Total_Rate := Total_Rate + Rate;
               if Status.Build_Status.Is_Null then
                  Recipe_Count := Recipe_Count + 1;
               elsif Status.Build_Tag = Tag then
                  Build_Count := Build_Count + 1;
                  if Status.Build_Status.Value = Models.BUILD_PASS then
                     Success_Rate := Success_Rate + Rate;
                  end if;
                  Pass_Rate := Pass_Rate + Status.Pass_Count * Rate;
                  Fail_Rate := Fail_Rate + Status.Fail_Count * Rate;
                  Timeout_Rate := Timeout_Rate + Status.Timeout_Count * Rate;
                  Test_Rate := Test_Rate
                     + (Status.Pass_Count + Status.Fail_Count + Status.Timeout_Count) * Rate;
               end if;
            end;
         end loop;

         if Total_Rate > 0 then
            Service.Branch.Set_Build_Rate (To_Permille (Success_Rate, Total_Rate));
         else
            Service.Branch.Set_Build_Rate (0);
         end if;
         if Test_Rate > 0 then
            Service.Branch.Set_Pass_Rate (To_Permille (Pass_Rate, Test_Rate));
            Service.Branch.Set_Fail_Rate (To_Permille (Fail_Rate, Test_Rate));
            Service.Branch.Set_Timeout_Rate (To_Permille (Timeout_Rate, Test_Rate));
         else
            Service.Branch.Set_Pass_Rate (0);
            Service.Branch.Set_Fail_Rate (0);
            Service.Branch.Set_Timeout_Rate (0);
         end if;
         Service.Branch.Set_Build_Progress (To_Permille (Build_Count, Natural (List.Length)));
         Service.Branch.Save (Service.DB);
      end Do_Branch_Ratings;

      Retry   : Natural := 0;
      Updated : Boolean;
   begin
      --  If two processes are updating the same branch ratings, one can get a
      --  LAZY_LOCK exception.  To handle it, we can simply reload the branch
      --  and run the branch rating calculation again.
      loop
         begin
            Do_Branch_Ratings (Service);
            return;

         exception
            when ADO.Objects.LAZY_LOCK =>
               Retry := Retry + 1;
               if Retry > 10 then
                  raise;
               end if;
               Service.Branch.Reload (Service.DB, Updated);

         end;
      end loop;
   end Update_Branch_Ratings;

   --  ------------------------------
   --  Update the ratings on the project by looking at the branches.
   --  ------------------------------
   procedure Update_Project_Ratings (Service : in out Context_Type) is

      procedure Do_Project_Ratings (Service : in out Context_Type);

      procedure Do_Project_Ratings (Service : in out Context_Type) is
         List         : Porion.Projects.Models.Branch_Vector;
         Query        : ADO.Queries.Context;
         Total_Rate   : Natural := 0;
         Success_Rate : Natural := 0;
         Pass_Rate    : Natural := 0;
         Fail_Rate    : Natural := 0;
         Timeout_Rate : Natural := 0;
         Build_Progress : Natural := 0;
      begin
         --  Step 1: get the project branches.
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
         Query.Set_Filter ("o.project_id = :project_id AND o.status != 0");
         Porion.Projects.Models.List (List, Service.DB, Query);

         --  Step 2: compute the pass/fail rates while applying the rate factor
         --  defined on each recipe.  We only consider the builds that match
         --  our current branch tag.
         for Branch of List loop
            declare
               Rate : constant Natural := Natural (Branch.Get_Rate_Factor);
            begin
               Total_Rate := Total_Rate + Rate;
               Success_Rate := Success_Rate + Natural (Branch.Get_Build_Rate) * Rate;
               Build_Progress := Build_Progress + Natural (Branch.Get_Build_Progress) * Rate;
               Pass_Rate := Pass_Rate + Natural (Branch.Get_Pass_Rate) * Rate;
               Fail_Rate := Fail_Rate + Natural (Branch.Get_Fail_Rate) * Rate;
               Timeout_Rate := Timeout_Rate + Natural (Branch.Get_Timeout_Rate) * Rate;
            end;
         end loop;

         if Total_Rate > 0 then
            Service.Project.Set_Build_Rate (Permille_Type (Success_Rate / Total_Rate));
            Service.Project.Set_Pass_Rate (Permille_Type (Pass_Rate / Total_Rate));
            Service.Project.Set_Fail_Rate (Permille_Type (Fail_Rate / Total_Rate));
            Service.Project.Set_Timeout_Rate (Permille_Type (Timeout_Rate / Total_Rate));
            Service.Project.Set_Build_Progress (Permille_Type (Build_Progress / Total_Rate));
         else
            Service.Project.Set_Build_Rate (0);
            Service.Project.Set_Pass_Rate (0);
            Service.Project.Set_Fail_Rate (0);
            Service.Project.Set_Timeout_Rate (0);
         end if;

         Service.Project.Save (Service.DB);
      end Do_Project_Ratings;

      Retry   : Natural := 0;
      Updated : Boolean;
   begin
      --  If two processes are updating the same project ratings, one can get a
      --  LAZY_LOCK exception.  To handle it, we can simply reload the project
      --  and run the project rating calculation again.
      loop
         begin
            Do_Project_Ratings (Service);
            return;

         exception
            when ADO.Objects.LAZY_LOCK =>
               Retry := Retry + 1;
               if Retry > 10 then
                  raise;
               end if;
               Service.Project.Reload (Service.DB, Updated);

         end;
      end loop;
   end Update_Project_Ratings;

   --  ------------------------------
   --  Remove the recipe and all its materials (including the builds).
   --  ------------------------------
   procedure Remove_Recipe (Service : in out Context_Type) is
      procedure Execute (Definition : in ADO.Queries.Query_Definition_Access);

      procedure Execute (Definition : in ADO.Queries.Query_Definition_Access) is
         Query  : ADO.Queries.Context;
      begin
         Query.Set_Query (Definition);
         Query.Bind_Param ("recipe_id", Service.Recipe.Get_Id);
         declare
            Stmt   : ADO.Statements.Query_Statement := Service.DB.Create_Statement (Query);
         begin
            Stmt.Execute;
         end;
      end Execute;

   begin
      Service.DB.Begin_Transaction;

      --  Cleanup the build information.
      Execute (Porion.Builds.Models.Query_Cleanup_Recipe_Build_Metrics);
      Execute (Porion.Builds.Models.Query_Cleanup_Recipe_Test_Run);
      Execute (Porion.Builds.Models.Query_Cleanup_Recipe_Test_Run_Group);
      Execute (Porion.Builds.Models.Query_Cleanup_Recipe_Last_Build);
      Execute (Porion.Builds.Models.Query_Cleanup_Recipe_Build_Reason);
      Execute (Porion.Builds.Models.Query_Cleanup_Recipe_Build_Step);
      Execute (Porion.Builds.Models.Query_Cleanup_Recipe_Environment);
      Execute (Porion.Builds.Models.Query_Cleanup_Recipe_Build_Queue);
      Execute (Porion.Builds.Models.Query_Cleanup_Recipe_Step);
      Execute (Porion.Builds.Models.Query_Cleanup_Recipe_Build);

      Service.Recipe.Delete (Service.DB);
      Service.DB.Commit;
   end Remove_Recipe;

   --  ------------------------------
   --  Remove the build.
   --  ------------------------------
   procedure Remove_Build (Service : in out Context_Type) is
      procedure Execute (Definition : in ADO.Queries.Query_Definition_Access);

      procedure Execute (Definition : in ADO.Queries.Query_Definition_Access) is
         Query  : ADO.Queries.Context;
      begin
         Query.Set_Query (Definition);
         Query.Bind_Param ("build_id", Service.Build.Get_Id);
         declare
            Stmt   : ADO.Statements.Query_Statement := Service.DB.Create_Statement (Query);
         begin
            Stmt.Execute;
         end;
      end Execute;

   begin
      Service.DB.Begin_Transaction;

      --  Cleanup the build information.
      Execute (Porion.Builds.Models.Query_Cleanup_Build_Metrics);
      Execute (Porion.Builds.Models.Query_Cleanup_Build_Test_Run);
      Execute (Porion.Builds.Models.Query_Cleanup_Build_Test_Run_Group);
      Execute (Porion.Builds.Models.Query_Cleanup_Build_Reason);
      Execute (Porion.Builds.Models.Query_Cleanup_Build_Step);
      Execute (Porion.Builds.Models.Query_Cleanup_Build_Last_Build);

      Service.Build.Delete (Service.DB);
      Service.DB.Commit;
   end Remove_Build;

   procedure Load_Environment (Service : in out Context_Type;
                               Recipe  : in Models.Recipe_Ref;
                               Env     : in out Util.Strings.Maps.Map) is
      Envs  : Porion.Builds.Models.Environment_Vector;
      Query : ADO.Queries.Context;
   begin
      --  Service.Environments.Clear;
      Query.Set_Filter ("(o.recipe_id = :recipe_id OR o.node_id = :node_id)"
                        & " OR (o.recipe_id IS NULL AND o.node_id IS NULL)");
      Query.Bind_Param ("recipe_id", Recipe.Get_Id);
      Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
      Porion.Builds.Models.List (Envs, Service.DB, Query);

      Env.Clear;
      for Item of Envs loop
         Env.Include (Item.Get_Name, Item.Get_Value);
      end loop;

   end Load_Environment;

   procedure Load_Recipe (Service : in out Context_Type;
                          Recipe  : in Models.Recipe_Ref;
                          Steps   : in out Build_Step_Vector) is
      List  : Models.Recipe_Step_Vector;
      Query : ADO.Queries.Context;
   begin
      Service.Branch := Projects.Models.Branch_Ref (Recipe.Get_Branch);
      Steps.Clear;
      Query.Set_Filter ("o.recipe_id = :recipe_id AND "
                        & "o.next_version_id IS NULL "
                        & "ORDER BY o.number");
      Query.Bind_Param ("recipe_id", Recipe.Get_Id);
      Models.List (List, Service.DB, Query);

      for DB_Step of List loop
         declare
            Step : Build_Step;
            Params : constant String := DB_Step.Get_Parameters;
         begin
            Step.Step := DB_Step;
            if Params'Length > 0 then
               Step.Config := Util.Serialize.IO.JSON.Read (Params);
            end if;
            Steps.Append (Step);
         end;
      end loop;

      Log.Info ("Loaded{0} build steps",
                Ada.Containers.Count_Type'Image (Steps.Length));
   end Load_Recipe;

   --  ------------------------------
   --  Delete the build step at the given execution order.
   --  Raises Invalid_Position if the position is invalid.
   --  ------------------------------
   procedure Delete_Step (Service  : in out Context_Type;
                          Recipe   : in out Porion.Builds.Models.Recipe_Ref;
                          Position : in Positive) is
      Last  : Natural;
      Steps : Build_Step_Vector;
      Added : Boolean;
   begin
      Load_Recipe (Service, Recipe, Steps);

      Last := Natural (Steps.Length);
      if Position > Last then
         Log.Warn ("Step position{0} is out of range", Natural'Image (Position));
         raise Invalid_Position;
      end if;

      Service.DB.Begin_Transaction;
      declare
         Step : Build_Step := Steps.Element (Position);
      begin
         Step.Step.Delete (Service.DB);
         Steps.Delete (Position);
      end;
      for I in Position .. Last - 1 loop
         declare
            Step : Build_Step := Steps.Element (I);
         begin
            Step.Step.Set_Number (I);
            Step.Step.Save (Service.DB);
         end;
      end loop;

      Add_Build_Queue (Service, Recipe, Models.REASON_CONFIG, Added);
      if Added then
         Update_Build_Queue (Service, Trigger_Builds => False);
      end if;
      Service.DB.Commit;

      Log.Info ("Build step {0} removed from {1}",
                Util.Strings.Image (Position), Service.Project.Get_Name);
   end Delete_Step;

   --  ------------------------------
   --  Insert the build step in the recipe at the given position.
   --  ------------------------------
   procedure Insert_Step (Service   : in out Context_Type;
                          Recipe    : in out Porion.Builds.Models.Recipe_Ref;
                          Position  : in Natural;
                          Kind      : in Porion.Builds.Models.Builder_Type;
                          Step      : in Porion.Builds.Step_Type;
                          Arguments : in Util.Strings.Vectors.Vector) is
      Steps    : Build_Step_Vector;
      New_Step : Build_Step;
      Pos      : Natural := Position;
      Last     : Natural;
      Added    : Boolean;
   begin
      Load_Recipe (Service, Recipe, Steps);

      Last := Natural (Steps.Length);

      if Pos = 0 then
         Pos := Last;
      end if;

      if Pos > Last then
         Log.Warn ("Step position{0} is out of range", Natural'Image (Pos));
         raise Invalid_Position;
      end if;

      Service.DB.Begin_Transaction;
      Last := Last + 1;

      New_Step.Step.Set_Parameters (Builders.Save_Configuration (Kind, Service.DB, Arguments));
      New_Step.Step.Set_Builder (Kind);
      New_Step.Step.Set_Number (Pos);
      New_Step.Step.Set_Step (Step);
      New_Step.Step.Set_Execution (Builds.Models.EXEC_NO_ERROR);
      New_Step.Step.Set_Recipe (Recipe);
      New_Step.Step.Save (Service.DB);
      Steps.Insert (Pos, New_Step);

      Pos := Pos + 1;
      while Pos <= Last loop
         declare
            Next_Step : Build_Step := Steps.Element (Pos);
         begin
            Next_Step.Step.Set_Number (Pos);
            Next_Step.Step.Save (Service.DB);
         end;
         Pos := Pos + 1;
      end loop;

      Add_Build_Queue (Service, Recipe, Models.REASON_CONFIG, Added);
      if Added then
         Update_Build_Queue (Service, Trigger_Builds => False);
      end if;
      Service.DB.Commit;
   end Insert_Step;

   --  ------------------------------
   --  Update the build step at the given position in the recipe.  To update the
   --  recipe, the Update procedure is called.  The build step parameters should
   --  not be modified.
   --  ------------------------------
   procedure Update_Step (Service   : in out Context_Type;
                          Recipe    : in out Porion.Builds.Models.Recipe_Ref;
                          Position  : in Positive;
                          Update    : not null access
                           procedure (Step : in out Porion.Builds.Models.Recipe_Step_Ref)) is
      Last  : Natural;
      Steps : Build_Step_Vector;
      Added : Boolean;
   begin
      Load_Recipe (Service, Recipe, Steps);

      Last := Natural (Steps.Length);
      if Position > Last then
         Log.Warn ("Step position{0} is out of range", Positive'Image (Position));
         raise Invalid_Position;
      end if;

      Service.DB.Begin_Transaction;
      declare
         Step    : Build_Step := Steps.Element (Position);
         Updated : Porion.Builds.Models.Recipe_Step_Ref;
      begin
         Update (Step.Step);
         if not Step.Step.Is_Modified then
            Service.DB.Rollback;
            return;
         end if;

         Updated.Set_Parameters (String '(Step.Step.Get_Parameters));
         Updated.Set_Number (Step.Step.Get_Number);
         Updated.Set_Builder (Step.Step.Get_Builder);
         Updated.Set_Step (Step.Step.Get_Step);
         Updated.Set_Recipe (Step.Step.Get_Recipe);
         Updated.Set_Timeout (Step.Step.Get_Timeout);
         Updated.Set_Execution (Step.Step.Get_Execution);
         Updated.Save (Service.DB);

         Step.Step.Set_Next_Version (Updated);
         Step.Step.Save (Service.DB);
      end;

      Add_Build_Queue (Service, Recipe, Models.REASON_CONFIG, Added);
      if Added then
         Update_Build_Queue (Service, Trigger_Builds => False);
      end if;
      Service.DB.Commit;

      Log.Info ("Build step {0} updated in {1}",
                Util.Strings.Image (Position), Service.Project.Get_Name);
   end Update_Step;

   --  ------------------------------
   --  Update the build step command at the given position in the recipe.
   --  ------------------------------
   procedure Update_Step (Service   : in out Context_Type;
                          Recipe    : in out Porion.Builds.Models.Recipe_Ref;
                          Position  : in Positive;
                          Kind      : in Porion.Builds.Models.Builder_Type;
                          Step      : in Porion.Builds.Step_Type;
                          Arguments : in Util.Strings.Vectors.Vector) is
      procedure Update (Recipe_Step : in out Porion.Builds.Models.Recipe_Step_Ref);

      procedure Update (Recipe_Step : in out Porion.Builds.Models.Recipe_Step_Ref) is
      begin
         Recipe_Step.Set_Step (Step);
         Recipe_Step.Set_Parameters (Builders.Save_Configuration (Kind, Service.DB, Arguments));
      end Update;
   begin
      Update_Step (Service, Recipe, Position, Update'Access);
   end Update_Step;

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class) is
      Recipes : Porion.Builds.Models.Recipe_Vector;
      Query   : ADO.Queries.Context;
   begin
      Query.Set_Filter ("o.project_id = :project_id");
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Porion.Builds.Models.List (Recipes, Service.DB, Query);

      Stream.Start_Array ("recipes");
      for Recipe of Recipes loop
         Export (Service, Recipe, Stream);
      end loop;
      Stream.End_Array ("recipes");
   end Export;

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Recipe  : in Porion.Builds.Models.Recipe_Ref;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class) is
   begin
      Stream.Start_Entity ("recipe");
      Stream.Write_Attribute ("id", Integer (Recipe.Get_Id));
      Stream.Write_Attribute ("version", Recipe.Get_Version);
      if not Recipe.Get_Node.Is_Null then
         Stream.Start_Entity ("node");
         Stream.Write_Attribute ("id", Integer (Recipe.Get_Node.Get_Id));
         Stream.End_Entity ("node");
      end if;
      Stream.Write_Entity ("name", String '(Recipe.Get_Name));
      Stream.Write_Entity ("description", String '(Recipe.Get_Description));
      Stream.Write_Entity ("status", Recipe.Get_Status'Image);

      --  Load the build steps.
      declare
         Steps : Porion.Builds.Models.Recipe_Step_Vector;
         Query : ADO.Queries.Context;
      begin
         Query.Set_Filter ("o.recipe_id = :recipe_id ORDER BY o.number");
         Query.Bind_Param ("recipe_id", Recipe.Get_Id);
         Porion.Builds.Models.List (Steps, Service.DB, Query);

         if not Steps.Is_Empty then
            Stream.Start_Array ("steps");
            for Step of Steps loop
               Stream.Start_Entity ("step");
               Stream.Write_Attribute ("id", Integer (Step.Get_Id));
               Stream.Write_Attribute ("version", Step.Get_Version);
               Stream.Write_Entity ("number", Step.Get_Number);
               Stream.Write_Entity ("timeout", Step.Get_Timeout);
               Stream.Write_Entity ("builder", Step.Get_Builder'Image);
               Stream.Write_Entity ("step", Step.Get_Step'Image);
               Stream.Write_Entity ("execution", Step.Get_Execution'Image);
               Stream.Start_Entity ("parameters");
               declare
                  procedure Print (Name : in String;
                                   Value : Util.Properties.Value);

                  Params : constant String := Step.Get_Parameters;
                  Config : Porion.Configs.Config_Type;

                  procedure Print (Name : in String;
                                   Value : Util.Properties.Value) is
                  begin
                     Stream.Start_Entity ("parameter");
                     Stream.Write_Attribute ("name", Name);
                     Stream.Write_Entity ("value", Value);
                     Stream.End_Entity ("parameter");
                  end Print;

               begin
                  if Params'Length > 0 then
                     Config := Util.Serialize.IO.JSON.Read (Params);
                     Config.Iterate (Print'Access);
                  end if;
               end;
               Stream.End_Entity ("parameters");
               Stream.End_Entity ("step");
            end loop;
            Stream.End_Array ("steps");
         end if;
      end;

      --  Load the environment variables.
      declare
         Envs  : Porion.Builds.Models.Environment_Vector;
         Query : ADO.Queries.Context;
      begin
         Query.Set_Filter ("o.recipe_id = :recipe_id");
         Query.Bind_Param ("recipe_id", Recipe.Get_Id);
         Porion.Builds.Models.List (Envs, Service.DB, Query);

         if not Envs.Is_Empty then
            Stream.Start_Array ("environments");
            for Env of Envs loop
               Stream.Start_Entity ("environment");
               Stream.Write_Attribute ("id", Integer (Env.Get_Id));
               Stream.Write_Attribute ("version", Env.Get_Version);
               Stream.Write_Entity ("name", String '(Env.Get_Name));
               Stream.Write_Entity ("value", String '(Env.Get_Value));
               Stream.End_Entity ("environment");
            end loop;
            Stream.End_Array ("environments");
         end if;
      end;

      Stream.End_Entity ("recipe");
   end Export;

   procedure Update_Parameters (Service : in out Context_Type;
                                Step    : in out Builds.Models.Recipe_Step_Ref;
                                Config  : in out Porion.Configs.Config_Type) is
      Kind : constant Models.Builder_Type := Step.Get_Builder;
   begin
      Step.Set_Parameters (Builders.Save_Configuration (Kind, Service.DB, Config));
   end Update_Parameters;

   procedure Find_Build_Configs (Service : in out Context_Type;
                                 Force   : in Boolean;
                                 List    : in out Porion.Builds.Models.Recipe_Vector) is
      Query         : ADO.Queries.Context;
   begin
      if not Service.Branch.Is_Null then
         if Force then
            Query.Set_Filter ("o.branch_id = :branch_id AND o.status != 0");
         else
            Query.Set_Filter ("o.branch_id = :branch_id AND o.status = 3");
         end if;
         Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
      else
         if Force then
            Query.Set_Filter ("o.project_id = :project_id AND o.status != 0");
         else
            Query.Set_Filter ("o.project_id = :project_id AND o.status = 3");
         end if;
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
      end if;
      Porion.Builds.Models.List (List, Service.DB, Query);
   end Find_Build_Configs;

   --  Set the environment variable for the build.
   procedure Set_Environment (Service : in out Context_Type;
                              Name    : in String;
                              Value   : in String) is
      use Ada.Strings.Unbounded;

      Query  : ADO.Queries.Context;
      Env    : Porion.Builds.Models.Environment_Ref;
      Found  : Boolean;
      Filter : UString;
   begin
      Append (Filter, "o.name = :name");
      Query.Bind_Param ("name", Name);
      if not Service.Branch.Is_Null then
         Append (Filter, " AND o.branch_id = :branch_id");
         Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
      else
         Append (Filter, " AND o.branch_id IS NULL");
      end if;
      if not Service.Project.Is_Null then
         Append (Filter, "AND o.project_id = :project_id");
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
      else
         Append (Filter, " AND o.project_id IS NULL");
      end if;
      if not Service.Recipe.Is_Null then
         Append (Filter, " AND o.recipe_id = :recipe_id");
         Query.Bind_Param ("recipe_id", Service.Recipe.Get_Id);
      else
         Append (Filter, " AND o.recipe_id IS NULL");
      end if;
      if not Service.Build_Node.Is_Null then
         Append (Filter, " AND o.node_id = :node_id");
         Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
      else
         Append (Filter, " AND o.node_id IS NULL");
      end if;
      Query.Set_Filter (To_String (Filter));

      Service.DB.Begin_Transaction;
      Env.Find (Service.DB, Query, Found);
      if not Found then
         Env.Set_Name (Name);
         Env.Set_Node (Service.Build_Node);
         Env.Set_Recipe (Service.Recipe);
         Env.Set_Branch (Service.Branch);
         Env.Set_Project (Service.Project);
      end if;
      Env.Set_Value (Value);
      Env.Save (Service.DB);
      Service.DB.Commit;
   end Set_Environment;

   --  ------------------------------
   --  Add in the build queue the recipes for the current branch and use the given
   --  reason for adding them in the build queue.
   --  ------------------------------
   procedure Add_Build_Queue (Service : in out Context_Type;
                              Reason  : in Porion.Builds.Models.Reason_Type;
                              Added   : out Boolean) is
      Recipes : Porion.Builds.Models.Recipe_Vector;
      Query   : ADO.Queries.Context;
   begin
      Query.Set_Filter ("o.branch_id = :branch_id AND o.status != 0");
      Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
      Porion.Builds.Models.List (Recipes, Service.DB, Query);

      Added := False;
      for Recipe of Recipes loop
         declare
            Recipe_Added : Boolean;
         begin
            Add_Build_Queue (Service, Recipe, Reason, Recipe_Added);
            if Recipe_Added then
               Added := True;
            end if;
         end;
      end loop;
   end Add_Build_Queue;

   --  ------------------------------
   --  Add in the build queue the given recipe with the reason for adding it
   --  in the build queue.
   --  ------------------------------
   procedure Add_Build_Queue (Service : in out Context_Type;
                              Recipe  : in out Porion.Builds.Models.Recipe_Ref;
                              Reason  : in Porion.Builds.Models.Reason_Type;
                              Added   : out Boolean) is
      use Porion.Builds.Models;

      Queue        : Models.Build_Queue_Ref;
      Queue_Reason : Models.Build_Reason_Ref;
      Found        : Boolean;
      Id           : constant ADO.Identifier := Recipe.Get_Id;
      Query   : ADO.Queries.Context;
      Now     : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      Recipe.Set_Status (Models.CONFIG_BUILD_REQUIRED);
      Recipe.Save (Service.DB);

      Query.Set_Filter ("o.recipe_id = :recipe_id");
      Query.Bind_Param ("recipe_id", Id);
      Queue.Find (Service.DB, Query, Found);
      Added := not Found;
      if not Found then
         Queue.Set_Recipe (Recipe);
         Queue.Set_Node (Recipe.Get_Node);
         Queue.Set_Create_Date (Now);
         Queue.Set_Update_Date (Queue.Get_Create_Date);

         Log.Info ("Add build queue for {0} as{1}", Service.Get_Branch_Name,
                   ADO.Identifier'Image (Id));
      end if;
      Queue.Save (Service.DB);

      Query.Clear;
      Query.Set_Filter ("o.queue_id = :queue_id AND o.reason = :reason");
      Query.Bind_Param ("queue_id", Queue.Get_Id);
      Query.Bind_Param ("reason", Integer (Models.Reason_Type'Pos (Reason)));
      Queue_Reason.Find (Service.DB, Query, Found);
      if not Found then
         Queue_Reason.Set_Queue (Queue);
         Queue_Reason.Set_Create_Date (Now);
         Queue_Reason.Set_Reason (Reason);
         Queue_Reason.Save (Service.DB);
      end if;
   end Add_Build_Queue;

   --  ------------------------------
   --  Get the build queue size.
   --  ------------------------------
   function Get_Queue_Size (Service : in Context_Type) return Natural is
      Stmt : ADO.Statements.Query_Statement
         := Service.DB.Create_Statement ("SELECT COUNT(*) FROM porion_build_queue");
   begin
      Stmt.Execute;
      return Stmt.Get_Result_Integer;
   end Get_Queue_Size;

   procedure Update (Service : in out Context_Type;
                     Config  : in out Build_Config) is
      procedure Remove (List : in out Models.Recipe_Step_Vector;
                        Id   : in ADO.Identifier);

      procedure Remove (List : in out Models.Recipe_Step_Vector;
                        Id   : in ADO.Identifier) is
         Iter : Models.Recipe_Step_Vectors.Cursor := List.First;
      begin
         while Models.Recipe_Step_Vectors.Has_Element (Iter) loop
            if Models.Recipe_Step_Vectors.Element (Iter).Get_Id = Id then
               List.Delete (Iter);
               return;
            end if;
            Models.Recipe_Step_Vectors.Next (Iter);
         end loop;
      end Remove;

      Config_Id : constant ADO.Identifier := Config.Config.Get_Id;
      Steps     : Models.Recipe_Step_Vector;
      Query     : ADO.Queries.Context;
      Rank      : Natural := 0;
   begin
      Log.Info ("Update build config {0}", Config_Id'Image);

      Query.Set_Filter ("o.recipe_id = :config_id ORDER BY o.number");
      Query.Bind_Param ("config_id", Config_Id);
      Models.List (Steps, Service.DB, Query);

      --  Step 1: update and insert the build steps.
      for Pos in Config.Steps.Iterate loop
         declare
            Step_Ref : constant Build_Step_Vectors.Reference_Type := Config.Steps.Reference (Pos);
         begin
            Rank := Rank + 1;
            Step_Ref.Step.Set_Number (Rank);
            Update_Parameters (Service, Step_Ref.Step, Step_Ref.Config);
            if Step_Ref.Step.Is_Loaded then
               if Step_Ref.Step.Is_Modified then
                  Step_Ref.Step.Save (Service.DB);
               end if;

               Remove (Steps, Step_Ref.Step.Get_Id);
            else
               Step_Ref.Step.Set_Recipe (Config.Config);
               Step_Ref.Step.Save (Service.DB);
            end if;
         end;
      end loop;

      --  Step 2: remove the build steps.
      for To_Delete_Step of Steps loop
         To_Delete_Step.Delete (Service.DB);
      end loop;
   end Update;

   procedure Update (Service : in out Context_Type;
                     Configs : in out Build_Config_Vector) is
      procedure Remove (List : in out Models.Recipe_Vector;
                        Id   : in ADO.Identifier);

      procedure Remove (List : in out Models.Recipe_Vector;
                        Id   : in ADO.Identifier) is
         Iter : Models.Recipe_Vectors.Cursor := List.First;
      begin
         while Models.Recipe_Vectors.Has_Element (Iter) loop
            if Models.Recipe_Vectors.Element (Iter).Get_Id = Id then
               List.Delete (Iter);
               return;
            end if;
            Models.Recipe_Vectors.Next (Iter);
         end loop;
      end Remove;

      Project_Id    : constant ADO.Identifier := Service.Project.Get_Id;
      Build_Configs : Models.Recipe_Vector;
      Query         : ADO.Queries.Context;
   begin
      Log.Info ("Update build configs for{0}", Project_Id'Image);

      Query.Set_Filter ("o.project_id = :project_id");
      Query.Bind_Param ("project_id", Project_Id);
      Porion.Builds.Models.List (Build_Configs, Service.DB, Query);

      Service.DB.Begin_Transaction;

      --  Step 1: update the existing configs and create the new one.
      for Pos in Configs.Iterate loop
         declare
            Config_Ref : constant Build_Config_Vectors.Reference_Type
              := Configs.Reference (Pos);
         begin
            if Config_Ref.Config.Is_Loaded then
               if Config_Ref.Config.Is_Modified then
                  Config_Ref.Config.Save (Service.DB);
               end if;

               Update (Service, Config_Ref.Element.all);
               Remove (Build_Configs, Config_Ref.Config.Get_Id);
            else
               Config_Ref.Config.Save (Service.DB);
            end if;
         end;
      end loop;

      --  Step 2: remove the build configs
      for To_Delete_Config of Build_Configs loop
         To_Delete_Config.Delete (Service.DB);
      end loop;
      Service.DB.Commit;
   end Update;

   procedure Make_Recipes (Service  : in out Context_Type;
                           Branch   : in String;
                           Executor : in out Porion.Executors.Executor_Type'Class) is
      Name    : constant String := Service.Project.Get_Name;
      Path    : constant String := Configs.Get_Build_Directory (Name, Branch);
      Config  : Util.Properties.Manager;
      Query   : ADO.SQL.Query;
      Found   : Boolean;
      Added   : Boolean;
   begin
      Log.Info ("Make build config {0} for branch {1} in {2}", Name, Branch, Path);

      Query.Set_Filter ("o.project_id = :project_id and o.name = :branch");
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Query.Bind_Param ("branch", Branch);
      Service.Branch.Find (Service.DB, Query, Found);
      if not Found then
         Log.Error ("Branch {0} not found in database", Branch);
         return;
      end if;

      if not Executor.Is_Dry_Run then
         Executor.Create_Directory (Path, False);
      end if;

      Config.Set ("repository_url", String '(Service.Project.Get_Scm_Url));

      Sources.Checkout (Service.Project.Get_Scm, Config, Path, Executor);

      if Service.Build_Node.Is_Null then
         Nodes.Services.Load_Default_Node (Service);
      end if;

      Service.Recipe.Set_Project (Service.Project);
      Service.Recipe.Set_Node (Service.Build_Node);
      Service.Recipe.Set_Status (Builds.Models.CONFIG_BUILD_REQUIRED);
      Service.Recipe.Set_Branch (Service.Branch);
      Service.Recipe.Set_Main_Recipe (True);
      Service.Recipe.Set_Rate_Factor (100);
      Service.Recipe.Set_Name ("main");
      Service.Recipe.Save (Service.DB);
      Guess (Service, Path, Executor);

      Add_Build_Queue (Service, Models.REASON_CONFIG, Added);
      if Added then
         Update_Build_Queue (Service, Trigger_Builds => False);
      end if;
   end Make_Recipes;

   --  Load the recipes of a project according to the identification.
   procedure Load_Recipes (Service : in out Context_Type;
                           Ident   : in Porion.Projects.Ident_Type;
                           List    : in out Porion.Builds.Models.Recipe_Vector) is
      Query : ADO.Queries.Context;
      Found : Boolean;
   begin
      Service.Load_Project (To_String (Ident.Name));

      if Length (Ident.Branch) > 0 then
         Query.Set_Filter ("o.project_id = :project_id and o.name = :branch");
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
         Query.Bind_Param ("branch", Ident.Branch);
         Service.Branch.Find (Service.DB, Query, Found);
         if not Found then
            Log.Error ("Branch {0} not found in database", To_String (Ident.Branch));
            return;
         end if;
      end if;

      if Length (Ident.Node) > 0 then
         Nodes.Services.Load_Node (Service, To_String (Ident.Node));
      end if;

      if Service.Build_Node.Is_Null then
         Nodes.Services.Load_Default_Node (Service);
      end if;

      Query.Clear;
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
      if not Service.Branch.Is_Null and not Service.Build_Node.Is_Null then
         Query.Set_Filter ("o.project_id = :project_id AND o.node_id = :node_id "
                           & " AND o.branch_id = :branch_id");
         Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
      else
         Query.Set_Filter ("o.project_id = :project_id AND o.node_id = :node_id");
      end if;
      Builds.Models.List (List, Service.DB, Query);
   end Load_Recipes;

   --  ------------------------------
   --  Copy the recipe to another recipe with the given name.
   --  ------------------------------
   procedure Copy_Recipe (Service  : in out Context_Type;
                          Name     : in String;
                          From     : in out Models.Recipe_Ref) is
      use type Porion.Projects.Models.Branch_Status_Type;

      Ident   : constant String := Service.Get_Recipe_Name (From);
      Steps   : Build_Step_Vector;
   begin
      Log.Info ("Copy build recipe {0} to {1}", Ident, Name);

      --  Load the recipe steps.
      Load_Recipe (Service, From, Steps);

      --  Create the new recipe and copy the build steps.
      Service.DB.Begin_Transaction;
      declare
         New_Recipe : Models.Recipe_Ref;
         Added      : Boolean;
      begin
         New_Recipe.Set_Name (Name);
         New_Recipe.Set_Description (String '(From.Get_Description));
         New_Recipe.Set_Rate_Factor (From.Get_Rate_Factor);
         New_Recipe.Set_Status (Builds.Models.CONFIG_BUILD_REQUIRED);
         New_Recipe.Set_Node (Service.Build_Node);
         New_Recipe.Set_Project (Service.Project);
         New_Recipe.Set_Branch (Service.Branch);
         New_Recipe.Set_Filter_Rules (String '(From.Get_Filter_Rules));
         New_Recipe.Save (Service.DB);

         if Service.Branch.Get_Status = Porion.Projects.Models.BUILD_DISABLED then
            Service.Branch.Set_Status (Porion.Projects.Models.BUILD_REQUIRED);
            Service.Branch.Save (Service.DB);
         end if;

         for Step of Steps loop
            declare
               Src_Step : constant Models.Recipe_Step_Ref := Step.Step;
               New_Step : Models.Recipe_Step_Ref;
            begin
               New_Step.Set_Parameters (String '(Src_Step.Get_Parameters));
               New_Step.Set_Number (Src_Step.Get_Number);
               New_Step.Set_Timeout (Src_Step.Get_Timeout);
               New_Step.Set_Recipe (New_Recipe);
               New_Step.Set_Builder (Src_Step.Get_Builder);
               New_Step.Set_Execution (Src_Step.Get_Execution);
               New_Step.Set_Step (Src_Step.Get_Step);
               New_Step.Save (Service.DB);
            end;
         end loop;

         Service.Recipe := New_Recipe;
         Add_Build_Queue (Service, Models.REASON_CONFIG, Added);
         if Added then
            Update_Build_Queue (Service, Trigger_Builds => False);
         end if;
      end;
      Service.DB.Commit;
   end Copy_Recipe;

   procedure Guess (Service  : in out Context_Type;
                    Path     : in String;
                    Executor : in out Porion.Executors.Executor_Type'Class) is
      use Ada.Strings.Unbounded;

      function Check (File    : in String;
                      Message : in String) return Boolean;

      procedure Add_Step (Step    : in out Builds.Models.Recipe_Step_Ref;
                          Builder : in Builds.Models.Builder_Type;
                          Kind    : in Builds.Step_Type);

      procedure Add_Step (Kind    : in Builds.Step_Type;
                          Command : in String);

      procedure Add_Metric_Step (Command : in String;
                                 Arg     : in String);

      use Util.Strings.Formats;

      Current_Step : Positive := 1;

      function Check (File    : in String;
                      Message : in String) return Boolean is
         File_Path : constant String := Util.Files.Compose (Path, File);
         Exists    : constant Boolean := Ada.Directories.Exists (File_Path);
      begin
         Executor.Log (Porion.Logs.LOG_INFO,
                       Format (Message, File, (if Exists then -("yes") else -("no")), "", ""));
         return Exists;
      end Check;

      procedure Add_Step (Step    : in out Builds.Models.Recipe_Step_Ref;
                          Builder : in Builds.Models.Builder_Type;
                          Kind    : in Builds.Step_Type) is
      begin
         Step.Set_Step (Kind);
         Step.Set_Execution (Builds.Models.EXEC_NO_ERROR);
         Step.Set_Builder (Builder);
         Step.Set_Timeout (10 * 60);
         Step.Set_Number (Current_Step);
         Step.Set_Recipe (Service.Recipe);
         Step.Set_Version (1);
         Step.Save (Service.DB);
         Current_Step := Current_Step + 1;
      end Add_Step;

      procedure Add_Step (Kind    : in Builds.Step_Type;
                          Command : in String) is
         Step   : Builds.Models.Recipe_Step_Ref;
         Config : Porion.Configs.Config_Type;
      begin
         Config.Set ("command", Command);
         Step.Set_Builder (Builds.Models.BUILDER_SCRIPT);
         Update_Parameters (Service, Step, Config);
         Add_Step (Step, Builds.Models.BUILDER_SCRIPT, Kind);
      end Add_Step;

      procedure Add_Metric_Step (Command : in String;
                                 Arg     : in String) is
         Step   : Builds.Models.Recipe_Step_Ref;
         Params : Util.Strings.Vectors.Vector;
         Kind   : Builds.Models.Builder_Type renames Builds.Models.BUILDER_METRIC;
      begin
         Params.Append (Command);
         Params.Append (Arg);
         Step.Set_Builder (Kind);
         Step.Set_Parameters (Builders.Save_Configuration (Kind, Service.DB, Params));
         Add_Step (Step, Kind, Builds.STEP_METRIC);
      end Add_Metric_Step;

      Has_Autogen     : Boolean;
      Has_Autoconf    : Boolean;
      Has_Automake    : Boolean;
      Has_Configure   : Boolean;
      Has_Makefile_In : Boolean;
      Has_CMake       : Boolean;
      Has_Makefile    : Boolean;
      Has_Pom_Xml     : Boolean;
      Has_Package_Json : Boolean;
      Rules           : UString;
   begin
      Has_Autogen := Check ("autogen.sh", -("checking for {0}"));
      Has_Autoconf := Check ("configure.ac", -("checking for {0}"))
        or else Check ("configure.in", -("checking for {0}"));

      Has_Automake := Check ("Makefile.am", -("checking for {0}"));
      Has_Makefile_In := Check ("Makefile.in", -("checking for {0}"));
      Has_Configure := Check ("configure", -("checking for {0}"));
      Has_CMake := Check ("CMakeLists.txt", -("checking for {0}"));
      Has_Makefile := Check ("Makefile", -("checking for {0}"))
        or else Check ("makefile", -("checking for {0}"));
      Has_Pom_Xml := Check ("pom.xml", -("checking for {0}"));
      Has_Package_Json := Check ("package.json", -("checking for {0}"));

      Add_Metric_Step ("disk", "before");

      if Has_Autogen then
         Add_Step (Builds.STEP_GENERATE, "./autogen.sh");
      end if;

      if not Has_Autogen and Has_Autoconf and not Has_Configure then
         Add_Step (Builds.STEP_GENERATE, "autoconf");
         Append (Rules, " autoconf");
      end if;

      if not Has_Autogen and Has_Automake and not Has_Makefile_In then
         Add_Step (Builds.STEP_GENERATE, "automake");
         Append (Rules, " automake");
      end if;

      if Has_Autogen or Has_Autoconf or Has_Configure then
         Add_Step (Builds.STEP_CONFIGURE, "./configure --prefix=#{install}");
         Append (Rules, " configure");
      end if;

      if Has_CMake then
         Add_Step (Builds.STEP_CONFIGURE, "cmake");
         Append (Rules, " cmake");
      end if;

      if Has_Pom_Xml then
         Add_Step (Builds.STEP_MAKE, "mvn package");
         Append (Rules, " mvn");
      end if;

      if Has_CMake or Has_Makefile_In or Has_Automake or Has_Makefile then
         Add_Step (Builds.STEP_MAKE, "make");
         Append (Rules, " make");
      end if;

      if Has_Package_Json then
         Add_Step (Builds.STEP_MAKE, "npm install");
         Append (Rules, " npm");
      end if;

      Add_Metric_Step ("disk", "after");

      Service.Recipe.Set_Filter_Rules (Rules);
      Service.Recipe.Save (Service.DB);
   end Guess;

end Porion.Builds.Services;
