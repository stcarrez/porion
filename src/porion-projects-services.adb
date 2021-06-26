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
with Util.Properties;
with Util.Log.Loggers;
with Util.Strings.Vectors;
with Util.Files;
with EL.Expressions;
with Porion.Configs;
with Porion.Projects.Models;
with Porion.Sources.Factories;
with ADO.Configs;
with ADO.SQLite;
with ADO.SQL;
with ADO.Queries;
with ADO.Statements;
with Porion.Builders.Scripts;
with Yaml.Source.Text_IO;
with Yaml.Source.File;
with Yaml.Parser;
package body Porion.Projects.Services is

   --  The logger
   Log   : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Projects.Services");

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

   procedure Set_Source_Control (Project : in out Porion.Projects.Models.Project_Ref;
                                 Mode    : in String) is
   begin
      Project.Set_Scm_Url (Mode);
      if Util.Strings.Ends_With (Mode, ".git") then
         Project.Set_Scm (Porion.Projects.Models.SRC_GIT);
      else
         Project.Set_Scm (Porion.Projects.Models.SRC_FILE);
      end if;
   end Set_Source_Control;

   procedure Add_Project (Service   : in out Context_Type;
                          Name      : in String;
                          Mode      : in String;
                          Parameter : in String) is
      Query : ADO.SQL.Query;
      Cfg   : Projects.Models.Build_Config_Ref;
      Found : Boolean;
   begin
      Log.Debug ("Add project {0} with {1}", Name, Mode);

      Service.DB.Begin_Transaction;
      Query.Bind_Param (1, Name);
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
      Set_Source_Control (Service.Project, Mode);
      Service.Project.Save (Service.DB);

      Cfg.Set_Project (Service.Project);
      Cfg.Save (Service.DB);
      Service.DB.Commit;

      Log.Info ("Project {0} added", Name);
   end Add_Project;

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

   procedure Add_Branch (Service : in out Context_Type;
                         Name    : in String;
                         Item    : in Porion.Sources.Branch_Type) is
      use type Porion.Projects.Models.Branch_Status_Type;

      Query  : ADO.SQL.Query;
      Found  : Boolean;
      Now    : Ada.Calendar.Time := Ada.Calendar.Clock;
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
   begin
      if Service.Project.Is_Null then
         raise Name_Used;
      end if;

      Config.Set ("repository_url", String '(Service.Project.Get_Scm_Url));
      Service.Source_Controller := Porion.Sources.Factories.Create ("git", Config);

      Service.Source_Controller.Check (Status);

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

   procedure Build (Service : in out Context_Type;
                    Branch_Name : in String;
                    Branch      : in Porion.Sources.Branch_Type) is
   begin
      if Service.Project.Is_Null then
         raise Name_Used;
      end if;
      if Service.Branch.Is_Null then
         raise Name_Used;
      end if;

      Service.Build.Set_Project (Service.Project);
      Service.Build.Set_Branch (Service.Branch);
      Service.Build.Set_Create_Date (Ada.Calendar.Clock);
      declare
         Name : constant String := Service.Project.Get_Name;
         Path : constant String := Porion.Configs.Get_Project_Directory (Name);
         Config : Util.Properties.Manager;
      begin
         Log.Info ("Build {0} in {1}", Name, Path);

         if not Ada.Directories.Exists (Path) then
            Ada.Directories.Create_Path (Path);
         end if;
         Service.Source_Controller.Checkout (Path);

         Config.Set ("build_dir", Util.Files.Compose (Path, Name));
         Service.Build_Controller := Porion.Builders.Scripts.Create (Config);
         Service.Build_Controller.Build;
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
         Log.Error (Yaml.To_String (Cur));
         exit when Cur.Kind = Yaml.Stream_End;
      end loop;
   end Load;

   function Create_Query (Service : in out Context_Type;
                          Query   : in ADO.Queries.Context) return Ado.Statements.Query_Statement is
   begin
      return Service.DB.Create_Statement (Query);
   end Create_Query;

   procedure Open (Service : in out Context_Type) is
      Path   : constant String := Porion.Configs.Get_Database_Path;
      Config : Util.Properties.Manager;
   begin
      Config.Set (ADO.Configs.QUERY_PATHS_CONFIG, "db");
      Config.Set (ADO.Configs.DYNAMIC_DRIVER_LOAD, "false");
      Config.Set (ADO.Configs.QUERY_LOAD_CONFIG, "true");
      ADO.SQLite.Initialize (Config);
      Service.Factory.Create (Path);
      Service.DB := Service.Factory.Get_Master_Session;
   end Open;

end Porion.Projects.Services;
