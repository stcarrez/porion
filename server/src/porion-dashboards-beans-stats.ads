-----------------------------------------------------------------------
--  porion-dashboards-beans-stats -- Statistics about projects and builds
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
with Porion.Queries;
with Porion.Dashboards.Modules;
with Porion.Dashboards.Models;
package Porion.Dashboards.Beans.Stats is

   type Build_Stat_Bean_Access is access all Porion.Queries.Build_Stat;

   type Last_Builds_Bean is new Porion.Dashboards.Models.Project_List_Bean with record
      Module        : Porion.Dashboards.Modules.Dashboard_Module_Access := null;
      Pass          : aliased Porion.Queries.Build_Stat;
      Pass_Bean     : Build_Stat_Bean_Access;
      Fail          : aliased Porion.Queries.Build_Stat;
      Fail_Bean     : Build_Stat_Bean_Access;
      Total         : aliased Porion.Queries.Build_Stat;
      Total_Bean    : Build_Stat_Bean_Access;
   end record;
   type Last_Builds_Bean_Access is access all Last_Builds_Bean'Class;

   --  Get the value identified by the name.
   overriding
   function Get_Value (From : in Last_Builds_Bean;
                       Name : in String) return Util.Beans.Objects.Object;

   --  Load the stats.
   procedure Load (Bean    : in out Last_Builds_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String);

   --  Create the stats build bean instance.
   function Create_Last_Builds_Bean (Module : in Modules.Dashboard_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access;

end Porion.Dashboards.Beans.Stats;
