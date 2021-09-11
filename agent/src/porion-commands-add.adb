-----------------------------------------------------------------------
--  porion-commands-add -- Add command
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
package body Porion.Commands.Add is

   --  ------------------------------
   --  Add a project, identify its source control scheme and build steps.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Command, Name);
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Error (-("missing project URL or file to add"));
         return;
      end if;
      Context.Open;

      declare
         Logger : Porion.Loggers.Logger_Type;
         Info   : Porion.Sources.Source_Info_Type;
         Config : Porion.Configs.Config_Type;
         URI    : constant String := Args.Get_Argument (1);
      begin
         Porion.Sources.Factories.Guess (Path   => URI,
                                         Config => Config,
                                         Result => Info,
                                         Logger => Logger);

         Context.Project_Service.Add_Project (Info);
         Context.Console.Notice (N_INFO, Format (-("Project {0} - {1} added"),
                                 To_String (Info.Name), URI));

         Context.Build_Service.Open (Context.Project_Service);
         Context.Build_Service.Make_Build_Config;

      exception
         when Porion.Projects.Services.Name_Used =>
            Porion.Commands.Error (-("project '{0}' already exists"),
                                   To_String (Info.Name));

         when Porion.Projects.Services.Invalid_Name =>
            Porion.Commands.Error (-("invalid project name '{0}'"),
                                   To_String (Info.Name));

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

end Porion.Commands.Add;
