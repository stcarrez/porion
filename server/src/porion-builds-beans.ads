-----------------------------------------------------------------------
--  porion-builds-beans -- Beans for module builds
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

with Ada.Strings.Unbounded;

with Util.Beans.Basic;
with Util.Beans.Objects;
with Porion.Dashboards.Models;
with Porion.Builds.Modules;
with Porion.Projects.Models;
with Porion.Builds.Models;
with Porion.Nodes.Models;
package Porion.Builds.Beans is

   package UBB renames Util.Beans.Basic;
   package UBO renames Util.Beans.Objects;

   type Build_Bean is new Porion.Dashboards.Models.Project_List_Bean with record
      Ident        : Porion.Projects.Ident_Type;
      Module       : Porion.Builds.Modules.Build_Module_Access := null;
      Build        : aliased Porion.Builds.Models.Build_Ref;
      Build_Bean   : UBB.Readonly_Bean_Access;
      Recipe       : aliased Porion.Builds.Models.Recipe_Ref;
      Recipe_Bean  : UBB.Readonly_Bean_Access;
      Branch       : aliased Porion.Projects.Models.Branch_Ref;
      Branch_Bean  : UBB.Readonly_Bean_Access;
      Project      : aliased Porion.Projects.Models.Project_Ref;
      Project_Bean : UBB.Readonly_Bean_Access;
      Node         : aliased Porion.Nodes.Models.Node_Ref;
      Node_Bean    : UBB.Readonly_Bean_Access;
   end record;
   type Build_Bean_Access is access all Build_Bean'Class;

   --  Get the value identified by the name.
   overriding
   function Get_Value (From : in Build_Bean;
                       Name : in String) return Util.Beans.Objects.Object;

   --  Set the value identified by the name.
   overriding
   procedure Set_Value (From  : in out Build_Bean;
                        Name  : in String;
                        Value : in Util.Beans.Objects.Object);

   --  Load the build.
   procedure Load (Bean    : in out Build_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String);

   --  Create the Build_Bean instance.
   function Create_Build_Bean (Module : in Porion.Builds.Modules.Build_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access;

end Porion.Builds.Beans;
