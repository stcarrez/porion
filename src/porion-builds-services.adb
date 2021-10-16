-----------------------------------------------------------------------
--  porion-builds-services -- build service to manage builds
--  Copyright (C) 2021 Stephane Carrez
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
with Ada.Unchecked_Deallocation;
with Util.Log.Loggers;
with Util.Strings;
with Util.Files;
with Util.Streams;
with Util.Streams.Texts;
with Util.Serialize.IO.JSON;
with Util.Properties;
with Util.Strings.Formats;
with ADO.Statements;
with ADO.Queries;
with ADO.SQL;
with Porion.Sources.Factories;
with Porion.Nodes.Models;
with Porion.Nodes.Services;
with Porion.Builders.Factories;
package body Porion.Builds.Services is

   use type ADO.Identifier;
   use type Porion.Builders.Controller_Access;
   use type Porion.Builds.Models.Execution_Type;
   use type Porion.Builds.Models.Build_Status_Type;

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builds.Services");

   procedure Free is
     new Ada.Unchecked_Deallocation (Object => Porion.Builders.Controller_Type'Class,
                                     Name   => Porion.Builders.Controller_Access);

   procedure Start_Build (Service     : in out Context_Type;
                          Recipe      : in Porion.Builds.Models.Recipe_Ref;
                          Executor    : in out Porion.Executors.Executor_Type'Class) is
      Query : ADO.Queries.Context;
      Stmt  : ADO.Statements.Query_Statement;
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
      Query.Set_Query (Projects.Models.Query_Project_Last_Build);
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
      Stmt := Service.DB.Create_Statement (Query);
      Stmt.Execute;

      Service.Build := Porion.Builds.Models.Null_Build;
      Service.Build.Set_Number (Stmt.Get_Result_Integer + 1);

      Service.Build.Set_Project (Service.Project);
      Service.Build.Set_Branch (Service.Branch);
      Service.Build.Set_Node (Service.Build_Node);
      Service.Build.Set_Recipe (Service.Recipe);
      Service.Build.Set_Tag (String '(Service.Branch.Get_Tag));
      Service.Build.Set_Create_Date (Ada.Calendar.Clock);
      if not Executor.Is_Dry_Run then
         Service.Build.Save (Service.DB);
         Service.DB.Commit;
      else
         Service.DB.Rollback;
      end if;

      Log.Info ("Created build{0} for {1}", Natural'Image (Service.Build.Get_Number),
                Service.Project.Get_Name);
   end Start_Build;

   procedure Build (Service  : in out Context_Type;
                    Recipe   : in Porion.Builds.Models.Recipe_Ref;
                    Executor : in out Porion.Executors.Executor_Type'Class) is
      Steps : Build_Step_Vector;
   begin
      Start_Build (Service, Recipe, Executor);

      Load_Environment (Service, Recipe);
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

   procedure Build (Service     : in out Context_Type;
                    Steps       : in Build_Step_Vector;
                    Executor    : in out Porion.Executors.Executor_Type'Class) is
      Ident   : constant String := Projects.To_String (Service.Ident);
      Number  : constant Positive := Service.Build.Get_Number;
      Name    : constant String := Service.Project.Get_Name;
      Branch_Name : constant String := Service.Branch.Get_Name;
      Path    : constant String := Get_Build_Directory (Service);
      Log_Dir : constant String := Configs.Get_Build_Log_Directory (Name, Branch_Name, Number);
      Config  : Util.Properties.Manager;
      Status  : Builds.Models.Build_Status_Type := Builds.Models.BUILD_RUNNING;
      Source_Controller : Porion.Sources.Controller_Access;
   begin
      Log.Info ("Build {0} in {1}", Ident, Path);

      Executor.Set_Build_Node (Service.Build_Node);

      Executor.Set_Step (Builds.STEP_CHECKOUT);
      if not Executor.Is_Dry_Run then
         Executor.Create_Directory (Path, False);
      end if;

      Config.Set ("branch", Branch_Name);
      Config.Set ("repository_url", String '(Service.Project.Get_Scm_Url));
      Source_Controller := Sources.Factories.Create (Service.Project.Get_Scm, Config);

      Executor.Create_Logger (Log_Dir, "build.log");
      Executor.Log ("Build '" & Ident & "' in " & Path);
      Source_Controller.Checkout (Path, Executor);

      Config.Set ("build_dir", Path);
      for Step of Steps loop
         if Step.Step.Get_Execution /= Builds.Models.EXEC_DISABLED then
            declare
               Exec_Step   : Builds.Models.Build_Step_Ref;
               Step_Status : Integer;
               Build_Controller : Porion.Builders.Controller_Access;
            begin
               if not Executor.Is_Dry_Run then
                  Exec_Step.Set_Start_Date (Ada.Calendar.Clock);
                  Exec_Step.Set_Build (Service.Build);
                  Exec_Step.Set_Recipe_Step (Step.Step);
                  Exec_Step.Save (Service.DB);
               end if;
               Executor.Set_Step (Step.Step.Get_Step);
               Executor.Set_Status (0);
               Build_Controller
                 := Builders.Factories.Create (Step.Step.Get_Builder, Service.DB, Step.Config);
               Build_Controller.Build (Service.Build, Path, Executor);

               if not Executor.Is_Dry_Run then
                  Step_Status := Executor.Get_Status;
                  Exec_Step.Set_Exit_Status (Step_Status);
                  Exec_Step.Set_End_Date ((Is_Null => False,
                                           Value => Ada.Calendar.Clock));
                  Exec_Step.Save (Service.DB);
                  if Step_Status /= 0 and Step.Step.Get_Execution = Builds.Models.EXEC_NO_ERROR then
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
         Update_Build (Service, Status);
      end if;
   end Build;

   procedure Update_Build (Service : in out Context_Type;
                           Status  : in Builds.Models.Build_Status_Type) is
      Last_Builds : Builds.Models.Last_Build_Vector;
      Query       : ADO.Queries.Context;

      procedure Update_Last is
      begin
         for Iter in Last_Builds.Iterate loop
            declare
               Last_Build : Models.Last_Build_Vectors.Reference_Type
                 := Models.Last_Build_Vectors.Reference (Last_Builds, Iter);
            begin
               if Last_Build.Get_Status = Status then
                  Last_Build.Set_Build (Service.Build);
                  Last_Build.Save (Service.DB);
                  return;
               end if;
            end;
         end loop;
         declare
            Last_Build : Models.Last_Build_Ref;
         begin
            Last_Build.Set_Status (Status);
            Last_Build.Set_Build (Service.Build);
            Last_Build.Set_Recipe (Service.Recipe);
            Last_Build.Set_Branch (Service.Branch);
            Last_Build.Save (Service.DB);
         end;
      end Update_Last;

   begin
      Service.Build.Set_Status (Status);
      Service.Build.Set_Finish_Date ((Is_Null => False,
                                      Value => Ada.Calendar.Clock));
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

         when Builds.Models.BUILD_FAIL =>
            Service.Recipe.Set_Status (Builds.Models.CONFIG_BUILD_FAIL);
            Service.Recipe.Save (Service.DB);

         when others =>
            null;

      end case;
   end Update_Build;

   procedure Load_Environment (Service : in out Context_Type;
                               Recipe  : in Models.Recipe_Ref) is
      Envs  : Porion.Builds.Models.Environment_Vector;
      Query : ADO.Queries.Context;
   begin
      --  Service.Environments.Clear;
      Query.Set_Filter ("(o.recipe_id = :recipe_id OR o.node_id = :node_id)"
                        & " OR (o.recipe_id IS NULL AND o.node_id IS NULL)");
      Query.Bind_Param ("recipe_id", Recipe.Get_Id);
      Query.Bind_Param ("node_id", Recipe.Get_Id);
      Porion.Builds.Models.List (Envs, Service.DB, Query);


   end Load_Environment;

   procedure Load_Recipe (Service : in out Context_Type;
                          Recipe  : in Models.Recipe_Ref;
                          Steps   : in out Build_Step_Vector) is
      List  : Models.Recipe_Step_Vector;
      Query : ADO.Queries.Context;
   begin
      Steps.Clear;
      Query.Set_Filter ("o.recipe_id = :recipe_id ORDER BY o.number");
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

   --  Delete the build step at the given execution order.
   procedure Delete_Step (Service  : in out Context_Type;
                          Steps    : in out Build_Step_Vector;
                          Position : in Natural) is
      Last : constant Natural := Natural (Steps.Length);
   begin
      if Position > Last then
         raise Program_Error;
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
      Service.DB.Commit;
   end Delete_Step;

   procedure Insert_Step (Service   : in out Context_Type;
                          Steps     : in out Build_Step_Vector;
                          Position  : in Natural;
                          Kind      : in Porion.Builds.Models.Builder_Type;
                          Step      : in Porion.Builds.Step_Type;
                          Arguments : in Util.Strings.Vectors.Vector) is
      use Porion.Builds.Models;

      Config     : Porion.Configs.Config_Type;
      Controller : Porion.Builders.Controller_Access
        := Porion.Builders.Factories.Create (Kind, Service.DB, Config);
      Output : aliased Util.Streams.Texts.Print_Stream;
      Stream : Util.Serialize.IO.JSON.Output_Stream;
   begin
      if Controller = null then
         Log.Error ("No builder for {0}", Builder_Type'Image (Kind));
         return;
      end if;
      Controller.Configure (Arguments);

      Output.Initialize (Size => 10000);
      Stream.Initialize (Output => Output'Unchecked_Access);
      Stream.Start_Document;
      Controller.Print (Stream);
      Stream.End_Document;

      Free (Controller);

      declare
         New_Step : Build_Step;
         Pos  : Natural := Position;
      begin
         if Pos = 0 then
            Pos := Natural (Steps.Length);
         end if;
         Steps.Insert (Pos, New_Step);
         New_Step.Step.Set_Parameters (Util.Streams.Texts.To_String (Output));
         New_Step.Step.Set_Builder (Kind);
         New_Step.Step.Set_Number (Pos);
         New_Step.Step.Set_Step (Step);
         New_Step.Step.Set_Execution (Builds.Models.EXEC_NO_ERROR);
         New_Step.Step.Set_Recipe (Service.Recipe);
         New_Step.Step.Save (Service.DB);

         Pos := Pos + 1;
         while Pos < Natural (Steps.Length) loop
            declare
               Next_Step : Build_Step := Steps.Element (Pos);
            begin
               Next_Step.Step.Set_Number (Pos);
               Next_Step.Step.Save (Service.DB);
            end;
            Pos := Pos + 1;
         end loop;
      end;
   end Insert_Step;

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class) is
      Build_Configs : Porion.Builds.Models.Recipe_Vector;
      Query         : ADO.Queries.Context;
   begin
      Query.Set_Filter ("o.project_id = :project_id");
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Porion.Builds.Models.List (Build_Configs, Service.DB, Query);

      Stream.Start_Array ("recipes");
      for Build_Config of Build_Configs loop
         Export (Service, Build_Config, Stream);
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
         Query.Bind_Param ("recipe_id", Service.Recipe.Get_Id);
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
      Kind       : constant Models.Builder_Type := Step.Get_Builder;
      Controller : Porion.Builders.Controller_Access;
      Output     : aliased Util.Streams.Texts.Print_Stream;
      Stream     : Util.Serialize.IO.JSON.Output_Stream;
   begin
      Controller := Builders.Factories.Create (Kind, Service.DB, Config);
      if Controller = null then
         Log.Error ("No builder for {0}", Models.Builder_Type'Image (Kind));
         return;
      end if;

      Output.Initialize (Size => 10000);
      Stream.Initialize (Output => Output'Unchecked_Access);
      Stream.Start_Document;
      Controller.Print (Stream);
      Stream.End_Document;

      Free (Controller);

      Step.Set_Parameters (Util.Streams.Texts.To_String (Output));
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

   procedure Update_Branch_Config (Branch  : in Porion.Projects.Models.Branch_Ref;
                                   Status  : in Porion.Builds.Models.Config_Status_Type;
                                   Session : in out ADO.Sessions.Master_Session) is
      use Porion.Builds.Models;

      function Get_Name return String is
         Project_Name  : constant String := Branch.Get_Project.Get_Name;
         Branch_Name   : constant String := Branch.Get_Name;
      begin
         return Project_Name & "^" & Branch_Name;
      end Get_Name;

      Recipes       : Porion.Builds.Models.Recipe_Vector;
      Build_Queues  : Porion.Builds.Models.Build_Queue_Vector;
      Query         : ADO.Queries.Context;
   begin
      Query.Set_Filter ("o.branch_id = :branch_id AND o.status = :status");
      Query.Bind_Param ("branch_id", Branch.Get_Id);
      Query.Bind_Param ("status", Integer (Builds.Models.Config_Status_Type'Pos (Status)));
      Porion.Builds.Models.List (Recipes, Session, Query);

      for Iter in Recipes.Iterate loop
         declare
            Recipe : constant Models.Recipe_Vectors.Reference_Type
              := Models.Recipe_Vectors.Reference (Recipes, Iter);
            Queue  : Models.Build_Queue_Ref;
            Found  : Boolean;
            Id     : constant ADO.Identifier := Recipe.Get_Id;
         begin
            Recipe.Set_Status (Status);
            Recipe.Save (Session);

            Query.Clear;
            Query.Set_Filter ("o.recipe_id = :recipe_id");
            Query.Bind_Param ("recipe_id", Id);
            Queue.Find (Session, Query, Found);
            if not Found then
               Queue.Set_Recipe (Recipe);
               Queue.Set_Node (Recipe.Get_Node);
               Queue.Set_Creation_Date (Ada.Calendar.Clock);

               Log.Info ("Add build queue for {0} as{1}", Get_Name,
                         ADO.Identifier'Image (Id));
            end if;
            Queue.Save (Session);
         end;
      end loop;
   end Update_Branch_Config;

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
      Source_Controller : Porion.Sources.Controller_Access;
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
      Source_Controller := Sources.Factories.Create (Service.Project.Get_Scm, Config);

      --  Logger.Create (Log_Dir, "build.log");
      Source_Controller.Checkout (Path, Executor);

      if Service.Build_Node.Is_Null then
         Nodes.Services.Load_Default_Node (Service);
      end if;

      Service.Recipe.Set_Project (Service.Project);
      Service.Recipe.Set_Node (Service.Build_Node);
      Service.Recipe.Set_Status (Builds.Models.CONFIG_BUILD_REQUIRED);
      Service.Recipe.Set_Branch (Service.Branch);
      Service.Recipe.Set_Main_Recipe (True);
      Service.Recipe.Save (Service.DB);
      Guess (Service, Path, Executor);

      Update_Branch_Config (Service.Branch,
                            Builds.Models.CONFIG_BUILD_REQUIRED,
                            Service.DB);
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

   procedure Copy_Recipe (Service  : in out Context_Type;
                          Project  : in String;
                          Branch   : in String;
                          Node     : in String;
                          Recipe   : in out Models.Recipe_Ref) is
      use type Porion.Projects.Models.Branch_Status_Type;

      Query   : ADO.SQL.Query;
      Found   : Boolean;
      Steps   : Build_Step_Vector;
   begin
      Log.Info ("Copy build recipe {0} for branch {1} and node {2}", Project, Branch, Node);

      Service.Load_Project (Project);

      --  Find the project branch when specified.
      if Branch'Length > 0 then
         Query.Set_Filter ("o.project_id = :project_id and o.name = :branch");
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
         Query.Bind_Param ("branch", Branch);
         Service.Branch.Find (Service.DB, Query, Found);
         if not Found then
            Log.Error ("Branch {0} not found in database", Branch);
            return;
         end if;
      end if;

      --  Find the main project branch.
      if Service.Branch.Is_Null then
         Query.Clear;
         Query.Set_Filter ("o.project_id = :project_id AND o.main_branch = 1");
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
         Service.Branch.Find (Service.DB, Query, Found);
         if not Found then
            Log.Error ("No main branch for project {0}", Project);
            return;
         end if;
      end if;

      --  Find the main project recipe for the branch.
      if Recipe.Is_Null then
         Query.Clear;
         Query.Set_Filter ("o.project_id = :project_id AND o.branch_id = :branch_id"
                           & " AND o.main_recipe = 1");
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
         Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
         Recipe.Find (Service.DB, Query, Found);
         if not Found then
            Query.Clear;
            Query.Set_Filter ("o.project_id = :project_id AND o.main_recipe = 1");
            Query.Bind_Param ("project_id", Service.Project.Get_Id);
            Recipe.Find (Service.DB, Query, Found);
            if not Found then
               Log.Error ("No main recipe for project {0}", Project);
               return;
            end if;
         end if;
      end if;

      --  Find the build node or use the current recipe's build node.
      if Node'Length > 0 then
         Nodes.Services.Load_Node (Service, Node);
      else
         Service.Build_Node := Nodes.Models.Node_Ref (Recipe.Get_Node);
      end if;

      --  Load the recipe steps.
      Load_Recipe (Service, Recipe, Steps);

      --  Create the new recipe and copy the build steps.
      Service.DB.Begin_Transaction;
      declare
         New_Recipe : Models.Recipe_Ref;
      begin
         New_Recipe.Set_Name (String '(Recipe.Get_Name));
         New_Recipe.Set_Description (String '(Recipe.Get_Description));
         New_Recipe.Set_Rate_Factor (Recipe.Get_Rate_Factor);
         New_Recipe.Set_Status (Builds.Models.CONFIG_BUILD_REQUIRED);
         New_Recipe.Set_Node (Service.Build_Node);
         New_Recipe.Set_Project (Service.Project);
         New_Recipe.Set_Branch (Service.Branch);
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

         Update_Branch_Config (Service.Branch,
                               Models.CONFIG_BUILD_REQUIRED,
                               Service.DB);
         Recipe := New_Recipe;
      end;
      Service.DB.Commit;
   end Copy_Recipe;

   procedure Guess (Service  : in out Context_Type;
                    Path     : in String;
                    Executor : in out Porion.Executors.Executor_Type'Class) is
      use Util.Strings.Formats;

      Current_Step : Positive := 1;

      function Check (File    : in String;
                      Message : in String) return Boolean is
         File_Path : constant String := Util.Files.Compose (Path, File);
         Exists    : constant Boolean := Ada.Directories.Exists (File_Path);
      begin
         Executor.Log (Format (Message, File, (if Exists then -("yes") else -("no")), "", ""));
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

      Has_Autogen     : Boolean;
      Has_Autoconf    : Boolean;
      Has_Automake    : Boolean;
      Has_Configure   : Boolean;
      Has_Makefile_In : Boolean;
      Has_CMake       : Boolean;
      Has_Makefile    : Boolean;
      Has_Pom_Xml     : Boolean;
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

      if Has_Autogen then
         Add_Step (Builds.STEP_GENERATE, "./autogen.sh");
      end if;

      if not Has_Autogen and Has_Autoconf and not Has_Configure then
         Add_Step (Builds.STEP_GENERATE, "autoconf");
      end if;

      if not Has_Autogen and Has_Automake and not Has_Makefile_In then
         Add_Step (Builds.STEP_GENERATE, "automake");
      end if;

      if Has_Autogen or Has_Autoconf or Has_Configure then
         Add_Step (Builds.STEP_CONFIGURE, "./configure --prefix=#{install}");
      end if;

      if Has_CMake then
         Add_Step (Builds.STEP_CONFIGURE, "cmake");
      end if;

      if Has_Pom_Xml then
         Add_Step (Builds.STEP_MAKE, "mvn package");
      end if;

      if Has_CMake or Has_Makefile_In or Has_Automake or Has_Makefile then
         Add_Step (Builds.STEP_MAKE, "make");
      end if;

   end Guess;

end Porion.Builds.Services;
