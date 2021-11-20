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
with Util.Files;
with Util.Strings;
with Util.Log.Loggers;
package body Porion.Configs.Rules is

   use type Logs.Analysis.Level_Type;

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Configs.Rules");

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
