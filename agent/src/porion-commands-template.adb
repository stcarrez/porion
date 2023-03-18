-----------------------------------------------------------------------
--  porion-commands-template -- Template management command
--  Copyright (C) 2022 Stephane Carrez
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
with Util.Strings.Vectors;
with Porion.Sources;
with Porion.Services;
with Porion.Projects;
with Porion.Builds.Services;
with Porion.Templates.Parser;
package body Porion.Commands.Template is

   use type Porion.Sources.Source_Control_Type;

   procedure Import_Template (Command : in out Command_Type;
                              Args    : in Argument_List'Class;
                              Context : in out Context_Type) is
      Repo   : Porion.Templates.Repository_Type;
   begin
      Porion.Templates.Parser.Load (Command.Template.all, Repo);
   end Import_Template;

   --  ------------------------------
   --  Add, update or remove a build step.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);
   begin
      if Command.Template'Length > 0 then
         Import_Template (Command, Args, Context);
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
      GC.Define_Switch (Config => Config,
                        Output => Command.Template'Access,
                        Long_Switch => "--import=",
                        Argument => "PATH",
                        Help => -("Path of the template file to use"));
   end Setup;

end Porion.Commands.Template;
