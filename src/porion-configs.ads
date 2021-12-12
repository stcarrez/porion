-----------------------------------------------------------------------
--  porion-configs -- Configuration
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
with Util.Properties;
package Porion.Configs is

   VERSION   : constant String := "0.1.0";
   RELEASE   : constant String := "Porion " & "0.1.0";
   PREFIX    : constant String := "/build/local-gnat-2021";
   SHARE_DIR : constant String := "/share/porion/";
   RESOURCES : constant String := "/share/porion/resources";

   WORKSPACE_DIR_NAME     : constant String := "workspace_dir";
   PROJECT_DIR_NAME       : constant String := "project_dir";
   RULES_DIR_NAME         : constant String := "rules_dir";
   RULES_SEARCH_PATH_NAME : constant String := "rules_search_path";
   DATABASE_NAME          : constant String := "database";
   DEFAUL_LOG_DIR_NAME    : constant String := "log_dir";

   subtype Config_Type is Util.Properties.Manager;

   --  Initialize the configuration.
   procedure Initialize (Path : in String);

   --  Get the configuration parameter.
   function Get (Name : in String) return String;
   function Get (Name : in String; Default : in String) return String;
   function Get (Name : in String; Default : in Integer) return Integer;

   --  Get a set of configuration parameters.
   function Get_Config (Name : in String) return Config_Type;

   --  Set the configuration parameter.
   procedure Set (Name  : in String;
                  Value : in String);

   --  Returns true if the configuration parameter is defined.
   function Exists (Name : in String) return Boolean;

   --  Save the configuration.
   procedure Save;

   --  Get the share directory path which contains other porion installation files.
   function Get_Share_Directory return String;

   --  Get the porion configuration directory.
   function Get_Config_Directory return String;

   --  Get the porion installation directory.
   function Get_Porion_Directory return String;

   --  Get the directory holding all the projects.
   function Get_Project_Directory return String;

   --  Get the directory holding filtering rules.
   function Get_Rules_Directory return String;

   --  Get the search path to find filtering rules.
   function Get_Rules_Search_Path return String;

   --  Get the default log directory (global).
   function Get_Default_Log_Directory return String;

   --  Get the directory holding the projects.
   function Get_Project_Directory (Name : in String) return String;

   --  Get the directory holding the project sources for the given build.
   function Get_Build_Directory (Name   : in String;
                                 Branch : in String) return String;

   --  Get the directory holding the build log files for the given build.
   function Get_Build_Log_Directory (Name   : in String;
                                     Branch : in String;
                                     Number : in Positive) return String;

   --  Get the directory holding the source checkout log files.
   function Get_Source_Log_Directory (Name   : in String) return String;

   --  Get a working directory.
   function Get_Work_Directory (Name : in String) return String;

   --  Get the default path of the local database.
   function Get_Default_Database_Path return String;

   --  Get the path of the local database.
   function Get_Database_Path return String;

   function Null_Config return Config_Type;

end Porion.Configs;
