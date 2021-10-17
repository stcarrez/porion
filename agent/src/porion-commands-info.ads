-----------------------------------------------------------------------
--  porion-commands-info -- Info command
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
with Util.Properties.Bundles;
private package Porion.Commands.Info is

   type Command_Type is new Porion.Commands.Drivers.Command_Type with private;

   --  Report some information about a project.
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

   type Command_Type is new Porion.Commands.Drivers.Command_Type with record
      Bundle        : Util.Properties.Bundles.Manager;
      List_All      : aliased Boolean := False;
      List_Recipes  : aliased Boolean := False;
      List_Nodes    : aliased Boolean := False;
      List_Builds   : aliased Boolean := False;
   end record;

end Porion.Commands.Info;
