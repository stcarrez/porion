-----------------------------------------------------------------------
--  porion-nodes-ssh -- SSH build node management
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
with Porion.Nodes.Local;
with Porion.Nodes.Models;
private with EL.Expressions;
private package Porion.Nodes.SSH is

   SSH_COMMAND_NAME : constant String := "command_ssh";

   SSH_COMMAND      : constant String := "ssh -x "
     & "#{not empty identity ? '-i ' : ''}#{identity} "
     & "#{not empty login ? '-l ' : ''}#{login} #{hostname}";

   type Controller_Type is limited new Local.Controller_Type with private;
   type Controller_Access is access all Controller_Type'Class;

   --  Create the controller for the management of the given build node.
   function Create (Listener : in Listener_Access;
                    Node     : in Models.Node_Ref) return Nodes.Controller_Access;

   --  Returns true if this executor runs locally.
   overriding
   function Is_Local (Controller : in Controller_Type) return Boolean is (False);

   --  Execute the command in the working directory on the remote host through
   --  ssh and for each output line produced by the command call Process.
   overriding
   procedure Execute (Controller  : in out Controller_Type;
                      Command     : in String;
                      Working_Dir : in String := "";
                      Process     : not null access procedure (Line : in String);
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer);

   --  Create the directory and optionally make sure it is cleaned.
   overriding
   procedure Create_Directory (Controller : in out Controller_Type;
                               Path       : in String;
                               Clean      : in Boolean;
                               Process    : not null access
                                 procedure (Line : in String));

private

   type Controller_Type is limited new Local.Controller_Type with record
      Hostname : Porion.UString;
      Login    : Porion.UString;
      Identity : Porion.UString;
      Command  : EL.Expressions.Expression;
   end record;

end Porion.Nodes.SSH;
