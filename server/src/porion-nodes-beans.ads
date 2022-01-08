-----------------------------------------------------------------------
--  porion-nodes-beans -- Beans for module nodes
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

with Ada.Strings.Unbounded;

with Util.Beans.Basic;
with Util.Beans.Objects;

with Porion.Nodes.Modules;
with Porion.Queries;
with Porion.Dashboards.Models;
package Porion.Nodes.Beans is

   package UBO renames Util.Beans.Objects;

   type Node_List_Bean is new Porion.Dashboards.Models.Project_List_Bean with record
      Nodes       : aliased Porion.Queries.Node_Info_List_Bean;
      Nodes_Bean  : Porion.Queries.Node_Info_List_Bean_Access;
      Queue_Count : Natural := 0;
      Queue_Nodes : Natural := 0;
   end record;
   type Node_List_Bean_Access is access all Node_List_Bean'Class;

   --  Get the value identified by the name.
   overriding
   function Get_Value (From : in Node_List_Bean;
                       Name : in String) return UBO.Object;

   --  Set the value identified by the name.
   overriding
   procedure Set_Value (From  : in out Node_List_Bean;
                        Name  : in String;
                        Value : in UBO.Object);

   --  Load the list of projects.
   procedure Load (Bean    : in out Node_List_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String);

   --  Create the project list bean instance.
   function Create_Node_List_Bean (Module : in Modules.Node_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access;

end Porion.Nodes.Beans;
