-----------------------------------------------------------------------
--  porion-commands-logs -- Logs command to print build logs
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
with Porion.Projects.Services;
with Porion.Services;
with Porion.Configs.Rules;
with Porion.Logs.Analysis;
with Ada.Text_IO;
package body Porion.Commands.Logs is

   package Analysis renames Porion.Logs.Analysis;

   --  ------------------------------
   --  Print build logs.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);

      Levels : Analysis.Level_Map := (Analysis.LOG_ERROR => True,
                                      Analysis.LOG_FATAL => True,
                                      Analysis.LOG_WARNING => True,
                                      others => False);
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Error (-("missing project name"));
         return;
      end if;
      Context.Open;

      Porion.Configs.Rules.Read ("configure.rules");
      Porion.Configs.Rules.Read ("git.rules");
      Porion.Configs.Rules.Read ("gprbuild.rules");
      for I in 1 .. Args.Get_Count loop
         declare
            Path : constant String := Args.Get_Argument (I);
            List : Analysis.Line_Vector;
            Ctx  : Analysis.Analyser_Type;
         begin
            Logs.Analysis.Set_Filter (Ctx, Levels);
            Logs.Analysis.Read (Ctx, Path, List);

            for Line of List loop
                Ada.Text_IO.Put_Line (Line.Content);
            end loop;
         exception
            when Porion.Services.Not_Found =>
               Porion.Commands.Error (-("project '{0}' not found"),
                                      Path);
         end;
      end loop;
   end Execute;

   --  ------------------------------
   --  Setup the command before parsing the arguments and executing it.
   --  ------------------------------
   overriding
   procedure Setup (Command : in out Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Context_Type) is
   begin
      Drivers.Command_Type (Command).Setup (Config, Context);
      GC.Define_Switch (Config, Command.No_Filter'Access,
                        "-n", "--no-filter", -("do not filter build logs"));
   end Setup;

end Porion.Commands.Logs;
