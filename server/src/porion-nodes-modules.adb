-----------------------------------------------------------------------
--  porion-nodes-modules -- Module nodes
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

with AWA.Modules.Beans;
with AWA.Modules.Get;
with Util.Log.Loggers;
with Porion.Nodes.Beans;
package body Porion.Nodes.Modules is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Nodes.Module");

   package Register is new AWA.Modules.Beans (Module => Node_Module,
                                              Module_Access => Node_Module_Access);

   --  ------------------------------
   --  Initialize the nodes module.
   --  ------------------------------
   overriding
   procedure Initialize (Plugin : in out Node_Module;
                         App    : in AWA.Modules.Application_Access;
                         Props  : in ASF.Applications.Config) is
   begin
      Log.Info ("Initializing the nodes module");

      --  Register here any bean class, servlet, filter.
      Register.Register (Plugin => Plugin,
                         Name   => "Porion.Nodes.Beans.Node_List_Bean",
                         Handler => Porion.Nodes.Beans.Create_Node_List_Bean'Access);
      Register.Register (Plugin => Plugin,
                         Name   => "Porion.Nodes.Beans.Node_Bean",
                         Handler => Porion.Nodes.Beans.Create_Node_Bean'Access);
      Register.Register (Plugin => Plugin,
                         Name   => "Porion.Nodes.Beans.Queue_List_Bean",
                         Handler => Porion.Nodes.Beans.Create_Queue_List_Bean'Access);

      AWA.Modules.Module (Plugin).Initialize (App, Props);

      --  Add here the creation of manager instances.
   end Initialize;

   --  ------------------------------
   --  Get the nodes module.
   --  ------------------------------
   function Get_Node_Module return Node_Module_Access is
      function Get is new AWA.Modules.Get (Node_Module, Node_Module_Access, NAME);
   begin
      return Get;
   end Get_Node_Module;

end Porion.Nodes.Modules;
