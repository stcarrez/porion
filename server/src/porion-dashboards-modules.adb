-----------------------------------------------------------------------
--  porion-dashboards-modules -- Module dashboards
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

with AWA.Applications;
with AWA.Modules.Beans;
with AWA.Modules.Get;
with Util.Log.Loggers;
with Porion.Dashboards.Beans;
with Porion.Dashboards.Beans.Stats;
package body Porion.Dashboards.Modules is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Dashboards.Module");

   package Register is new AWA.Modules.Beans (Module => Dashboard_Module,
                                              Module_Access => Dashboard_Module_Access);

   --  ------------------------------
   --  Initialize the dashboards module.
   --  ------------------------------
   overriding
   procedure Initialize (Plugin : in out Dashboard_Module;
                         App    : in AWA.Modules.Application_Access;
                         Props  : in ASF.Applications.Config) is
   begin
      Log.Info ("Initializing the dashboards module");

      --  Register here any bean class, servlet, filter.
      Register.Register (Plugin => Plugin,
                         Name   => "Porion.Dashboards.Beans.Project_List_Bean",
                         Handler => Porion.Dashboards.Beans.Create_Project_List_Bean'Access);
      Register.Register (Plugin => Plugin,
                         Name   => "Porion.Dashboards.Beans.Stats.Last_Builds_Bean",
                         Handler => Porion.Dashboards.Beans.Stats.Create_Last_Builds_Bean'Access);
      Register.Register (Plugin => Plugin,
                         Name   => "Porion.Dashboards.Beans.Stats.Metrics_Bean",
                         Handler => Porion.Dashboards.Beans.Stats.Create_Metrics_Bean'Access);

      Plugin.Percent_Converter.Set_Picture ("ZZ9.9");
      App.Add_Converter (Name      => "percentConverter",
                         Converter => Plugin.Percent_Converter'Unchecked_Access);

      AWA.Modules.Module (Plugin).Initialize (App, Props);

      --  Add here the creation of manager instances.
   end Initialize;

   --  ------------------------------
   --  Get the dashboards module.
   --  ------------------------------
   function Get_Dashboard_Module return Dashboard_Module_Access is
      function Get is new AWA.Modules.Get (Dashboard_Module, Dashboard_Module_Access, NAME);
   begin
      return Get;
   end Get_Dashboard_Module;

end Porion.Dashboards.Modules;
