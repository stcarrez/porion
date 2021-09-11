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
with Porion.Services;
package body Porion.Commands.Remove is

   --  ------------------------------
   --  Remove a project and all its build data.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Error (-("missing project name"));
         return;
      end if;
      Context.Open;

      for I in 1 .. Args.Get_Count loop
         declare
            Project_Name : constant String := Args.Get_Argument (I);
         begin
            if not Command.Interactive
              or else Command.Force
              or else Confirm (Format (-("remove project '{0}'?"), Project_Name))
            then
               Context.Project_Service.Load_Project (Project_Name);
               Context.Project_Service.Remove_Project (Project_Name);
               Context.Console.Notice (N_INFO, Format (-("Project {0} is removed"),
                                       Project_Name));
            end if;

         exception
            when Porion.Services.Not_Found =>
               if not Command.Force then
                  Porion.Commands.Error (-("project '{0}' already exists"),
                                         Project_Name);
               end if;
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
      GC.Define_Switch (Config, Command.Force'Access,
                        "-f", "--force", -("ignore nonexistent projects, never prompt"));
      GC.Define_Switch (Config, Command.Interactive'Access,
                        "-i", "--interactive", -("prompt before every removal"));
   end Setup;

end Porion.Commands.Remove;
