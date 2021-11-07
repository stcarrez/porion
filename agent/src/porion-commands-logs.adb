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
with PT.Texts;
package body Porion.Commands.Logs is

   package Analysis renames Porion.Logs.Analysis;

   use type Analysis.Level_Type;

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

      Printer : PT.Texts.Printer_Type := PT.Texts.Create (Context.Printer.all);
      Fields  : PT.Texts.Field_Array (1 .. 2);
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Error (-("missing project name"));
         return;
      end if;
      Context.Open;

      Printer.Create_Field (Fields (1), Context.Styles.Default, 0.0);
      Printer.Create_Field (Fields (2), Context.Styles.Success, 90.0);
      Printer.Set_Bottom_Right_Padding (Fields (1), (1, 0));
      Printer.Set_Max_Dimension (Fields (1), (4, 0));
      Printer.Layout_Fields (Fields (1 .. 2));

      if Command.No_Filter then
         Levels := (others => True);
      end if;

      Porion.Configs.Rules.Read ("configure.rules");
      Porion.Configs.Rules.Read ("git.rules");
      Porion.Configs.Rules.Read ("gprbuild.rules");
      Porion.Configs.Rules.Read ("make.rules");
      for I in 1 .. Args.Get_Count loop
         declare
            Path : constant String := Args.Get_Argument (I);
            List : Analysis.Line_Vector;
            Ctx  : Analysis.Analyser_Type;
         begin
            Logs.Analysis.Set_Filter (Ctx, Levels);
            Logs.Analysis.Read (Ctx, Path, List);

            for Line of List loop
               if Line.Level = Analysis.LOG_ERROR then
                  Printer.Set_Style (Fields (1), Context.Styles.Error);
                  Printer.Set_Style (Fields (2), Context.Styles.Error);
               elsif Line.Level = Analysis.LOG_WARNING then
                  Printer.Set_Style (Fields (1), Context.Styles.Warning);
                  Printer.Set_Style (Fields (2), Context.Styles.Warning);
               elsif Line.Level = Analysis.LOG_INFO then
                  Printer.Set_Style (Fields (1), Context.Styles.Info);
                  Printer.Set_Style (Fields (2), Context.Styles.Info);
               else
                  Printer.Set_Style (Fields (1), Context.Styles.Default);
                  Printer.Set_Style (Fields (2), Context.Styles.Default);
               end if;
               Printer.Put_Int (Fields (1), Line.Number);
               Printer.Put (Fields (2), Line.Content);
               Printer.New_Line;
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
