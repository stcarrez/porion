-----------------------------------------------------------------------
--  porion-configs-rules -- Configuration rules
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
with Ada.Exceptions;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Hash;
with EL.Contexts.Default;
with Util.Files;
with Util.Strings;
with Util.Log.Loggers;
package body Porion.Configs.Rules is

   use Ada.Strings.Unbounded;
   use type Logs.Analysis.Level_Type;

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Configs.Rules");

   function Read_Rule (Name : in String) return Rule_Type;

   package Rule_Maps is
      new Ada.Containers.Indefinite_Hashed_Maps (Key_Type     => String,
                                                 Element_Type => Definition_Access,
                                                 Hash         => Ada.Strings.Hash,
                                                 Equivalent_Keys => "=");

   use Rule_Maps;

   Rules : Rule_Maps.Map;

   --  ------------------------------
   --  Returns True if the rule is empty.
   --  ------------------------------
   function Is_Null (Rule : in Rule_Type) return Boolean is
   begin
      return Rule.Def = null;
   end Is_Null;

   function Get_Command (Rule    : in Rule_Type;
                         Name    : in String;
                         Default : in String) return EL.Expressions.Expression is
      Ctx : EL.Contexts.Default.Default_Context;
   begin
      if Rule.Def = null then
         return EL.Expressions.Create_Expression (Default, Ctx);
      else
         declare
            Cmd : constant String := Rule.Def.Config.Get (Name, Default);
         begin
            return EL.Expressions.Create_Expression (Cmd, Ctx);
         end;
      end if;
   end Get_Command;

   function Get_Command (Rule    : in Rule_Type;
                         Name    : in String;
                         Default : in String) return String is
   begin
      if Rule.Def = null then
         return Default;
      else
         return Rule.Def.Config.Get (Name, Default);
      end if;
   end Get_Command;

   function Get_Definition (Name : in String) return Rule_Type is
      Pos : constant Rule_Maps.Cursor := Rules.Find (Name);
   begin
      if not Rule_Maps.Has_Element (Pos) then
         return Read_Rule (Name);
      end if;

      return Rule : Rule_Type do
         Rule.Def := Rule_Maps.Element (Pos);
      end return;
   end Get_Definition;

   --  ------------------------------
   --  Get the name of this rule.
   --  ------------------------------
   function Get_Name (Rule : in Rule_Type) return String is
   begin
      if Rule.Def = null then
         return "";
      else
         return To_String (Rule.Def.Name);
      end if;
   end Get_Name;

   function Read_Rule (Name : in String) return Rule_Type is
      procedure Process_Line (Line : in String);

      Rule        : constant Definition_Access := new Definition_Type;
      Line_Number : Natural := 1;
      Section     : UString;
      Value       : UString;

      procedure Process_Line (Line : in String) is
         Last : Natural;
      begin
         Line_Number := Line_Number + 1;
         if Line'Length = 0 then
            return;
         end if;

         if Line (Line'First) = '[' then
            if Length (Section) > 0 then
               Rule.Config.Set (Section, Value);
               Section := Null_Unbounded_String;
               Value := Null_Unbounded_String;
            end if;

            Last := Util.Strings.Rindex (Line, ']');
            if Last = 0 then
               return;
            end if;

            Section := To_UString (Line (Line'First + 1 .. Last - 1));
            return;
         end if;

         Append (Value, Line);
      end Process_Line;

      Dirs : constant String := Porion.Configs.Get_Rules_Search_Path;
      Path : constant String := Util.Files.Find_File_Path (Name & ".rules", Dirs);
   begin
      Log.Info ("Loading rules {0}", Path);

      Rule.Name := To_UString (Name);
      if Ada.Directories.Exists (Path) then
         Util.Files.Read_File (Path, Process_Line'Access);
      end if;

      Rules.Insert (Name, Rule);

      return Result : Rule_Type do
         Result.Def := Rule;
      end return;
   end Read_Rule;

   --  ------------------------------
   --  Read the rule configuration file.
   --  ------------------------------
   procedure Read (Path    : in String;
                   Process : not null
                      access procedure (Line : in String;
                                        Level : in Logs.Analysis.Level_Type)) is
      procedure Process_Line (Line : in String);

      Line_Number   : Natural := 1;
      Current_Level : Logs.Analysis.Level_Type := Logs.Analysis.LOG_UNKNOWN;

      procedure Process_Line (Line : in String) is
      begin
         Line_Number := Line_Number + 1;
         if Line'Length = 0 then
            return;
         end if;

         if Line (Line'First) = '[' then
            if Line = "[log-ignore]" then
               Current_Level := Logs.Analysis.LOG_INFO;
               return;
            elsif Line = "[log-error]" then
               Current_Level := Logs.Analysis.LOG_ERROR;
               return;
            elsif Line = "[log-warning]" then
               Current_Level := Logs.Analysis.LOG_WARNING;
               return;
            elsif Line = "[log-context]" then
               Current_Level := Logs.Analysis.LOG_CONTEXT;
               return;
            elsif Line = "[log-info]" then
               Current_Level := Logs.Analysis.LOG_INFO;
               return;
            elsif Line = "[log-trace]" then
               Current_Level := Logs.Analysis.LOG_TRACE;
               return;
            else
               Current_Level := Logs.Analysis.LOG_UNKNOWN;
               return;
            end if;
         end if;

         if Current_Level /= Logs.Analysis.LOG_UNKNOWN then
            Process (Line, Current_Level);
         end if;

      exception
         when E : others =>
            Log.Error ("{0}:{1}: invalid pattern: {2}",
                       Path, Util.Strings.Image (Line_Number),
                       Ada.Exceptions.Exception_Message (E));
      end Process_Line;

   begin
      Log.Info ("Loading rules {0}", Path);
      Util.Files.Read_File (Path, Process_Line'Access);
   end Read;

   --  ------------------------------
   --  Find the rule configuration file and read it.
   --  ------------------------------
   procedure Read_Rule (Name    : in String;
                        Process : not null
                           access procedure (Line : in String;
                                             Level : in Logs.Analysis.Level_Type)) is
      Dirs : constant String := Porion.Configs.Get_Rules_Search_Path;
      Path : constant String := Util.Files.Find_File_Path (Name & ".rules", Dirs);
   begin
      if Ada.Directories.Exists (Path) then
         Read (Path, Process);
      else
         Log.Warn ("Skipping rule '{0}'' not found", Name);
      end if;
   end Read_Rule;

end Porion.Configs.Rules;
