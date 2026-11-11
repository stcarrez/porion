-----------------------------------------------------------------------
--  porion-logs-analysis -- Log analysis
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
with Util.Files;
with Util.Strings.Tokenizers;
with Porion.Configs.Rules;
package body Porion.Logs.Analysis is

   --  ------------------------------
   --  Analyze the log line according to the current context and the log rules.
   --  ------------------------------
   procedure Analyse (Context : in out Analyser_Type;
                      Line    : in String;
                      Result  : out Line_Info_Type) is
   begin
      Context.Count := Context.Count + 1;
      for Rule of Context.Rules loop
         if GNAT.Regpat.Match (Rule.Pattern, Line) then
            Result := Rule.Kind;
            if not Result.Drop and not Context.Levels (Result.Level) then
               Result.Drop := True;
            end if;
            return;
         end if;
      end loop;
      Result.Drop := False;
      if Line'Length = 0 then
         Result.Level := LOG_DEBUG;
         if not Context.Levels (LOG_DEBUG) then
            Result.Drop := True;
         end if;
      else
         Result.Level := LOG_UNKNOWN;
      end if;
   end Analyse;

   --  ------------------------------
   --  Read the log file and apply the analysis rules to collect the interesting content.
   --  ------------------------------
   procedure Read (Context : in out Analyser_Type;
                   Path    : in String;
                   Result  : in out Line_Vector) is
      procedure Analyze (Level : in Level_Type; Line : in String);
      procedure Process (Line : in String);

      Line_Num : Natural := 0;
      Step     : ADO.Identifier := ADO.NO_IDENTIFIER;

      procedure Analyze (Level : in Level_Type; Line : in String) is
         State : Line_Info_Type;
      begin
         Analyse (Context, Line, State);
         if not State.Drop then
            if State.Level = LOG_UNKNOWN and then Level /= LOG_INFO then
               State.Level := Level;
            end if;
            Result.Append (Line_Type'(Length  => Line'Length,
                                      Number  => Line_Num,
                                      Level   => State.Level,
                                      Step    => Step,
                                      Context => False,
                                      Content => Line));
         end if;
      end Analyze;

      procedure Process (Line : in String) is
      begin
         Line_Num := Line_Num + 1;
         if Line'Length > 10 and then Util.Strings.Starts_With (Line, "porion:") then
            if Util.Strings.Starts_With (Line, "porion:step:") then
               Step := ADO.Identifier'Value (Line (Line'First + 13 .. Line'Last));
               return;
            end if;
            if Util.Strings.Starts_With (Line, "porion:error: ") then
               Analyze (LOG_ERROR, Line (Line'First + 14 .. Line'Last));
               return;
            end if;
            if Context.Levels (LOG_PORION) then
               Result.Append (Line_Type'(Length  => Line'Length,
                                         Number  => Line_Num,
                                         Level   => LOG_PORION,
                                         Step    => Step,
                                         Context => False,
                                         Content => Line));
            end if;
            return;
         end if;

         Analyze (LOG_INFO, Line);
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
   --  Set the filtering rules that must be applied when analysing the logs.
   --  ------------------------------
   procedure Set_Rules (Context : in out Analyser_Type;
                        Rules   : in String) is

      procedure Process (Line  : in String;
                         Level : in Level_Type);
      procedure Read_Rules (Token : in String;
                            Done  : out Boolean);

      procedure Process (Line  : in String;
                         Level : in Level_Type) is
         Match : constant GNAT.Regpat.Pattern_Matcher
           := GNAT.Regpat.Compile (Line, GNAT.Regpat.Single_Line);
      begin
         Context.Rules.Append (Rule_Matcher'(Size    => Match.Size,
                                             Pattern => Match,
                                             Kind    => (Level, False)));
      end Process;

      procedure Read_Rules (Token : in String;
                            Done  : out Boolean) is
      begin
         Done := False;
         if Token'Length > 0 then
            Porion.Configs.Rules.Read_Rule (Token, Process'Access);
         end if;
      end Read_Rules;

   begin
      Util.Strings.Tokenizers.Iterate_Tokens (Content => Rules,
                                              Pattern => " ",
                                              Process => Read_Rules'Access);
   end Set_Rules;

end Porion.Logs.Analysis;
