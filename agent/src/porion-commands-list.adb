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
with Porion.Services;
package body Porion.Commands.List is

   --  The maximum number of entries displayed in a list unless --all is used.
   MAX_LIST_COUNT : constant Natural := 100;

   --  Report the list of projects, nodes or builds.  When a project name is given
   --  as argument, the builds, nodes and queues are filtered by that project.
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);

      --  Limit the number of entries unless --all is given (0 means no limit).
      Max_Count : constant Natural := (if Command.List_All then 0 else MAX_LIST_COUNT);
   begin
      if Args.Get_Count > 1 then
         Porion.Commands.Error (-("too many arguments"));
         return;
      end if;
      Context.Open;

      if Args.Get_Count = 1 then
         declare
            Project_Name : constant String := Args.Get_Argument (1);
         begin
            Context.Project_Service.Load_Project (Project_Name);
         exception
            when Porion.Services.Not_Found =>
               Porion.Commands.Error (-("project '{0}' not found"), Project_Name);
               return;
         end;
      end if;

      if not Command.List_Projects and not Command.List_Nodes and not Command.List_Builds
        and not Command.List_Queues and not Command.List_Env
      then
         Command.List_Projects := True;
      end if;

      if Command.List_Projects then
         Porion.Reports.List_Projects (Service   => Context.Project_Service,
                                       Printer   => Context.Printer.all,
                                       Styles    => Context.Styles,
                                       Max_Count => Max_Count);
      end if;

      if Command.List_Nodes then
         Porion.Reports.List_Nodes (Service   => Context.Project_Service,
                                    Printer   => Context.Printer.all,
                                    Styles    => Context.Styles,
                                    Max_Count => Max_Count);
      end if;

      if Command.List_Builds then
         Porion.Reports.List_Builds (Service   => Context.Project_Service,
                                     Printer   => Context.Printer.all,
                                     Styles    => Context.Styles,
                                     Max_Count => Max_Count);
      end if;

      if Command.List_Queues then
         Porion.Reports.List_Queues (Service   => Context.Project_Service,
                                     Printer   => Context.Printer.all,
                                     Styles    => Context.Styles,
                                     Max_Count => Max_Count);
      end if;

      if Command.List_Env then
         Porion.Reports.List_Environment (Service   => Context.Project_Service,
                                          Printer   => Context.Printer.all,
                                          Styles    => Context.Styles,
                                          Max_Count => Max_Count);
      end if;
   end Execute;

   --  Setup the command before parsing the arguments and executing it.
   overriding
   procedure Setup (Command : in out Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Context_Type) is
   begin
      Drivers.Command_Type (Command).Setup (Config, Context);
      GC.Set_Usage (Config => Config,
                    Usage  => Command.Get_Name & " [options] [project]",
                    Help   => Command.Get_Description);
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
                        Help => -("List the builds, filtered by the project name when given"));
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
      GC.Define_Switch (Config => Config,
                        Output => Command.List_All'Access,
                        Switch => "-a",
                        Long_Switch => "--all",
                        Help => -("Display the complete list without limiting"
                          & " the number of entries"));
   end Setup;

end Porion.Commands.List;
