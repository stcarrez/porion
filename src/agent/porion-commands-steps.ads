-----------------------------------------------------------------------
--  porion-commands-steps -- Command to add, update remove build steps
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
private package Porion.Commands.Steps is

   type Command_Type is new Porion.Commands.Drivers.Command_Type with private;

   --  Add, update or remove a build step.
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

   --  Write the help associated with the command.
   overriding
   procedure Help (Command   : in out Command_Type;
                   Name      : in String;
                   Context   : in out Context_Type);

private

   type Command_Type is new Porion.Commands.Drivers.Command_Type with record
      Delete_Pos : aliased Integer := 0;
      Update_Pos : aliased Integer := 0;
      Insert_Pos : aliased Integer := 0;
   end record;

   function Has_Several_Actions (Command : in Command_Type) return Boolean is
     ((Command.Delete_Pos > 0 and Command.Update_Pos > 0)
      or (Command.Delete_Pos > 0 and Command.Insert_Pos > 0)
      or (Command.Update_Pos > 0 and Command.Insert_Pos > 0));

end Porion.Commands.Steps;
