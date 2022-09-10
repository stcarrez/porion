-----------------------------------------------------------------------
--  porion-commands-remove -- Remove command
--  Copyright (C) 2021, 2022 Stephane Carrez
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
with Porion.Builds.Services;
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
            Arg   : constant String := Args.Get_Argument (I);
            Ident : Porion.Projects.Ident_Type;
         begin
            Ident := Porion.Projects.Parse (Arg);
            Context.Project_Service.Load (Ident);

            if Porion.Projects.Has_Build (Ident) then
               if not Command.Interactive
                 or else Command.Force
                 or else Confirm (Format (-("remove build '{0}'?"), Arg))
               then
                  Builds.Services.Remove_Build (Context.Project_Service);
                  Context.Notice (-("Build '{0}'' is removed"), Arg);
               end if;
            elsif Porion.Projects.Has_Recipe (Ident) then
               if not Command.Interactive
                 or else Command.Force
                 or else Confirm (Format (-("remove build recipe '{0}'?"), Arg))
               then
                  Builds.Services.Remove_Recipe (Context.Project_Service);
                  Context.Notice (-("Project recipe '{0}' is removed"), Arg);
               end if;
            else
               if not Command.Interactive
                 or else Command.Force
                 or else Confirm (Format (-("remove project '{0}'?"), Arg))
               then
                  Projects.Services.Remove_Project (Context.Project_Service, Arg);
                  Context.Notice (-("Project '{0}' is removed"), Arg);
               end if;
            end if;

         exception
            when Porion.Services.Not_Found =>
               if not Command.Force then
                  Context.Error_Not_Found (Ident);
               end if;

            when Porion.Projects.Invalid_Ident =>
               Commands.Error (-("invalid project or build identifier: {0}"), Arg);

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
