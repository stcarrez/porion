-----------------------------------------------------------------------
--  porion-services -- Project information
--  Copyright (C) 2021, 2022, 2023 Stephane Carrez
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
with Ada.Unchecked_Deallocation;

with Util.Strings;
with Util.Files;
with Util.Log.Loggers;
with Util.Properties;

with Keystore.Passwords.Keys;
with Keystore.Passwords.Files;

with Security.Random;

with ADO.Configs;
with ADO.Sqlite;
with ADO.SQL;
with ADO.Queries;
with ADO.Statements;

with Porion.Configs;
with Porion.Services.Parsers;
with Porion.Builds.Services;
with Porion.Nodes.Services;
with Porion.Projects.Services;
package body Porion.Services is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Services");

   --  ------------------------------
   --  Returns True if the service is opened.
   --  ------------------------------
   function Is_Open (Service : in Context_Type) return Boolean is
      use type ADO.Sessions.Connection_Status;
   begin
      return Service.DB.Get_Status = ADO.Sessions.OPEN;
   end Is_Open;

   --  ------------------------------
   --  Get the current project id.
   --  ------------------------------
   function Get_Project_Id (Service : in Context_Type) return ADO.Identifier is
   begin
      return Service.Project.Get_Id;
   end Get_Project_Id;

   --  ------------------------------
   --  Get the project branch identification string in the form <project>^<branch>.
   --  ------------------------------
   function Get_Branch_Name (Service : in Context_Type) return String is
      Project_Name  : constant String := Service.Branch.Get_Project.Get_Name;
      Branch_Name   : constant String := Service.Branch.Get_Name;
   begin
      return Project_Name & "^" & Branch_Name;
   end Get_Branch_Name;

   --  ------------------------------
   --  Get the identification of the current recipe in the form <project>#<branc>~<recipe>.
   --  ------------------------------
   function Get_Recipe_Name (Service : in Context_Type) return String is
      Branch_Name : constant String := Service.Get_Branch_Name;
   begin
      return Branch_Name & "~" & Service.Recipe.Get_Name;
   end Get_Recipe_Name;

   function Get_Recipe_Name (Service : in Context_Type;
                             Recipe  : in Porion.Builds.Models.Recipe_Ref'Class) return String is
   begin
      return "~" & Recipe.Get_Name;
   end Get_Recipe_Name;

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
         raise Not_Found;
      end if;

      Log.Info ("Project {0} loaded", Name);
   end Load_Project;

   procedure Load (Service : in out Context_Type;
                   Ident   : in Porion.Projects.Ident_Type) is
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
            raise Not_Found;
         end if;

         Log.Info ("Branch {0} loaded", Porion.Projects.To_String (Ident));
      end if;

      if Ident.Build > 0 then
         Query.Clear;
         Query.Set_Filter ("o.project_id = :project_id AND o.number = :number");
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
         Query.Bind_Param ("number", Ident.Build);
         Service.Build.Find (Service.DB, Query, Found);
         if not Found then
            Log.Warn ("Build {0} not found for project {1}",
                      Util.Strings.Image (Ident.Build), To_String (Ident.Name));
            raise Not_Found;
         end if;

         Log.Info ("Build {0} loaded", Porion.Projects.To_String (Ident));
         Service.Build_Node := Porion.Nodes.Models.Node_Ref (Service.Build.Get_Node);
         Service.Branch := Porion.Projects.Models.Branch_Ref (Service.Build.Get_Branch);
         Service.Recipe := Porion.Builds.Models.Recipe_Ref (Service.Build.Get_Recipe);
         return;
      end if;

      if Length (Ident.Node) > 0 then
         begin
            Nodes.Services.Load_Node (Service, To_String (Ident.Node));

         --  Transform the Nodes Not_Found exception into our Not_Found exception
         exception
            when Porion.Nodes.Services.Not_Found =>
               raise Not_Found;
         end;
      end if;

      if Length (Ident.Recipe) > 0 then
         Query.Clear;
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
         Query.Bind_Param ("recipe_name", Ident.Recipe);
         if not Service.Branch.Is_Null and not Service.Build_Node.Is_Null then
            Query.Set_Filter ("o.project_id = :project_id AND o.name = :recipe_name "
                              & "AND o.node_id = :node_id AND o.branch_id = :branch_id");
            Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
            Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
         elsif not Service.Branch.Is_Null then
            Query.Set_Filter ("o.project_id = :project_id AND o.name = :recipe_name "
                              & " AND o.branch_id = :branch_id");
            Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
         elsif not Service.Build_Node.Is_Null then
            Query.Set_Filter ("o.project_id = :project_id AND o.name = :recipe_name "
                              & " AND o.node_id = :node_id");
            Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
         else
            Query.Set_Filter ("o.project_id = :project_id AND o.name = :recipe_name ");
         end if;
         Service.Recipe.Find (Service.DB, Query, Found);
         if not Found then
            Log.Warn ("Recipe {0} not found for project {1}",
                      To_String (Ident.Recipe), To_String (Ident.Name));
            raise Not_Found;
         end if;

         Log.Info ("Recipe {0} loaded", Porion.Projects.To_String (Ident));
         if Service.Build_Node.Is_Null then
            Service.Build_Node := Porion.Nodes.Models.Node_Ref (Service.Recipe.Get_Node);
         end if;
         if Service.Branch.Is_Null then
            Service.Branch := Porion.Projects.Models.Branch_Ref (Service.Recipe.Get_Branch);
         end if;
         return;
      end if;

      if Service.Build_Node.Is_Null then
         Nodes.Services.Load_Default_Node (Service);
      end if;

      Query.Clear;
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
      if not Service.Branch.Is_Null and not Service.Build_Node.Is_Null then
         Query.Set_Filter ("o.project_id = :project_id AND o.node_id = :node_id "
                           & " AND o.branch_id = :branch_id AND o.main_recipe = 1");
         Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
      else
         Query.Set_Filter ("o.project_id = :project_id AND o.node_id = :node_id "
                           & "AND o.main_recipe = 1");
      end if;
      Service.Recipe.Find (Service.DB, Query, Found);
      if not Found then
         --  Don't treat this as an error because we may want to get the project+branch
         --  when it does not have any recipe yet.
         Log.Info ("Recipe not found");
         return;
      end if;
      if Service.Branch.Is_Null then
         Service.Branch := Porion.Projects.Models.Branch_Ref (Service.Recipe.Get_Branch);
      end if;
   end Load;

   procedure Open (Service  : in out Context_Type;
                   Resource : in Resources.Get_Resource_Access;
                   Schema   : in Resources.Content_Access) is
      use type Resources.Content_Access;

      Create  : constant Boolean := Schema /= null;
      Path    : constant String := Porion.Configs.Get_Database_Config (Create);
      Config : Util.Properties.Manager;
   begin
      Config.Set (ADO.Configs.QUERY_PATHS_CONFIG, "db");
      Config.Set (ADO.Configs.DYNAMIC_DRIVER_LOAD, "false");
      Config.Set (ADO.Configs.QUERY_LOAD_CONFIG, "true");
      Config.Set (ADO.Configs.NO_ENTITY_LOAD, (if Create then "true" else "false"));
      ADO.SQLite.Initialize (Config);
      Service.Factory.Set_Query_Loader (Resource.all'Access);
      Service.Factory.Create (Path);
      Service.DB := Service.Factory.Get_Master_Session;

      if Schema /= null then
         for Query of Schema.all loop
            declare
               Stmt : ADO.Statements.Query_Statement
                 := Service.DB.Create_Statement (Query.all);
            begin
               Stmt.Execute;
            end;
         end loop;
      end if;
   end Open;

   procedure Open (Service : in out Context_Type;
                   From    : in out Context_Type'Class) is
   begin
      Service.DB := From.DB;
      Service.Project := From.Project;
      Service.Branch := From.Branch;
      Service.Build_Node := From.Build_Node;
      Service.Dry_Run := From.Dry_Run;
   end Open;

   procedure Import (Service : in out Context_Type;
                     Path    : in String) is
      Content : Porion.Services.Parsers.Parser_Type;
   begin
      Porion.Services.Parsers.Parse (Service, Path, Content);

      Projects.Services.Update (Service, Content.Project);

      Builds.Services.Update (Service, Content.Build_Configs);
   end Import;

   --  ------------------------------
   --  Setup the directory to hold the database, configuration files
   --  and project space to checkout and build projects.
   --  ------------------------------
   procedure Setup (Service  : in out Context_Type;
                    Path     : in String;
                    Resource : in Resources.Get_Resource_Access;
                    Schema   : in Resources.Content_Access) is
      procedure Check_Empty (Ent : in Ada.Directories.Directory_Entry_Type);
      procedure Free is
        new Ada.Unchecked_Deallocation (Object => Keystore.Passwords.Provider'Class,
                                        Name   => Keystore.Passwords.Provider_Access);
      procedure Free is
        new Ada.Unchecked_Deallocation (Object => Keystore.Passwords.Keys.Key_Provider'Class,
                                        Name   => Keystore.Passwords.Keys.Key_Provider_Access);

      procedure Check_Empty (Ent : in Ada.Directories.Directory_Entry_Type) is
         Name : constant String := Ada.Directories.Simple_Name (Ent);
      begin
         if Name /= "." and Name /= ".." then
            Log.Warn ("Workspace directory '{0}' is not empty: found '{1}'", Path, Name);
            raise Invalid_Workspace;
         end if;
      end Check_Empty;

      Rules : Porion.Nodes.Services.Rule_Status_Vector;
   begin
      Log.Info ("Setup workspace in {0}", Path);

      if Ada.Directories.Exists (Path) then
         Ada.Directories.Search (Path, "", Process => Check_Empty'Access);
      end if;

      Ada.Directories.Create_Path (Path);
      Porion.Configs.Set (Porion.Configs.WORKSPACE_DIR_NAME, Path);
      Porion.Configs.Set (Porion.Configs.DATABASE_NAME,
                          Porion.Configs.Get_Default_Database_Path);
      declare
         Config_Dir    : constant String := Porion.Configs.Get_Config_Directory;
         Config_Path   : constant String := Porion.Configs.Get_Config_Path;
         Sys_Config    : constant String := Porion.Configs.Get_Sys_Config_Path;
         Key1_Path     : constant String := Util.Files.Compose (Config_Dir, "wallet.key");
         Key2_Path     : constant String := Util.Files.Compose (Config_Dir, "master.key");
         KS_Path       : constant String := Util.Files.Compose (Config_Dir, "porion.akt");
         Key1_Provider : Keystore.Passwords.Keys.Key_Provider_Access;
         Key2_Provider : Keystore.Passwords.Keys.Key_Provider_Access;
         Pass_Provider : Keystore.Passwords.Provider_Access;
         Sec_Gen       : Security.Random.Generator;
      begin
         Ada.Directories.Create_Path (Config_Dir);
         Key1_Provider := Keystore.Passwords.Files.Generate (Key1_Path);
         Key2_Provider := Keystore.Passwords.Files.Generate (Key2_Path);
         Pass_Provider := Keystore.Passwords.Files.Create (Key2_Path);
         Porion.Configs.Set (Porion.Configs.WALLET_KEY_PATH, Key1_Path);
         Porion.Configs.Set (Porion.Configs.PASSWORD_FILE_PATH, Key2_Path);
         Porion.Configs.Set (Porion.Configs.KEYSTORE_PATH, KS_Path);
         Service.Wallet.Set_Master_Key (Key1_Provider.all);
         Keystore.Files.Create (Container => Service.Wallet,
                                Password  => Pass_Provider.all,
                                Path      => KS_Path);

         --  Server setup configuration: load the system wide configuration first.
         if Sys_Config'Length > 0 then
            Porion.Configs.Set ("porion.config", Sys_Config & "," & Config_Path);
         else
            Porion.Configs.Set ("porion.config", Config_Path);
         end if;
         Service.Wallet.Set ("porion.users.auth_key", Sec_Gen.Generate (Bits => 256));
         Free (Key1_Provider);
         Free (Key2_Provider);
         Free (Pass_Provider);
      end;
      Ada.Directories.Create_Path (Porion.Configs.Get_Project_Directory);
      Ada.Directories.Create_Path (Porion.Configs.Get_Rules_Directory);
      Porion.Configs.Save;
      Service.Open (Resource, Schema);

      Log.Info (-("Porion workspace created in {0}"), Path);
      Nodes.Services.Add_Default_Node (Service,
                                       Hostname => "localhost",
                                       Login    => "");
      Nodes.Services.Probe_Node (Service,
                                 "git mvn make cloc lcov gprbuild",
                                 Rules);
   end Setup;

end Porion.Services;
