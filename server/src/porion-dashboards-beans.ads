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

with Ada.Strings.Unbounded;

with Util.Beans.Basic.Lists;
with Util.Beans.Objects;
with Porion.Queries;
with Porion.Beans;
with Porion.Dashboards.Modules;
package Porion.Dashboards.Beans is

   package UBO renames Util.Beans.Objects;

   type Project_Report_Bean is new Porion.Queries.Project_Info with record
      Config_Changes : Natural := 0;
      Recipe_Changes : Natural := 0;
      Build_Changes  : Natural := 0;
   end record;

   --  Get the value identified by the name.
   overriding
   function Get_Value (From : in Project_Report_Bean;
                       Name : in String) return UBO.Object;

   package Project_Report_Beans is
      new Util.Beans.Basic.Lists (Element_Type => Project_Report_Bean);
   package Project_Report_Vectors renames Project_Report_Beans.Vectors;

   type Project_Report_Beans_List_Access is access all Project_Report_Beans.List_Bean;

   type Project_Report_List_Bean is new Porion.Beans.Project_List_Bean with record
      Module        : Porion.Dashboards.Modules.Dashboard_Module_Access := null;
      Projects      : aliased Project_Report_Beans.List_Bean;
      Projects_Bean : Project_Report_Beans_List_Access;
   end record;
   type Project_Report_List_Bean_Access is access all Project_Report_List_Bean'Class;

   --  Get the value identified by the name.
   overriding
   function Get_Value (From : in Project_Report_List_Bean;
                       Name : in String) return UBO.Object;

   --  Set the value identified by the name.
   overriding
   procedure Set_Value (From  : in out Project_Report_List_Bean;
                        Name  : in String;
                        Value : in UBO.Object);

   --  Load the list of projects.
   procedure Load (Bean    : in out Project_Report_List_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String);

   --  Create the project list bean instance.
   function Create_Project_Report_List_Bean (Module : in Modules.Dashboard_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access;

   type Project_List_Bean is new Porion.Beans.Project_List_Bean with record
      Module        : Porion.Dashboards.Modules.Dashboard_Module_Access := null;
      Projects      : aliased Porion.Queries.Project_Info_List_Bean;
      Projects_Bean : Porion.Queries.Project_Info_List_Bean_Access;
   end record;
   type Project_List_Bean_Access is access all Project_List_Bean'Class;

   --  Get the value identified by the name.
   overriding
   function Get_Value (From : in Project_List_Bean;
                       Name : in String) return UBO.Object;

   --  Set the value identified by the name.
   overriding
   procedure Set_Value (From  : in out Project_List_Bean;
                        Name  : in String;
                        Value : in UBO.Object);

   --  Load the list of projects.
   procedure Load (Bean    : in out Project_List_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String);

   --  Create the project list bean instance.
   function Create_Project_List_Bean (Module : in Modules.Dashboard_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access;

end Porion.Dashboards.Beans;
