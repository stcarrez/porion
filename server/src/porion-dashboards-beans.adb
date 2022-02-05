-----------------------------------------------------------------------
--  porion-dashboards-beans -- Beans for module dashboards
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
package body Porion.Dashboards.Beans is

   package ASC renames AWA.Services.Contexts;

   --  ------------------------------
   --  Load the list of projects.
   --  ------------------------------
   procedure Load (Bean    : in out Project_List_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String) is
      pragma Unreferenced (Outcome);

      Ctx     : constant ASC.Service_Context_Access := ASC.Current;
      Session : ADO.Sessions.Session := ASC.Get_Session (Ctx);
      Query   : ADO.Queries.Context;
   begin
      Query.Set_Query (Porion.Queries.Query_Project_Summary_List);
      Porion.Queries.List (Bean.Projects, Session, Query);
   end Load;

   --  ------------------------------
   --  Get the value identified by the name.
   --  ------------------------------
   overriding
   function Get_Value (From : in Project_List_Bean;
                       Name : in String) return Util.Beans.Objects.Object is
   begin
      if Name = "projects" then
         return Util.Beans.Objects.To_Object (Value   => From.Projects_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      else
         return Util.Beans.Objects.Null_Object;
      end if;
   end Get_Value;

   --  ------------------------------
   --  Set the value identified by the name.
   --  ------------------------------
   overriding
   procedure Set_Value (From  : in out Project_List_Bean;
                        Name  : in String;
                        Value : in Util.Beans.Objects.Object) is
   begin
      null;
   end Set_Value;

   --  ------------------------------
   --  Create the project list bean instance.
   --  ------------------------------
   function Create_Project_List_Bean (Module : in Modules.Dashboard_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access is
      Object : constant Project_List_Bean_Access := new Project_List_Bean;
   begin
      Object.Module := Module;
      Object.Projects_Bean := Object.Projects'Access;
      return Object.all'Access;
   end Create_Project_List_Bean;

end Porion.Dashboards.Beans;
