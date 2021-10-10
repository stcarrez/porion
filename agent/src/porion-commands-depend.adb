-----------------------------------------------------------------------
--  porion-commands-depend -- Depend command to add/remove project dependencies
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
package body Porion.Commands.Depend is

   --  ------------------------------
   --  Add or remove dependencies on a project.
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

      declare
         Project_Name : constant String := Args.Get_Argument (1);
      begin
         Context.Project_Service.Load_Project (Project_Name);
         for I in 2 .. Args.Get_Count loop
            declare
               Depend_Name : constant String := Args.Get_Argument (I);
            begin
               if not Command.Remove then
                  Projects.Services.Add_Dependency (Context.Project_Service, Depend_Name);
               else
                  Projects.Services.Remove_Dependency (Context.Project_Service, Depend_Name);
               end if;

            exception
               when Porion.Services.Not_Found =>
                  Porion.Commands.Error (-("project '{0}' does not exists"),
                                         Depend_Name);
            end;
         end loop;

      exception
         when Porion.Services.Not_Found =>
            Porion.Commands.Error (-("project '{0}' not found"),
                                   Project_Name);
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
      GC.Define_Switch (Config, Command.Remove'Access,
                        "-r", "--remove", -("remove the dependencies"));
   end Setup;

end Porion.Commands.Depend;
