-----------------------------------------------------------------------
--  porion-nodes -- Build node information and management
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
with Ada.Finalization;
with Util.Beans.Objects.Enums;
package Porion.Nodes is

   type Node_Type is (NODE_LOCAL, NODE_SSH, NODE_DOCKER, NODE_VIRSH);

   --  Use a fixed enum configuration because the value is stored in database.
   for Node_Type use (NODE_LOCAL  => 0,
                      NODE_SSH    => 1,
                      NODE_DOCKER => 2,
                      NODE_VIRSH  => 3);

   package Node_Type_Objects is new Util.Beans.Objects.Enums (Node_Type);

   type Node_Status_Type is (NODE_ERROR,
                             NODE_DISABLED,
                             NODE_ENABLED,
                             NODE_STARTING,
                             NODE_ONLINE,
                             NODE_STOPPING,
                             NODE_OFFLINE);

   --  Use a fixed enum configuration because the value is stored in database.
   --  Use -1 for error so that it helps in trouble shotting.
   for Node_Status_Type use (NODE_ERROR    => -1,
                             NODE_DISABLED => 0,
                             NODE_ENABLED  => 1,
                             NODE_STARTING => 2,
                             NODE_ONLINE   => 3,
                             NODE_STOPPING => 4,
                             NODE_OFFLINE  => 5);

   package Node_Status_Type_Objects is new Util.Beans.Objects.Enums (Node_Status_Type);

   type Controller_Type is abstract tagged limited private;
   type Controller_Access is access all Controller_Type'Class;

   procedure Start (Controller : in out Controller_Type) is null;

   procedure Stop (Controller : in out Controller_Type) is null;

   --  Execute the command in the working directory and for each output
   --  line produced by the command call the Process procedure.
   procedure Execute (Controller  : in out Controller_Type;
                      Command     : in String;
                      Working_Dir : in String := "";
                      Process     : not null access procedure (Line : in String);
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer) is abstract;

private

   type Controller_Type is abstract limited new Ada.Finalization.Limited_Controlled with record
      Ready : Boolean := True;
   end record;

end Porion.Nodes;
