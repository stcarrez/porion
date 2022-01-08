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
with ADO.Sessions;
with ADO.Queries;
with AWA.Services.Contexts;
package body Porion.Nodes.Beans is

   package ASC renames AWA.Services.Contexts;

   --  ------------------------------
   --  Load the list of projects.
   --  ------------------------------
   procedure Load (Bean    : in out Node_List_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String) is
      Ctx     : constant ASC.Service_Context_Access := ASC.Current;
      Session : ADO.Sessions.Session := ASC.Get_Session (Ctx);
      Query   : ADO.Queries.Context;
   begin
      Query.Set_Query (Porion.Queries.Query_Node_List);
      Porion.Queries.List (Bean.Nodes, Session, Query);
      Bean.Queue_Count := 0;
      for Node of Bean.Nodes.List loop
         if Node.Queue_Count > 0 then
            Bean.Queue_Count := Bean.Queue_Count + Node.Queue_Count;
            Bean.Queue_Nodes := Bean.Queue_Nodes + 1;
         end if;
      end loop;
   end Load;

   --  ------------------------------
   --  Get the value identified by the name.
   --  ------------------------------
   overriding
   function Get_Value (From : in Node_List_Bean;
                       Name : in String) return UBO.Object is
   begin
      if Name = "nodes" then
         return UBO.To_Object (Value   => From.Nodes_Bean,
                               Storage => UBO.STATIC);
      elsif Name = "queue_count" then
         return UBO.To_Object (From.Queue_Count);
      elsif Name = "queue_nodes" then
         return UBO.To_Object (From.Queue_Nodes);
      elsif Name = "count" then
         return UBO.To_Object (Natural (From.Nodes.List.Length));
      else
         return UBO.Null_Object;
      end if;
   end Get_Value;

   --  ------------------------------
   --  Set the value identified by the name.
   --  ------------------------------
   overriding
   procedure Set_Value (From  : in out Node_List_Bean;
                        Name  : in String;
                        Value : in UBO.Object) is
   begin
      null;
   end Set_Value;

   --  ------------------------------
   --  Create the project list bean instance.
   --  ------------------------------
   function Create_Node_List_Bean (Module : in Modules.Node_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access is
      pragma Unreferenced (Module);

      Object : constant Node_List_Bean_Access := new Node_List_Bean;
   begin
      Object.Nodes_Bean := Object.Nodes'Access;
      return Object.all'Access;
   end Create_Node_List_Bean;

end Porion.Nodes.Beans;
