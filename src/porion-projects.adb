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

with Porion.Configs;
with Ada.Directories;
with Util.Log.Loggers;
with Util.Files;
package body Porion.Projects is

   Log     : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Projects");

   --  Load the project description.
   procedure Load_Project (Name    : in String;
                           Project : in out Project_Type) is
      Path        : constant String := Porion.Configs.Get_Project_Directory (Name);
      Config_Path : constant String := Util.Files.Compose (Path, "project.conf");
   begin
      Log.Info ("Loading project {0} from {1}", Name, Config_Path);

      Project.Name := To_UString (Name);
      Project.Path := To_UString (Path);
      if not Ada.Directories.Exists (Config_Path) then
         return;
      end if;
   end Load_Project;

end Porion.Projects;
