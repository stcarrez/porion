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
with Ada.Directories;
with Util.Log.Loggers;
with Util.Strings;
with Util.Properties;
with Porion.Configs;
with Porion.Loggers;
with Porion.Sources.Factories;
with ADO.Configs;
with ADO.Sqlite;
with ADO.SQL;
with Porion.Projects.Schema;
with Porion.Builders.Scripts;
with Porion.Resources;
with Yaml.Source.File;
with Yaml.Parser;
package body Porion.Projects.Services is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Projects.Services");

   function Get_Query_Resource (Name : in String) return access constant String is
   begin
      Log.Info ("Get query resource {0}", Name);

      return Porion.Resources.Get_Content (Name);
   end Get_Query_Resource;

   function Make_Project_Name (URI : in String) return String is
      Last : Natural := Util.Strings.Rindex (URI, '/');
   begin
      if Last > 0 then
         return Make_Project_Name (URI (Last + 1 .. URI'Last));
      end if;

      Last := Util.Strings.Rindex (URI, '.');
      if Last > 0 then
         if Util.Strings.Ends_With (URI, ".git") then
            return URI (URI'First .. Last - 1);
         end if;

         return URI (URI'First .. Last - 1);
      end if;

      return URI;
   end Make_Project_Name;

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
      Cfg   : Porion.Builds.Models.Build_Config_Ref;
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
      Service.Project.Set_Update_Date (Service.Project.Get_Create_Date);
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

   --  ------------------------------
   --  Get the current project id.
   --  ------------------------------
   function Get_Project_Id (Service : in Context_Type) return ADO.Identifier is
   begin
      return Service.Project.Get_Id;
   end Get_Project_Id;

   procedure Load_Project (Service : in out Context_Type;
                           Name    : in String) is
      Query : ADO.SQL.Query;
      Found : Boolean;
   begin
      Log.Debug ("Load project {0}", Name);

      Query.Bind_Param (1, Name);
      Query.Set_Filter ("o.name = ?");
      Service.Project.Find (Service.DB, Query, Found);
      if not Found then
         Log.Warn ("Project name {0} does not exist", Name);
         raise Name_Used;
      end if;

   end Load_Project;

   --  ------------------------------
   --  Load the build node corresponding to the given hostname.
   --  ------------------------------
   procedure Load_Node (Service  : in out Context_Type;
                        Hostname : in String) is
      Query : ADO.SQL.Query;
      Found : Boolean;
   begin
      Log.Debug ("Load build node {0}", Hostname);

      Query.Bind_Param (1, Hostname);
      Query.Set_Filter ("o.name = ?");
      Service.Build_Node.Find (Service.DB, Query, Found);
      if not Found then
         Log.Warn ("Build node {0} does not exist", Hostname);
         raise Name_Used;
      end if;

   end Load_Node;

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
      Service.Source_Controller := Porion.Sources.Factories.Create (Service.Project.Get_Scm, Config);

      Service.Source_Controller.Check (Status, Logger);

      Query.Set_Query (Porion.Projects.Models.Query_Project_Branches);
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      declare
         Stmt   : ADO.Statements.Query_Statement := Service.DB.Create_Statement (Query);
      begin
         Stmt.Execute;
         while Stmt.Has_Elements loop
            declare
               Id    : constant ADO.Identifier := Stmt.Get_Identifier (0);
               Name  : constant String := Stmt.Get_String (1);
               Tag   : constant String := Stmt.Get_String (2);
               Date  : constant ADO.Nullable_Time := Stmt.Get_Nullable_Time (3);
               Build_Date : constant ADO.Nullable_Time := Stmt.Get_Nullable_Time (4);
               Count : constant Natural := Stmt.Get_Integer (5);

               procedure Update (Key  : in String;
                                 Item : in out Branch_Type);

               procedure Update (Key  : in String;
                                 Item : in out Branch_Type) is
                  pragma Unreferenced (Key);
               begin
                  Item.Last_Tag := To_UString (Tag);
                  --  if Date.Is_Null then
                  --  end if;
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
            if Branch.Tag /= Branch.Last_Tag then
               null;
            end if;
         end;
      end loop;
   end Check_Sources;

   procedure Start_Build (Service     : in out Context_Type;
                          Branch_Name : in String;
                          Branch      : in Porion.Sources.Branch_Type) is
      Query : ADO.Queries.Context;
      Found : Boolean;
      Stmt  : ADO.Statements.Query_Statement;
   begin
      if Service.Build_Node.Is_Null then
         Service.Load_Node ("localhost");
      end if;

      Add_Branch (Service, Branch_Name, Branch);

      Query.Set_Query (Projects.Models.Query_Project_Last_Build);
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
      Stmt := Service.DB.Create_Statement (Query);
      Stmt.Execute;

      Service.Build := Porion.Builds.Models.Null_Build;
      Service.Build.Set_Number (Stmt.Get_Result_Integer + 1);

      if Service.Build_Config.Is_Null then
         Query.Clear;
         Query.Bind_Param (1, Service.Project.Get_Id);
         Query.Bind_Param (2, Service.Build_Node.Get_Id);
         Query.Set_Filter ("o.project_id = ? AND o.node_id = ?");
         Service.Build_Config.Find (Service.DB, Query, Found);
         if not Found then
            Service.Build_Config.Set_Node (Service.Build_Node);
            Service.Build_Config.Set_Project (Service.Project);
            Service.Build_Config.Save (Service.DB);
         end if;
      end if;

      Service.Build.Set_Project (Service.Project);
      Service.Build.Set_Branch (Service.Branch);
      Service.Build.Set_Node (Service.Build_Node);
      Service.Build.Set_Build_Config (Service.Build_Config);
      Service.Build.Set_Create_Date (Ada.Calendar.Clock);
      Service.Build.Save (Service.DB);

      Service.Branch.Set_Last_Build_Id (Service.Build.Get_Id);
      Service.Branch.Save (Service.DB);
      Service.DB.Commit;

      Log.Info ("Created build{0} for {1}", Natural'Image (Service.Build.Get_Number),
                Service.Project.Get_Name);
   end Start_Build;

   procedure Build (Service     : in out Context_Type;
                    Branch_Name : in String;
                    Branch      : in Porion.Sources.Branch_Type) is
   begin
      if Service.Project.Is_Null then
         raise Name_Used;
      end if;

      Start_Build (Service, Branch_Name, Branch);

      declare
         Number  : constant Positive := Service.Build.Get_Number;
         Name    : constant String := Service.Project.Get_Name;
         Path    : constant String := Configs.Get_Build_Directory (Name, Branch_Name, Number);
         Log_Dir : constant String := Configs.Get_Build_Log_Directory (Name, Branch_Name, Number);
         Config  : Util.Properties.Manager;
         Logger  : Porion.Loggers.Logger_Type;
      begin
         Log.Info ("Build {0} in {1}", Name, Path);

         if not Ada.Directories.Exists (Path) then
            Ada.Directories.Create_Path (Path);
         end if;

         Logger.Create (Log_Dir, "build.log");
         Service.Source_Controller.Checkout (Path, Logger);

         Config.Set ("build_dir", Path);
         Service.Build_Controller := Porion.Builders.Scripts.Create (Config);
         Service.Build_Controller.Build (Logger);

         Service.Build.Set_Finish_Date (ADO.Nullable_Time '(Is_Null => False,
                                                            Value => Ada.Calendar.Clock));
         Service.Build.Save (Service.DB);
      end;
   end Build;

   procedure Load (Service : in out Context_Type;
                   Path : in String) is
      use type Yaml.Source.Pointer;
      use type Yaml.Event_Kind;

      Input : Yaml.Source.Pointer;
      P     : Yaml.Parser.Instance;
      Cur   : Yaml.Event;
   begin
      Input := Yaml.Source.File.As_Source (Path);
      P.Set_Input (Input);
      loop
         Cur := P.Next;
         --  Log.Error (Yaml.To_String (Cur));
         exit when Cur.Kind = Yaml.Stream_End;
      end loop;
   end Load;

   function Create_Query (Service : in out Context_Type;
                          Query   : in ADO.Queries.Context) return Ado.Statements.Query_Statement is
   begin
      return Service.DB.Create_Statement (Query);
   end Create_Query;

   function Get_Database (Service : in Context_Type) return ADO.Sessions.Master_Session is
   begin
      return Service.DB;
   end Get_Database;

   function Get_Build (Service : in Context_Type) return Porion.Builds.Models.Build_Ref is
   begin
      return Service.Build;
   end Get_Build;

   procedure Open (Service : in out Context_Type;
                   Create  : in Boolean := False) is
      Path   : constant String := Porion.Configs.Get_Database_Path
        & (if Create then "?create=true" else "");
      Config : Util.Properties.Manager;
   begin
      Config.Set (ADO.Configs.QUERY_PATHS_CONFIG, "db");
      Config.Set (ADO.Configs.DYNAMIC_DRIVER_LOAD, "false");
      Config.Set (ADO.Configs.QUERY_LOAD_CONFIG, "true");
      Config.Set (ADO.Configs.NO_ENTITY_LOAD, (if Create then "true" else "false"));
      ADO.SQLite.Initialize (Config);
      Service.Factory.Set_Query_Loader (Get_Query_Resource'Access);
      Service.Factory.Create (Path);
      Service.DB := Service.Factory.Get_Master_Session;

      if Create then
         declare
            use Porion.Projects.Schema;

            List : constant Porion.Projects.Schema.Content_Access
              := Porion.Projects.Schema.Get_Content ("create-porion-sqlite");
         begin
            if List = null then
               Log.Error ("Cannot find the database schema!");
               return;
            end if;

            for Query of List.all loop
               declare
                  Stmt : ADO.Statements.Query_Statement
                    := Service.DB.Create_Statement (Query.all);
               begin
                  Stmt.Execute;
               end;
            end loop;
         end;
      end if;
   end Open;

end Porion.Projects.Services;
