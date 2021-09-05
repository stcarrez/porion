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
with Ada.Calendar;
with Util.Log.Loggers;
with Util.Properties;
with Util.Dates.ISO8601;
with Porion.Configs;
with Porion.Loggers;
with Porion.Sources.Factories;
with ADO.SQL;
with ADO.Queries;
with ADO.Statements;
with Porion.Builds.Models;
with Porion.Projects.Models;
package body Porion.Projects.Services is

   use type ADO.Identifier;

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Projects.Services");

   --  ------------------------------
   --  Add a build node
   --  ------------------------------
   procedure Add_Node (Service   : in out Context_Type;
                       Hostname  : in String;
                       Login     : in String) is
      Query : ADO.SQL.Query;
      Found : Boolean;
   begin
      Log.Debug ("Add build node {0} with {1}", Hostname, Login);

      Service.DB.Begin_Transaction;
      Query.Bind_Param (1, Hostname);
      Query.Set_Filter ("o.name = ?");
      Service.Build_Node.Find (Service.DB, Query, Found);
      if Found then
         Log.Warn ("Build node name {0} already used", Hostname);
         raise Name_Used;
      end if;
      Service.Build_Node.Set_Name (Hostname);
      Service.Build_Node.Set_Login (Login);
      Service.Build_Node.Save (Service.DB);
      Service.DB.Commit;

      Log.Info ("Build node {0} added", Hostname);
   end Add_Node;

   procedure Add_Project (Service   : in out Context_Type;
                          Info      : in Porion.Sources.Source_Info_Type) is
      Name  : constant String := To_String (Info.Name);
      Query : ADO.SQL.Query;
      Found : Boolean;
   begin
      Log.Debug ("Add project {0}", Name);

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
      Service.Project.Save (Service.DB);

      Service.Build_Config.Set_Project (Service.Project);
      Service.Build_Config.Set_Node (Service.Build_Node);
      Service.Build_Config.Save (Service.DB);
      Service.DB.Commit;

      Log.Info ("Project {0} added", Name);
   end Add_Project;

   procedure Add_Branch (Service : in out Context_Type;
                         Name    : in String;
                         Item    : in Porion.Sources.Branch_Type) is
      use type Porion.Projects.Models.Branch_Status_Type;

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
         Service.Branch.Set_Tag (Item.Tag);
         Service.Branch.Set_Status (Porion.Projects.Models.BUILD_REQUIRED);
         Service.Branch.Set_Create_Date (Now);
      else
         Service.Branch.Set_Tag (Item.Tag);
      end if;
      if Service.Branch.Is_Modified then
         if Service.Branch.Get_Status = Projects.Models.BUILD_SUCCEEDED then
            Service.Branch.Set_Status (Projects.Models.BUILD_REQUIRED);
         end if;
         Service.Branch.Set_Update_Date (Now);
         Service.Branch.Save (Service.DB);
      end if;
   end Add_Branch;

   --  Remove a project with the given name and all its build data.
   procedure Remove_Project (Service : in out Context_Type;
                             Name    : in String) is

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
         raise Name_Used;
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

      Service.Project.Delete (Service.DB);
      Service.DB.Commit;
   end Remove_Project;

   procedure Check_Sources (Service : in out Context_Type;
                            Status  : in out Porion.Sources.Status_Type) is
      use Porion.Sources;

      Config : Porion.Configs.Config_Type;
      Query  : ADO.Queries.Context;
      Logger : Porion.Loggers.Logger_Type;
   begin
      if Service.Project.Is_Null then
         raise Name_Used;
      end if;

      declare
         Name    : constant String := Service.Project.Get_Name;
         Log_Dir : constant String := Configs.Get_Source_Log_Directory (Name, "master");
      begin
         Logger.Create (Log_Dir, "source.log");
      end;

      Config.Set ("repository_url", String '(Service.Project.Get_Scm_Url));
      Service.Source_Controller := Sources.Factories.Create (Service.Project.Get_Scm, Config);

      Service.Source_Controller.Check (Status, Logger);

      Query.Set_Query (Porion.Projects.Models.Query_Project_Branches);
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      declare
         Stmt   : ADO.Statements.Query_Statement := Service.DB.Create_Statement (Query);
      begin
         Stmt.Execute;
         while Stmt.Has_Elements loop
            declare
               --  Id    : constant ADO.Identifier := Stmt.Get_Identifier (0);
               Name  : constant String := Stmt.Get_String (1);
               Tag   : constant String := Stmt.Get_String (2);
               --  Date  : constant ADO.Nullable_Time := Stmt.Get_Nullable_Time (3);
               --  Build_Date : constant ADO.Nullable_Time := Stmt.Get_Nullable_Time (4);
               --  Count : constant Natural := Stmt.Get_Integer (5);

               procedure Update (Key  : in String;
                                 Item : in out Branch_Type);

               procedure Update (Key  : in String;
                                 Item : in out Branch_Type) is
                  pragma Unreferenced (Key);
               begin
                  Item.Last_Tag := To_UString (Tag);
               end Update;

               Pos  : constant Maps.Cursor := Status.Changes.Find (Name);
            begin
               if Maps.Has_Element (Pos) then
                  Status.Changes.Update_Element (Pos, Update'Access);
               end if;
            end;
            Stmt.Next;
         end loop;
      end;

      for Item in Status.Changes.Iterate loop
         declare
            Name   : constant String := Maps.Key (Item);
            Branch : constant Maps.Reference_Type := Maps.Reference (Status.Changes, Item);
         begin
            Add_Branch (Service, Name, Branch);
         end;
      end loop;
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
      Query : ADO.SQL.Query;
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

end Porion.Projects.Services;
