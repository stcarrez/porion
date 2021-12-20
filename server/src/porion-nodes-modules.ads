-----------------------------------------------------------------------
--  porion-nodes-modules -- Module nodes
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
with ASF.Applications;

with AWA.Modules;
package Porion.Nodes.Modules is

   --  The name under which the module is registered.
   NAME : constant String := "nodes";

   --  ------------------------------
   --  Module nodes
   --  ------------------------------
   type Node_Module is new AWA.Modules.Module with private;
   type Node_Module_Access is access all Node_Module'Class;

   --  Initialize the nodes module.
   overriding
   procedure Initialize (Plugin : in out Node_Module;
                         App    : in AWA.Modules.Application_Access;
                         Props  : in ASF.Applications.Config);

   --  Get the nodes module.
   function Get_Node_Module return Node_Module_Access;

private

   type Node_Module is new AWA.Modules.Module with null record;

end Porion.Nodes.Modules;
