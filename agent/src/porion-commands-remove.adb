-----------------------------------------------------------------------
--  porion-commands-remove -- Remove command
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
with Porion.Loggers;
with Porion.Configs;
with Porion.Sources.Factories;
package body Porion.Commands.Remove is

   --  ------------------------------
   --  Remove a project and all its build data.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Command, Name);
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Log.Error (-("missing project name"));
         raise Error;
      end if;
      Context.Open;

      declare
         Logger : Porion.Loggers.Logger_Type;
         Info   : Porion.Sources.Source_Info_Type;
         Config : Porion.Configs.Config_Type;
         Project_Name : constant String := Args.Get_Argument (1);
      begin
         Context.Project_Service.Remove_Project (Project_Name);
         Context.Console.Notice (N_INFO, Format (-("Project {0} is removed"),
                                 Project_Name));

      exception
         when Porion.Projects.Services.Name_Used =>
            Porion.Commands.Log.Error (-("project '{0}' already exists"),
                                       Project_Name);
            raise Error;
      end;

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
      GC.Define_Switch (Config, Command.Json'Access,
                        "-j", "json", -("Produce a JSON output"));
   end Setup;

   --  ------------------------------
   --  Write the help associated with the command.
   --  ------------------------------
   overriding
   procedure Help (Command   : in out Command_Type;
                   Name      : in String;
                   Context   : in out Context_Type) is
   begin
      null;
   end Help;

end Porion.Commands.Remove;
