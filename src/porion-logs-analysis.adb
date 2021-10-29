-----------------------------------------------------------------------
--  porion-logs-analysis -- Log analysis
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
with Util.Files;
with Util.Strings;
with GNAT.Regpat;
package body Porion.Logs.Analysis is

   type Rule_Matcher (Size : GNAT.Regpat.Program_Size) is record
      Pattern : GNAT.Regpat.Pattern_Matcher (Size);
      Kind    : Line_Info_Type;
   end record;

   package Match_Vectors is
      new Ada.Containers.Indefinite_Vectors (Index_Type   => Positive,
                                             Element_Type => Rule_Matcher,
                                             "="          => "=");

   subtype Match_Vector is Match_Vectors.Vector;

   Rules : Match_Vector;

   --  ------------------------------
   --  Analyze the log line according to the current context and the log rules.
   --  ------------------------------
   procedure Analyse (Context : in out Analyser_Type;
                      Line    : in String;
                      Result  : out Line_Info_Type) is
   begin
      Context.Count := Context.Count + 1;
      for Rule of Rules loop
         if GNAT.Regpat.Match (Rule.Pattern, Line) then
            Result := Rule.Kind;
            if not Result.Drop and not Context.Levels (Result.Level) then
               Result.Drop := True;
            end if;
            return;
         end if;
      end loop;
      Result.Level := LOG_UNKNOWN;
      Result.Drop := False;
   end Analyse;

   --  ------------------------------
   --  Read the log file and apply the analysis rules to collect the interesting content.
   --  ------------------------------
   procedure Read (Context : in out Analyser_Type;
                   Path    : in String;
                   Result  : in out Line_Vector) is
      procedure Process (Line : in String);

      Line_Num : Natural := 0;

      procedure Process (Line : in String) is
         State : Line_Info_Type;
      begin
         Line_Num := Line_Num + 1;
         if Line'Length > 10 and then Util.Strings.Starts_With (Line, "porion:") then
            if Context.Levels (LOG_PORION) then
               Result.Append ((Length  => Line'Length,
                               Number  => Line_Num,
                               Level   => LOG_PORION,
                               Context => False,
                               Content => Line));
            end if;
            return;
         end if;

         Analyse (Context, Line, State);
         if not State.Drop then
            Result.Append ((Length  => Line'Length,
                            Number  => Line_Num,
                            Level   => State.Level,
                            Context => False,
                            Content => Line));
         end if;
      end Process;

   begin
      Util.Files.Read_File (Path, Process'Access);
   end Read;

   --  ------------------------------
   --  Configure the levels which are accepted by the Read procedure.
   --  ------------------------------
   procedure Set_Filter (Context : in out Analyser_Type;
                         Levels  : in Level_Map) is
   begin
      Context.Levels := Levels;
   end Set_Filter;

   --  ------------------------------
   --  Add a log analysis rule.
   --  ------------------------------
   procedure Add_Rule (Line  : in String;
                       Level : in Level_Type) is
      Match : constant GNAT.Regpat.Pattern_Matcher := GNAT.Regpat.Compile (Line);
   begin
      Rules.Append ((Size => Match.Size, Pattern => Match, Kind => (Level, False)));
   end Add_Rule;

end Porion.Logs.Analysis;
