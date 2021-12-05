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
with ASF.Applications;

with AWA.Modules;
with ASF.Converters.Numbers;
package Porion.Dashboards.Modules is

   --  The name under which the module is registered.
   NAME : constant String := "dashboards";

   --  ------------------------------
   --  Module dashboards
   --  ------------------------------
   type Dashboard_Module is new AWA.Modules.Module with private;
   type Dashboard_Module_Access is access all Dashboard_Module'Class;

   --  Initialize the dashboards module.
   overriding
   procedure Initialize (Plugin : in out Dashboard_Module;
                         App    : in AWA.Modules.Application_Access;
                         Props  : in ASF.Applications.Config);

   --  Get the dashboards module.
   function Get_Dashboard_Module return Dashboard_Module_Access;

private

   type Dashboard_Module is new AWA.Modules.Module with record
      Percent_Converter : aliased ASF.Converters.Numbers.Number_Converter;
   end record;

end Porion.Dashboards.Modules;
