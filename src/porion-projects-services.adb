-----------------------------------------------------------------------
--  porion-projects -- Project information
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
with Ada.Directories;
with Ada.Strings.Maps;
with Ada.Strings.Fixed;
with Util.Log.Loggers;
with Util.Properties;
with Util.Strings;
with Util.Dates.ISO8601;
with Porion.Configs;
with Porion.Sources.Factories;
with Porion.Builds.Models;
with ADO.SQL;
with ADO.Queries;
with ADO.Statements;
with Porion.Builds.Services;
package body Porion.Projects.Services is

   use type ADO.Identifier;
   use type Porion.Projects.Models.Branch_Status_Type;

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Projects.Services");

   procedure Add_Project (Service   : in out Context_Type;
                          Info      : in Porion.Sources.Source_Info_Type) is
      Name  : constant String := To_String (Info.Name);
      Query : ADO.SQL.Query;
      Found : Boolean;
   begin
      Log.Debug ("Add project {0}", Name);

      if Name'Length = 0 then
         Log.Warn ("Cannot create project with empty name");
         raise Invalid_Name;
      end if;

      Service.DB.Begin_Transaction;
      Query.Bind_Param (1, Info.Name);
      Query.Set_Filter ("o.name = ?");
      Service.Project.Find (Service.DB, Query, Found);
      if Found then
         Log.Warn ("Project name {0} already used", Name);
         raise Name_Used;
      end if;
      Service.Project.Set_Name (Name);
      Service.Project.Set_Create_Date (Ada.Calendar.Clock);
      Service.Project.Set_Status (Projects.Models.PROJECT_ACTIVE);
      Service.Project.Set_Scm_Url (Info.URI);
      Service.Project.Set_Scm (Info.Kind);
      Service.Project.Set_Check_Delay (Configs.Get (PROJECT_CHECK_DELAY_NAME,
                                                    PROJECT_DEFAULT_CHECK_DELAY));
      Service.Project.Save (Service.DB);

      --  Service.Build_Config.Set_Project (Service.Project);
      --  Service.Build_Config.Set_Node (Service.Build_Node);
      --  Service.Build_Config.Save (Service.DB);
      Service.DB.Commit;

      Log.Info ("Project {0} added", Name);
   end Add_Project;

   procedure Add_Branch (Service : in out Context_Type;
                         Name    : in String;
                         Item    : in Porion.Sources.Branch_Type;
                         Is_Head : in Boolean) is

      Query  : ADO.SQL.Query;
      Found  : Boolean;
      Now    : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      Query.Set_Filter ("o.name = ? AND o.project_id = ?");
      Query.Bind_Param (1, Name);
      Query.Bind_Param (2, Service.Project.Get_Id);
      Service.Branch.Find (Service.DB, Query, Found);
      if not Found then
         Service.Branch.Set_Project (Service.Project);
         Service.Branch.Set_Name (Name);
         Service.Branch.Set_Main_Branch (Is_Head);
         Service.Branch.Set_Tag (Item.Tag);
         Service.Branch.Set_Rate_Factor (100);
         if Is_Head then
            Service.Branch.Set_Status (Models.BUILD_REQUIRED);
         else
            Service.Branch.Set_Status (Models.BUILD_DISABLED);
         end if;
         Service.Branch.Set_Create_Date (Now);
      else
         Service.Branch.Set_Tag (Item.Tag);
      end if;
      if Service.Branch.Is_Modified then
         if Service.Branch.Get_Status /= Models.BUILD_DISABLED then
            Service.Branch.Set_Status (Projects.Models.BUILD_REQUIRED);
         end if;
         Service.Branch.Set_Update_Date (Now);
         Service.Branch.Save (Service.DB);
      end if;
   end Add_Branch;

   --  ------------------------------
   --  Remove a project with the given name and all its build data.
   --  ------------------------------
   procedure Remove_Project (Service : in out Context_Type;
                             Name    : in String) is
      procedure Execute (Definition : in ADO.Queries.Query_Definition_Access);

      procedure Execute (Definition : in ADO.Queries.Query_Definition_Access) is
         Query  : ADO.Queries.Context;
      begin
         Query.Set_Query (Definition);
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
         declare
            Stmt   : ADO.Statements.Query_Statement := Service.DB.Create_Statement (Query);
         begin
            Stmt.Execute;
         end;
      end Execute;

      Query : ADO.SQL.Query;
      Found : Boolean;
   begin
      Service.DB.Begin_Transaction;
      Query.Bind_Param (1, Name);
      Query.Set_Filter ("o.name = ?");
      Service.Project.Find (Service.DB, Query, Found);
      if not Found then
         Log.Warn ("Project name {0} already used", Name);
         raise Not_Found;
      end if;

      --  Cleanup unit test data.
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Test_Run);
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Test_Run_Group);
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Test);
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Test_Group);

      --  Cleanup build data.
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Build_Step);
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Last_Build);
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Build);

      --  Cleanup build config.
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Environment);
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Build_Config_Step);
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Build_Config);

      --  Cleanup project branches.
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Branch);
      Execute (Porion.Projects.Models.Query_Cleanup_Project_Dependency);

      Service.Project.Delete (Service.DB);
      Service.DB.Commit;

      declare
         Dir : constant String := Porion.Configs.Get_Project_Directory (Name);
      begin
         if Ada.Directories.Exists (Dir) then
            Ada.Directories.Delete_Tree (Dir);
         end if;
      end;

   end Remove_Project;

   --  ------------------------------
   --  Add a dependency on the current project.
   --  ------------------------------
   procedure Add_Dependency (Service : in out Context_Type;
                             Depend  : in String) is
      Project    : Porion.Projects.Models.Project_Ref;
      Dependency : Porion.Projects.Models.Dependency_Ref;
      Query      : ADO.SQL.Query;
      Found      : Boolean;
   begin
      Log.Debug ("Adding dependency to {0}", Depend);

      Query.Set_Filter ("o.name = ?");
      Query.Bind_Param (1, Depend);
      Project.Find (Session => Service.DB,
                    Query   => Query,
                    Found   => Found);
      if not Found then
         Log.Warn ("Project {0} not found", Depend);
         raise Not_Found;
      end if;

      Query.Clear;
      Query.Set_Filter ("o.owner_id = :owner_id AND o.project_id = :project_id");
      Query.Bind_Param ("owner_id", Service.Project.Get_Id);
      Query.Bind_Param ("project_id", Project.Get_Id);
      Dependency.Find (Session => Service.DB,
                       Query   => Query,
                       Found   => Found);
      if Found then
         Log.Info ("Project {0} already depends on {1}",
                   String '(Service.Project.Get_Name), Depend);
         return;
      end if;

      Dependency.Set_Owner (Service.Project);
      Dependency.Set_Project (Project);
      Dependency.Save (Service.DB);

      Log.Info ("Project {0} now depends on {1}",
                String '(Service.Project.Get_Name), Depend);

      --  Update the build queue order.
      Porion.Builds.Services.Update_Build_Queue (Service, Trigger_Builds => False);
   end Add_Dependency;

   --  ------------------------------
   --  Remove a dependency on the current project.
   --  ------------------------------
   procedure Remove_Dependency (Service : in out Context_Type;
                                Depend  : in String) is
      Project    : Porion.Projects.Models.Project_Ref;
      Dependency : Porion.Projects.Models.Dependency_Ref;
      Query      : ADO.SQL.Query;
      Found      : Boolean;
   begin
      Log.Debug ("Removing dependency to {0}", Depend);

      Query.Set_Filter ("o.name = ?");
      Query.Bind_Param (1, Depend);
      Project.Find (Session => Service.DB,
                    Query   => Query,
                    Found   => Found);
      if not Found then
         Log.Warn ("Project {0} not found", Depend);
         raise Not_Found;
      end if;

      Query.Clear;
      Query.Set_Filter ("o.owner_id = :owner_id AND o.project_id = :project_id");
      Query.Bind_Param ("owner_id", Service.Project.Get_Id);
      Query.Bind_Param ("project_id", Project.Get_Id);
      Dependency.Find (Session => Service.DB,
                       Query   => Query,
                       Found   => Found);
      if not Found then
         Log.Info ("Project {0} does not depend on {1}",
                   String '(Service.Project.Get_Name), Depend);
         return;
      end if;

      Dependency.Delete (Service.DB);

      Log.Info ("Project {0} now does not depend on {1}",
                String '(Service.Project.Get_Name), Depend);
   end Remove_Dependency;

   procedure Check_Sources (Service  : in out Context_Type;
                            Executor : in out Porion.Executors.Executor_Type'Class;
                            Force    : in Boolean) is
      Now    : constant Ada.Calendar.Time := Ada.Calendar.Clock;
      List   : Porion.Projects.Models.Project_Vector;
      Query  : ADO.SQL.Query;
      Status : Porion.Sources.Status_Type;
   begin
      if Force then
         Query.Set_Filter ("o.status != 1");
      else
         Query.Set_Filter ("o.status != 1 AND o.next_check_date < :now");
         Query.Bind_Param ("now", Now);
      end if;
      Porion.Projects.Models.List (List, Service.DB, Query);

      Log.Info ("Checking changes in {0} projects", Util.Strings.Image (Natural (List.Length)));

      for Project of List loop
         Service.Project := Project;
         Check_Sources (Service, Status, Executor);
      end loop;
   end Check_Sources;

   procedure Check_Sources (Service  : in out Context_Type;
                            Status   : in out Porion.Sources.Status_Type;
                            Executor : in out Porion.Executors.Executor_Type'Class) is
      use Porion.Sources;
      use type Ada.Calendar.Time;

      Name       : constant String := Service.Project.Get_Name;
      Log_Dir    : constant String := Configs.Get_Source_Log_Directory (Name);
      Config     : Porion.Configs.Config_Type;
      Query      : ADO.Queries.Context;
      Branches   : Porion.Projects.Models.Branch_Vector;
      Src_Status : Porion.Sources.Status_Type;
      Queue_Added : Boolean := False;
      Source_Controller : Porion.Sources.Controller_Access;
      Now        : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      Log.Info ("Checking changes in {0}", Name);

      Executor.Create_Logger (Log_Dir, "source.log");
      Executor.Set_Step (Builds.STEP_CHECKOUT);

      Config.Set ("repository_url", String '(Service.Project.Get_Scm_Url));
      Source_Controller := Sources.Factories.Create (Service.Project.Get_Scm, Config);

      Source_Controller.Check (Src_Status, Executor);

      --  Get the current known branches.
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Query.Set_Filter ("o.project_id = :project_id");
      Projects.Models.List (Branches, Service.DB, Query);

      Service.Project.Set_Check_Date (Now);
      Service.Project.Set_Next_Check_Date (Now + Duration (Service.Project.Get_Check_Delay));
      Service.Project.Save (Service.DB);

      Status.Head := Src_Status.Head;
      for Item in Src_Status.Changes.Iterate loop
         declare
            Name    : constant String := Maps.Key (Item);
            Branch  : constant Maps.Reference_Type := Maps.Reference (Src_Status.Changes, Item);
            Is_Head : constant Boolean := Name = To_String (Src_Status.Head);
            Found   : Boolean := False;
            Added   : Boolean;
         begin
            for Iter in 1 .. Integer (Branches.Length) loop
               declare
                  Existing_Branch : constant Models.Branch_Ref := Branches.Element (Iter);
               begin
                  if String '(Existing_Branch.Get_Name) = Name then
                     Service.Branch := Existing_Branch;
                     Branch.Last_Tag := Existing_Branch.Get_Tag;
                     Service.Branch.Set_Tag (Branch.Tag);
                     if Service.Branch.Is_Modified then
                        if Service.Branch.Get_Status /= Models.BUILD_DISABLED then
                           Service.Branch.Set_Status (Projects.Models.BUILD_REQUIRED);
                           Log.Info ("Build required for branch {0}", Name);
                           Builds.Services.Add_Build_Queue (Service,
                                                            Builds.Models.REASON_SCM,
                                                            Added);
                           if Added then
                              Queue_Added := True;
                           end if;
                        end if;
                        Service.Branch.Set_Update_Date (Now);
                        Service.Branch.Save (Service.DB);
                     else
                        Log.Info ("No change on branch {0}", Name);
                     end if;
                     Found := True;
                     Branches.Delete (Iter);
                     exit;
                  end if;
               end;
            end loop;

            if not Found then
               Add_Branch (Service, Name, Branch, Is_Head);
               if Service.Branch.Get_Status = Models.BUILD_REQUIRED then
                  Log.Info ("Build required for new branch {0}", Name);
                  Builds.Services.Add_Build_Queue (Service,
                                                   Builds.Models.REASON_SCM,
                                                   Added);
                  if Added then
                     Queue_Added := True;
                  end if;
               end if;
            end if;
         end;
      end loop;

      --  Mark disabled the branches that are deleted.
      for Branch of Branches loop
         Branch.Set_Status (Models.BUILD_DISABLED);
         if Branch.Is_Modified then
            Branch.Save (Service.DB);
         end if;
      end loop;

      if Queue_Added then
         Builds.Services.Update_Build_Queue (Service, Trigger_Builds => False);
      end if;
   end Check_Sources;

   procedure Write_Date (Stream : in out Util.Serialize.IO.Output_Stream'Class;
                         Name   : in String;
                         Date   : in ADO.Nullable_Time) is
   begin
      if Date.Is_Null then
         Stream.Write_Null_Entity (Name);
      else
         Stream.Write_Entity (Name,
                              Util.Dates.ISO8601.Image (Date.Value, Util.Dates.ISO8601.SECOND));
      end if;
   end Write_Date;

   procedure Write_Date (Stream : in out Util.Serialize.IO.Output_Stream'Class;
                         Name   : in String;
                         Date   : in Ada.Calendar.Time) is
   begin
      Stream.Write_Entity (Name,
                           Util.Dates.ISO8601.Image (Date, Util.Dates.ISO8601.SECOND));
   end Write_Date;

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class;
                     Process : access
                       procedure (Stream : in out Util.Serialize.IO.Output_Stream'Class)) is
   begin
      Stream.Start_Entity ("project");
      Stream.Write_Attribute ("id", Integer (Service.Project.Get_Id));
      Stream.Write_Attribute ("version", Service.Project.Get_Version);
      Stream.Write_Entity ("name", String '(Service.Project.Get_Name));
      Stream.Write_Entity ("description", String '(Service.Project.Get_Description));
      Write_Date (Stream, "create_date", Service.Project.Get_Create_Date);
      Write_Date (Stream, "update_date", Service.Project.Get_Update_Date);
      Stream.Write_Entity ("status", Service.Project.Get_Status'Image);
      Stream.Write_Entity ("scm", Service.Project.Get_Scm'Image);
      Stream.Write_Entity ("scm_url", String '(Service.Project.Get_Scm_Url));
      declare
         Branches : Porion.Projects.Models.Branch_Vector;
         Query    : ADO.Queries.Context;
      begin
         Query.Set_Filter ("o.project_id = :project_id");
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
         Porion.Projects.Models.List (Branches, Service.DB, Query);

         Stream.Start_Array ("branches");
         for Branch of Branches loop
            Stream.Start_Entity ("branch");
            Stream.Write_Attribute ("id", Integer (Branch.Get_Id));
            Stream.Write_Attribute ("version", Branch.Get_Version);
            Stream.Write_Entity ("name", String '(Branch.Get_Name));
            Stream.Write_Entity ("tag", String '(Branch.Get_Tag));
            Write_Date (Stream, "create_date", Branch.Get_Create_Date);
            Write_Date (Stream, "update_date", Branch.Get_Update_Date);
            Write_Date (Stream, "last_date", Branch.Get_Last_Date);
            Stream.Write_Entity ("status", Branch.Get_Status'Image);
            Stream.End_Entity ("branch");
         end loop;
         Stream.End_Array ("branches");
      end;
      if Process /= null then
         Process (Stream);
      end if;
      Stream.End_Entity ("project");
   end Export;

   procedure Update (Service : in out Context_Type;
                     Project : in out Porion.Projects.Models.Project_Ref) is
      Id    : constant ADO.Identifier := Project.Get_Id;
      Found : Boolean;
   begin
      if Id = ADO.NO_IDENTIFIER then
         Log.Error ("Cannot load project");
         return;
      end if;

      if not Project.Is_Loaded then
         Service.Project.Load (Session => Service.DB,
                               Id      => Id,
                               Found   => Found);
         if not Found then
            Log.Error ("Project not found");
            return;
         end if;
      end if;

      Service.DB.Begin_Transaction;
      Service.Project := Project;
      if Service.Project.Is_Modified then
         Service.Project.Set_Update_Date ((Is_Null => False,
                                           Value   => Ada.Calendar.Clock));
         Service.Project.Save (Service.DB);
      end if;

      Service.DB.Commit;
   end Update;

   procedure Set_Name (Service  : in out Context_Type;
                       Name     : in String;
                       Modified : out Boolean) is
   begin
      Service.DB.Begin_Transaction;
      if not Service.Recipe.Is_Null then
         declare
            Stmt : ADO.Statements.Query_Statement :=
               Service.DB.Create_Statement ("SELECT COUNT(*) FROM porion_recipe AS r "
                                            & "WHERE r.project_id = :project_id "
                                            & "AND r.branch_id = :branch_id "
                                            & "AND r.name = :name");
         begin
            Stmt.Bind_Param ("project_id", Service.Project.Get_Id);
            Stmt.Bind_Param ("branch_id", Service.Branch.Get_Id);
            Stmt.Bind_Param ("name", Name);
            Stmt.Execute;
            if Stmt.Get_Result_Integer /= 0 then
               Service.DB.Rollback;
               Log.Warn ("Name {0} already used by another recipe", Name);
               raise Invalid_Name;
            end if;
            Service.Recipe.Set_Name (Name);
            Modified := Service.Recipe.Is_Modified;
            Service.Recipe.Save (Service.DB);
         end;
      end if;
      Service.DB.Commit;
   end Set_Name;

   --  ------------------------------
   --  Set the description associated with the project.
   --  ------------------------------
   procedure Set_Description (Service     : in out Context_Type;
                              Description : in String;
                              Modified    : out Boolean) is
   begin
      Service.DB.Begin_Transaction;
      if Service.Branch.Is_Null then
         Log.Info ("Set project description on {0} to {1}",
                   String '(Service.Project.Get_Name), Description);

         Service.Project.Set_Description (Description);
         Modified := Service.Project.Is_Modified;
         Service.Project.Save (Service.DB);
      else
         Log.Info ("Set branch description on {0}#{1} to {2}",
                   String '(Service.Project.Get_Name),
                   Service.Branch.Get_Name, Description);

         Service.Branch.Set_Description (Description);
         Modified := Service.Branch.Is_Modified;
         Service.Branch.Save (Service.DB);
      end if;
      Service.DB.Commit;
   end Set_Description;

   --  ------------------------------
   --  Set the project status to enable, disable or put the project onhold.
   --  ------------------------------
   procedure Set_Status (Service  : in out Context_Type;
                         Status   : in String;
                         Modified : out Boolean) is
      Project_Status : Models.Project_Status_Type;
      Branch_Status  : Models.Branch_Status_Type;
   begin
      if Status = "enable" or Status = "1" then
         Project_Status := Models.PROJECT_ACTIVE;
         Branch_Status := Models.BUILD_DISABLED;
      elsif Status = "disabled" or Status = "0" then
         Project_Status := Models.PROJECT_DISABLED;
         Branch_Status := Models.BUILD_DISABLED;
      elsif Status = "hold" then
         Project_Status := Models.PROJECT_ONHOLD;
         Branch_Status := Models.BUILD_DISABLED;
      else
         Log.Warn ("Invalid status value {0}", Status);
         raise Bad_Value;
      end if;

      Service.DB.Begin_Transaction;
      if Service.Branch.Is_Null then
         Log.Info ("Set project status on {0} to {1}",
                   String '(Service.Project.Get_Name), Status);

         Service.Project.Set_Status (Project_Status);
         Modified := Service.Project.Is_Modified;
         Service.Project.Save (Service.DB);
      else
         Log.Info ("Set branch status on {0}#{1} to {2}",
                   String '(Service.Project.Get_Name),
                   Service.Branch.Get_Name, Status);

         Service.Branch.Set_Status (Branch_Status);
         Modified := Service.Branch.Is_Modified;
         Service.Branch.Save (Service.DB);
      end if;
      Service.DB.Commit;
   end Set_Status;

   --  ------------------------------
   --  Set the project check delay used by the check command to periodically
   --  check for source changes in the project branches.
   --  Raises Bad_Value if the status value is not correct.
   --  ------------------------------
   procedure Set_Check_Delay (Service  : in out Context_Type;
                              Value    : in String;
                              Modified : out Boolean) is
      Check_Delay : Natural;
   begin
      begin
         Check_Delay := Natural'Value (Value);

      exception
         when Constraint_Error =>
            raise Bad_Value;
      end;

      Log.Info ("Set project check delay on {0} to {1}",
                String '(Service.Project.Get_Name), Value);
      Service.DB.Begin_Transaction;
      Service.Project.Set_Check_Delay (Check_Delay);
      Modified := Service.Project.Is_Modified;
      Service.Project.Save (Service.DB);
      Service.DB.Commit;
   end Set_Check_Delay;

   --  ------------------------------
   --  Set the branch or recipe rate factor.
   --  ------------------------------
   procedure Set_Rate_Factor (Service  : in out Context_Type;
                              Factor   : in String;
                              Modified : out Boolean) is
      Value : Rate_Type;
   begin
      begin
         Value := Rate_Type'Value (Factor);

      exception
         when Constraint_Error =>
            raise Bad_Value;
      end;

      Service.DB.Begin_Transaction;
      if Service.Recipe.Is_Null then
         Service.Branch.Set_Rate_Factor (Value);
         Modified := Service.Branch.Is_Modified;
         Service.Branch.Save (Service.DB);
      else
         Service.Recipe.Set_Rate_Factor (Value);
         Modified := Service.Recipe.Is_Modified;
         Service.Recipe.Save (Service.DB);
      end if;
      if Modified then
         Porion.Builds.Services.Update_Branch_Ratings (Service);
      end if;
      Service.DB.Commit;
   end Set_Rate_Factor;

   --  Replace several special characters by ' ' which is the separator
   --  used to split filtering rules.
   Rule_Translate_Map : constant Ada.Strings.Maps.Character_Mapping
     := Ada.Strings.Maps.To_Mapping
       (From => ",;/\",
        To   => "    ");

   --  ------------------------------
   --  Set the recipe filter rules.
   --  ------------------------------
   procedure Set_Filter_Rules (Service  : in out Context_Type;
                               Rules    : in String;
                               Modified : out Boolean) is
      Value : constant String := Ada.Strings.Fixed.Translate (Rules, Rule_Translate_Map);
   begin
      Log.Info ("Set filter rules to '{0}'' on recipe {1}", Value, Service.Get_Recipe_Name);

      Service.DB.Begin_Transaction;
      Service.Recipe.Set_Filter_Rules (Value);
      Modified := Service.Recipe.Is_Modified;
      Service.Recipe.Save (Service.DB);
      Service.DB.Commit;
   end Set_Filter_Rules;

end Porion.Projects.Services;
