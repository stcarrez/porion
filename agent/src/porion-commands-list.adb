-----------------------------------------------------------------------
--  porion-commands-list -- List command
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

with Porion.Reports;
package body Porion.Commands.List is

   --  Report the list of projects, nodes or builds.
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name, Args);
   begin
      Context.Open;

      if not Command.List_Projects and not Command.List_Nodes and not Command.List_Builds
        and not Command.List_Queues and not Command.List_Env
      then
         Command.List_Projects := True;
      end if;

      if Command.List_Projects then
         Porion.Reports.List_Projects (Service => Context.Project_Service,
                                       Printer => Context.Printer.all,
                                       Styles  => Context.Styles);
      end if;

      if Command.List_Nodes then
         Porion.Reports.List_Nodes (Service => Context.Project_Service,
                                    Printer => Context.Printer.all,
                                    Styles  => Context.Styles);
      end if;

      if Command.List_Builds then
         Porion.Reports.List_Builds (Service => Context.Project_Service,
                                     Printer => Context.Printer.all,
                                     Styles  => Context.Styles);
      end if;

      if Command.List_Queues then
         Porion.Reports.List_Queues (Service => Context.Project_Service,
                                     Printer => Context.Printer.all,
                                     Styles  => Context.Styles);
      end if;

      if Command.List_Env then
         Porion.Reports.List_Environment (Service => Context.Project_Service,
                                          Printer => Context.Printer.all,
                                          Styles  => Context.Styles);
      end if;
   end Execute;

   --  Setup the command before parsing the arguments and executing it.
   overriding
   procedure Setup (Command : in out Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Context_Type) is
   begin
      Drivers.Command_Type (Command).Setup (Config, Context);
      GC.Define_Switch (Config => Config,
                        Output => Command.List_Projects'Access,
                        Switch => "-p",
                        Long_Switch => "--projects",
                        Help => -("List the projects"));
      GC.Define_Switch (Config => Config,
                        Output => Command.List_Nodes'Access,
                        Switch => "-n",
                        Long_Switch => "--nodes",
                        Help => -("List the build nodes"));
      GC.Define_Switch (Config => Config,
                        Output => Command.List_Builds'Access,
                        Switch => "-b",
                        Long_Switch => "--builds",
                        Help => -("List the builds"));
      GC.Define_Switch (Config => Config,
                        Output => Command.List_Queues'Access,
                        Switch => "-Q",
                        Long_Switch => "--queue",
                        Help => -("List the content of build queue"));
      GC.Define_Switch (Config => Config,
                        Output => Command.List_Env'Access,
                        Switch => "-E",
                        Long_Switch => "--env",
                        Help => -("List the environment variables"));
   end Setup;

end Porion.Commands.List;
