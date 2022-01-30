-----------------------------------------------------------------------
--  porion-commands-init -- Setup command
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
with Porion.Resources.Queries;
with Porion.Resources.Schema;
with Porion.Services;
package body Porion.Commands.Init is

   --  ------------------------------
   --  Initialize the Porion workspace to manage and build projects.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Command, Name);

      Schema : constant Porion.Resources.Content_Access
        := Porion.Resources.Schema.Get_Content ("create-porion_agent-sqlite");
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Error (-("missing directory to setup"));

      elsif Args.Get_Count /= 1 then
         Porion.Commands.Error (-("too many arguments for the command"));
      else
         declare
            Path  : constant String := Args.Get_Argument (1);
         begin
            Context.Project_Service.Setup (Path, Resources.Queries.Get_Content'Access, Schema);

            Context.Notice (-("Porion workspace created in {0}"), Path);
            Context.Notice (-("Default build node 'localhost' is registered"));
            Context.Notice (-("Use 'porion add' to register a first project"));

         exception
            when Porion.Services.Invalid_Workspace =>
               Porion.Commands.Error (-("workspace directory '{0}' is not empty"), Path);

         end;

      end if;
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
   end Setup;

end Porion.Commands.Init;
