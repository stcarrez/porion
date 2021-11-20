-----------------------------------------------------------------------
--  porion-metrics-coverage -- Metric for code coverage using lcov
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
with GNAT.Regpat;
with EL.Contexts.Default;
with Porion.Logs;
package body Porion.Metrics.Coverage is

   function Create (Session : in ADO.Sessions.Master_Session;
                    Params  : in UString) return Controller_Access is
      Result  : constant Coverage_Controller_Access := new Controller_Type;
      Command : constant String := Configs.Get ("command_lcov", LCOV_SUMMARY_COMMAND);
      Ctx     : EL.Contexts.Default.Default_Context;
   begin
      Result.Kind := METRIC_COVERAGE;
      Result.Session := Session;
      Result.Path := Params;
      Result.Command := EL.Expressions.Create_Expression (Command, Ctx);
      return Result.all'Access;
   end Create;

   overriding
   procedure Collect (Controller : in out Controller_Type;
                      Path       : in String;
                      Executor   : in out Porion.Executors.Executor_Type'Class) is
      procedure Process (Line : in String);

      --  The 'lcov --summary file.cov' produces the following output:
      --  Reading tracefile file.cov
      --  Summary coverage rate:
      --    lines......: 71.2% (4571 of 6421 lines)
      --    functions..: 69.6% (514 of 738 functions)
      --    branches...: no data found
      LINE_REGEX : constant String
         := "^ +lines\.+: [0-9]+\.[0-9]+% \(([0-9]+) of ([0-9]) lines\)";
      FUNC_REGEX : constant String
         := "^ +functions\.+: [0-9]+\.[0-9]+% \(([0-9]+) of ([0-9]+) functions\)";

      Line_Pat   : constant GNAT.Regpat.Pattern_Matcher := GNAT.Regpat.Compile (LINE_REGEX);
      Func_Pat   : constant GNAT.Regpat.Pattern_Matcher := GNAT.Regpat.Compile (FUNC_REGEX);

      Line_Covered_Count : Natural := 0;
      Line_Total_Count   : Natural := 0;
      Func_Covered_Count : Natural := 0;
      Func_Total_Count   : Natural := 0;

      procedure Process (Line : in String) is
         Matches : GNAT.Regpat.Match_Array (0 .. 2);
      begin
         Executor.Log (Porion.Logs.LOG_EXECUTION, Line);

         if GNAT.Regpat.Match (Line_Pat, Line) then
            GNAT.Regpat.Match (Line_Pat, Line, Matches);
            Line_Covered_Count := Natural'Value (Line (Matches (1).First .. Matches (1).Last));
            Line_Total_Count := Natural'Value (Line (Matches (2).First .. Matches (2).Last));

         elsif GNAT.Regpat.Match (Func_Pat, Line) then
            GNAT.Regpat.Match (Func_Pat, Line, Matches);
            Func_Covered_Count := Natural'Value (Line (Matches (1).First .. Matches (1).Last));
            Func_Total_Count := Natural'Value (Line (Matches (2).First .. Matches (2).Last));

         end if;

      exception
         when Constraint_Error =>
            null;
      end Process;

      Config : Porion.Configs.Config_Type;
      Result : Integer;
   begin
      Config.Set ("path", Controller.Path);
      Executor.Execute (Controller.Command, Config, Process'Access, Path,
                        Strip_Crlf => True, Status => Result);
      if Result /= 0 then
         return;
      end if;

      if Line_Covered_Count > 0 and Line_Total_Count > 0 then
         Controller.Save_Metric ("lines_total", Line_Total_Count);
         Controller.Save_Metric ("lines_covered", Line_Covered_Count);
      end if;

      if Func_Covered_Count > 0 and Func_Total_Count > 0 then
         Controller.Save_Metric ("func_total", Func_Total_Count);
         Controller.Save_Metric ("func_covered", Func_Covered_Count);
      end if;
   end Collect;

end Porion.Metrics.Coverage;
