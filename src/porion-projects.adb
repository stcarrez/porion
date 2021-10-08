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
with Util.Log.Loggers;
with Util.Files;
with Util.Strings;
package body Porion.Projects is

   Log     : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Projects");

   --  ------------------------------
   --  Parse an identification string with the format:
   --   <project>[^<branch>][~<recipe>][@<node]
   --  Raises the Invalid_Ident exception if the format is invalid.
   --  ------------------------------
   function Parse (Ident : in String) return Ident_Type is
      Result    : Ident_Type;
      Caret_Pos : Natural;
      Tilde_Pos : Natural;
      At_Pos    : Natural;
   begin
      Caret_Pos := Util.Strings.Index (Ident, '^');
      Tilde_Pos := Util.Strings.Index (Ident, '~');
      At_Pos := Util.Strings.Index (Ident, '@');
      if Caret_Pos > 0 then
         Result.Name := To_UString (Ident (Ident'First .. Caret_Pos - 1));
         if Tilde_Pos = 0 and At_Pos = 0 then
            Result.Branch := To_UString (Ident (Caret_Pos + 1 .. Ident'Last));

         elsif Tilde_Pos = 0 and At_Pos > Caret_Pos + 1 then
            Result.Branch := To_UString (Ident (Caret_Pos + 1 .. At_Pos - 1));
            Result.Node := To_UString (Ident (At_Pos + 1 .. Ident'Last));

         elsif At_Pos = 0 and Tilde_Pos > Caret_Pos + 1 then
            Result.Branch := To_UString (Ident (Caret_Pos + 1 .. Tilde_Pos - 1));
            Result.Recipe := To_UString (Ident (Tilde_Pos + 1 .. Ident'Last));

         elsif Tilde_Pos > Caret_Pos + 1 and At_Pos > Tilde_Pos + 1 then
            Result.Branch := To_UString (Ident (Caret_Pos + 1 .. Tilde_Pos - 1));
            Result.Recipe := To_UString (Ident (Tilde_Pos + 1 .. At_Pos - 1));
            Result.Node := To_UString (Ident (At_Pos + 1 .. Ident'Last));
         else
            raise Invalid_Ident;
         end if;

      elsif Tilde_Pos > 0 then
         Result.Name := To_UString (Ident (Ident'First .. Tilde_Pos - 1));
         if At_Pos = 0 then
            Result.Recipe := To_UString (Ident (Tilde_Pos + 1 .. Ident'Last));
         elsif At_Pos > Tilde_Pos + 1 then
            Result.Recipe := To_UString (Ident (Tilde_Pos + 1 .. At_Pos - 1));
            Result.Node := To_UString (Ident (At_Pos + 1 .. Ident'Last));
         else
            raise Invalid_Ident;
         end if;

      elsif At_Pos > 0 then
         Result.Name := To_UString (Ident (Ident'First .. At_Pos - 1));
         Result.Node := To_UString (Ident (At_Pos + 1 .. Ident'Last));

      else
         Result.Name := To_UString (Ident);
      end if;

      return Result;
   end Parse;

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
