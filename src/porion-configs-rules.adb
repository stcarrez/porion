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
with Util.Files;
with Porion.Logs.Analysis;
package body Porion.Configs.Rules is

   use type Logs.Analysis.Level_Type;

   --  Read the rule configuration file.
   procedure Read (Path : in String) is
      procedure Process (Line : in String);

      Current_Level : Logs.Analysis.Level_Type := Logs.Analysis.LOG_UNKNOWN;

      procedure Process (Line : in String) is
      begin
         if Line'Length = 0 then
            return;
         end if;

         if Line (Line'First) = '[' then
            if Line = "[log-ignore]" then
               Current_Level := Logs.Analysis.LOG_INFO;
               return;
            else
               Current_Level := Logs.Analysis.LOG_UNKNOWN;
               return;
            end if;
         end if;

         if Current_Level /= Logs.Analysis.LOG_UNKNOWN then
            Logs.Analysis.Add_Rule (Line, Current_Level);
         end if;
      end Process;

   begin
      Util.Files.Read_File (Path, Process'Access);
   end Read;

end Porion.Configs.Rules;
