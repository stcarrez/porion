-----------------------------------------------------------------------
--  akt-configs -- Configuration
--  Copyright (C) 2019, 2021 Stephane Carrez
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
with Ada.Environment_Variables;
with Ada.Directories;
with Ada.Strings.Unbounded;
with Interfaces.C.Strings;
with Util.Files;
with Util.Strings;
with Util.Log.Loggers;
with Util.Systems.Os;
package body Porion.Configs is

   use Ada.Strings.Unbounded;

   --  The logger
   Log   : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Configs");

   function Get_Default_Path return String;

   Cfg      : Util.Properties.Manager;
   Cfg_Path : Ada.Strings.Unbounded.Unbounded_String;

   --  ------------------------------
   --  Get the default configuration path.
   --  ------------------------------
   function Get_Default_Path return String is
      Home     : constant String := Ada.Environment_Variables.Value ("HOME");
      Def_Path : constant String := Util.Files.Compose (Home, ".config/porion/porion.properties");
   begin
      return Def_Path;
   end Get_Default_Path;

   --  ------------------------------
   --  Initialize the configuration.
   --  ------------------------------
   procedure Initialize (Path : in String) is
      Def_Path : constant String := Get_Default_Path;
   begin
      if Path'Length > 0 and then Ada.Directories.Exists (Path) then
         Log.Info ("Loading configuration {0}", Path);

         Cfg.Load_Properties (Path);
         Cfg_Path := Ada.Strings.Unbounded.To_Unbounded_String (Path);
      elsif Ada.Directories.Exists (Def_Path) then
         Log.Info ("Loading user global configuration {0}", Def_Path);

         Cfg.Load_Properties (Def_Path);
         Cfg_Path := Ada.Strings.Unbounded.To_Unbounded_String (Def_Path);
      end if;

      if Path'Length > 0 then
         Cfg_Path := Ada.Strings.Unbounded.To_Unbounded_String (Path);
      end if;
   end Initialize;

   --  ------------------------------
   --  Save the configuration.
   --  ------------------------------
   procedure Save is
      Path : constant String
        := (if Length (Cfg_Path) = 0 then Get_Default_Path else To_String (Cfg_Path));
      Dir  : constant String := Ada.Directories.Containing_Directory (Path);
      P    : Interfaces.C.Strings.chars_ptr;
   begin
      Log.Info ("Saving configuration {0}", Path);

      if not Ada.Directories.Exists (Path) then
         Ada.Directories.Create_Path (Dir);
         P := Interfaces.C.Strings.New_String (Dir);
         if Util.Systems.Os.Sys_Chmod (P, 8#0700#) /= 0 then
            Log.Error (-("cannot set the permission of {0}"), Dir);
         end if;
         Interfaces.C.Strings.Free (P);
      end if;
      Cfg.Save_Properties (Path);

      --  Set the permission on the file to allow only the user to read/write that file.
      P := Interfaces.C.Strings.New_String (Path);
      if Util.Systems.Os.Sys_Chmod (P, 8#0600#) /= 0 then
         Log.Error (-("cannot set the permission of {0}"), Path);
      end if;
      Interfaces.C.Strings.Free (P);
   end Save;

   --  ------------------------------
   --  Get the configuration parameter.
   --  ------------------------------
   function Get (Name : in String) return String is
   begin
      return Cfg.Get (Name);
   end Get;

   function Get (Name : in String; Default : in String) return String is
   begin
      return Cfg.Get (Name, Default);
   end Get;

   --  ------------------------------
   --  Get a set of configuration parameters.
   --  ------------------------------
   function Get_Config (Name : in String) return Config_Type is
   begin
      if not Cfg.Exists (Name) then
         return Null_Config;
      else
         return Cfg.Get (Name);
      end if;
   end Get_Config;

   --  ------------------------------
   --  Set the configuration parameter.
   --  ------------------------------
   procedure Set (Name  : in String;
                  Value : in String) is
   begin
      Cfg.Set (Name, Value);
   end Set;

   --  ------------------------------
   --  Returns true if the configuration parameter is defined.
   --  ------------------------------
   function Exists (Name : in String) return Boolean is
   begin
      return Cfg.Exists (Name);
   end Exists;

   --  ------------------------------
   --  Get the porion installation directory.
   --  ------------------------------
   function Get_Porion_Directory return String is
   begin
      if Exists (WORKSPACE_DIR_NAME) then
         return Get (WORKSPACE_DIR_NAME);
      else
         return PREFIX;
      end if;
   end Get_Porion_Directory;

   --  ------------------------------
   --  Get the directory holding the projects.
   --  ------------------------------
   function Get_Project_Directory (Name : in String) return String is
   begin
      if Exists (PROJECT_DIR_NAME) then
         return Util.Files.Compose (Get (PROJECT_DIR_NAME), Name);
      else
         return Util.Files.Compose (Get_Porion_Directory, Name);
      end if;
   end Get_Project_Directory;

   --  ------------------------------
   --  Get the directory holding the project sources for the given build.
   --  ------------------------------
   function Get_Build_Directory (Name   : in String;
                                 Branch : in String;
                                 Number : in Positive) return String is
      pragma Unreferenced (Number);

      Project_Dir : constant String := Get_Project_Directory (Name);
   begin
      return Util.Files.Compose (Project_Dir, Branch);
   end Get_Build_Directory;

   --  ------------------------------
   --  Get the directory holding the build log files for the given build.
   --  ------------------------------
   function Get_Build_Log_Directory (Name   : in String;
                                     Branch : in String;
                                     Number : in Positive) return String is
      Project_Dir : constant String := Get_Project_Directory (Name);
      Build_Id    : constant String := Util.Strings.Image (Number);
      Log_Dir     : constant String := Util.Files.Compose ("builds", Branch & "-" & Build_Id);
   begin
      return Util.Files.Compose (Project_Dir, Log_Dir);
   end Get_Build_Log_Directory;

   --  ------------------------------
   --  Get the directory holding the source checkout log files.
   --  ------------------------------
   function Get_Source_Log_Directory (Name   : in String;
                                      Branch : in String) return String is
      Project_Dir : constant String := Get_Project_Directory (Name);
      Log_Dir     : constant String := Util.Files.Compose ("scm", Branch);
   begin
      return Util.Files.Compose (Project_Dir, Log_Dir);
   end Get_Source_Log_Directory;

   --  ------------------------------
   --  Get the path of the local database.
   --  ------------------------------
   function Get_Database_Path return String is
   begin
      if Exists (DATABASE_NAME) then
         return Get (DATABASE_NAME);
      else
         return "sqlite:///" & Util.Files.Compose (Get_Porion_Directory, "porion.db");
      end if;
   end Get_Database_Path;

   function Null_Config return Config_Type is
   begin
      return Empty : Config_Type do null; end return;
   end Null_Config;

end Porion.Configs;
