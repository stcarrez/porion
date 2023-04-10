-----------------------------------------------------------------------
--  porion-projects -- Project information
--  Copyright (C) 2021, 2023 Stephane Carrez
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
with Ada.Strings.Maps;
package body Porion.Projects is

   Log     : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Projects");

   Name_Forbidden_Set : constant Ada.Strings.Maps.Character_Set
      := Ada.Strings.Maps.To_Set ("@~#");

   --  ------------------------------
   --  Parse an identification string with the format:
   --   <project>[#<branch>][~<recipe>][@<node][:<build>]
   --  The following format is also recognized for URL compatibility and there must
   --  be at least one `recipe`, `node` or `build-number` component:
   --   <project>:<branch>{[~<recipe>][@<node][:<build-number>]}
   --  Raises the Invalid_Ident exception if the format is invalid.
   --  ------------------------------
   function Parse (Ident : in String) return Ident_Type is
      Result    : Ident_Type;
      Caret_Pos : Natural;
      Tilde_Pos : Natural;
      At_Pos    : Natural;
      Colon_Pos : Natural;
      Last      : Natural;
   begin
      Colon_Pos := Util.Strings.Index (Ident, ':');
      Caret_Pos := Util.Strings.Index (Ident, '#');
      Tilde_Pos := Util.Strings.Index (Ident, '~');
      At_Pos := Util.Strings.Index (Ident, '@');

      --  Look for the <project>:<branch>{...} form and treat the first ':'
      --  as the '#' branch separator.
      if Colon_Pos > 0 and then Caret_Pos = 0 then
         Last := Util.Strings.Index (Ident, ':', Colon_Pos + 1);
         if Last > 0 or else Tilde_Pos > Colon_Pos or else At_Pos > Colon_Pos then
            Caret_Pos := Colon_Pos;
            Colon_Pos := Last;
         end if;
      end if;

      if Colon_Pos > 0 then
         Last := Colon_Pos - 1;
         begin
            Result.Build := Positive'Value (Ident (Colon_Pos + 1 .. Ident'Last));

         exception
            when Constraint_Error =>
            raise Invalid_Ident;
         end;
      else
         Last := Ident'Last;
      end if;
      if Caret_Pos > 0 then
         Result.Name := To_UString (Ident (Ident'First .. Caret_Pos - 1));
         if Tilde_Pos = 0 and At_Pos = 0 then
            Result.Branch := To_UString (Ident (Caret_Pos + 1 .. Last));

         elsif Tilde_Pos = 0 and At_Pos > Caret_Pos + 1 then
            Result.Branch := To_UString (Ident (Caret_Pos + 1 .. At_Pos - 1));
            Result.Node := To_UString (Ident (At_Pos + 1 .. Last));

         elsif At_Pos = 0 and Tilde_Pos > Caret_Pos + 1 then
            Result.Branch := To_UString (Ident (Caret_Pos + 1 .. Tilde_Pos - 1));
            Result.Recipe := To_UString (Ident (Tilde_Pos + 1 .. Last));

         elsif Tilde_Pos > Caret_Pos + 1 and At_Pos > Tilde_Pos + 1 then
            Result.Branch := To_UString (Ident (Caret_Pos + 1 .. Tilde_Pos - 1));
            Result.Recipe := To_UString (Ident (Tilde_Pos + 1 .. At_Pos - 1));
            Result.Node := To_UString (Ident (At_Pos + 1 .. Last));
         else
            raise Invalid_Ident;
         end if;

      elsif Tilde_Pos > 0 then
         Result.Name := To_UString (Ident (Ident'First .. Tilde_Pos - 1));
         if At_Pos = 0 then
            Result.Recipe := To_UString (Ident (Tilde_Pos + 1 .. Last));
         elsif At_Pos > Tilde_Pos + 1 then
            Result.Recipe := To_UString (Ident (Tilde_Pos + 1 .. At_Pos - 1));
            Result.Node := To_UString (Ident (At_Pos + 1 .. Last));
         else
            raise Invalid_Ident;
         end if;

      elsif At_Pos > 0 then
         Result.Name := To_UString (Ident (Ident'First .. At_Pos - 1));
         Result.Node := To_UString (Ident (At_Pos + 1 .. Last));

      else
         Result.Name := To_UString (Ident (Ident'First .. Last));
      end if;

      if Length (Result.Name) = 0 then
         raise Invalid_Ident;
      end if;
      return Result;
   end Parse;

   --  ------------------------------
   --  Get a printable representation of the split identification string.
   --  ------------------------------
   function To_String (Ident : in Ident_Type) return String is
      use Ada.Strings.Unbounded;

      Result : UString;
   begin
      Append (Result, Ident.Name);
      if Length (Ident.Branch) > 0 then
         Append (Result, "#");
         Append (Result, Ident.Branch);
      end if;

      if Length (Ident.Recipe) > 0 then
         Append (Result, "~");
         Append (Result, Ident.Recipe);
      end if;

      if Length (Ident.Node) > 0 then
         Append (Result, "@");
         Append (Result, Ident.Node);
      end if;

      if Ident.Build > 0 then
         Append (Result, ":");
         Append (Result, Util.Strings.Image (Ident.Build));
      end if;

      return To_String (Result);
   end To_String;

   --  ------------------------------
   --  Returns true if the name can be used for a recipe name.
   --  ------------------------------
   function Is_Valid_Recipe (Name : in String) return Boolean is
   begin
      return (for all C of Name => not Ada.Strings.Maps.Is_In (C, Name_Forbidden_Set));
   end Is_Valid_Recipe;

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
