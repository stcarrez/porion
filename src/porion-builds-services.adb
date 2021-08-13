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
with Util.Log.Loggers;
with Util.Strings;
with Util.Properties;
with Porion.Configs;
with Porion.Loggers;
with ADO.Configs;
with ADO.Sqlite;
with ADO.SQL;
with Porion.Builders.Scripts;
package body Porion.Builds.Services is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builds.Services");

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

      --  Add_Branch (Service, Branch_Name, Branch);

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
      --   if Service.Project.Is_Null then
      --   raise Name_Used;
      --  end if;

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

   function Get_Build (Service : in Context_Type) return Porion.Builds.Models.Build_Ref is
   begin
      return Service.Build;
   end Get_Build;

end Porion.Builds.Services;
