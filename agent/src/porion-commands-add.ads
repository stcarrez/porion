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
with Porion.Commands.Drivers;
private package Porion.Commands.Add is

   type Command_Type is new Porion.Commands.Drivers.Command_Type with private;

   --  Add a project, identify its source control scheme and build steps.
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type);

   --  Setup the command before parsing the arguments and executing it.
   overriding
   procedure Setup (Command : in out Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Context_Type);

private

   --  Add a project with source control described by the URI.
   procedure Add_Project (Command : in out Command_Type;
                          URI     : in String;
                          Context : in out Context_Type);

   --  Add a recipe to build an existing project.
   procedure Add_Recipe (Command : in out Command_Type;
                         Target  : in String;
                         Source  : in String;
                         Context : in out Context_Type);

   type Command_Type is new Porion.Commands.Drivers.Command_Type with record
      Recipe : aliased Boolean := False;
   end record;

end Porion.Commands.Add;
