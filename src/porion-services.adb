-----------------------------------------------------------------------
--  porion-services -- Project information
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

with Util.Log.Loggers;
with Util.Properties;

with ADO.Configs;
with ADO.Sqlite;
with ADO.SQL;

with Porion.Configs;
with Porion.Resources;
with Porion.Services.Parsers;
with Porion.Builds.Services;
with Porion.Projects.Services;
package body Porion.Services is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Services");

   --function Get_Query_Resource (Name : in String) return access constant String is
   --begin
   --   Log.Info ("Get query resource {0}", Name);

   --   return Porion.Resources.Get_Content (Name);
   --end Get_Query_Resource;

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
         raise Not_Found;
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
         raise Not_Found;
      end if;

   end Load_Node;

   function Create_Query (Service : in out Context_Type;
                          Query   : in ADO.Queries.Context)
                          return Ado.Statements.Query_Statement is
   begin
      return Service.DB.Create_Statement (Query);
   end Create_Query;

   function Get_Database (Service : in Context_Type) return ADO.Sessions.Master_Session is
   begin
      return Service.DB;
   end Get_Database;

   procedure Open (Service  : in out Context_Type;
                   Resource : in Resources.Get_Resource_Access;
                   Schema   : in Resources.Content_Access) is
      use type Resources.Content_Access;

      Create : constant Boolean := Schema /= null;
      Path   : constant String := Porion.Configs.Get_Database_Path
        & (if Create then "?create=true" else "");
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
   end Open;

   procedure Import (Service : in out Context_Type;
                     Path    : in String) is
      Content : Porion.Services.Parsers.Parser_Type;
   begin
      Porion.Services.Parsers.Parse (Service, Path, Content);

      declare
         Project_Service : Porion.Projects.Services.Context_Type;
         Build_Service   : Porion.Builds.Services.Context_Type;
      begin
         Project_Service.Open (Service);

         Project_Service.Update (Content.Project);

         Build_Service.Open (Project_Service);
         Build_Service.Update (Content.Build_Configs);
      end;
   end Import;

end Porion.Services;
