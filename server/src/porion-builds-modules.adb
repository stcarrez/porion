-----------------------------------------------------------------------
--  porion-builds-modules -- Module builds
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

with AWA.Applications;
with AWA.Modules.Beans;
with AWA.Modules.Get;
with Util.Log.Loggers;
with Servlet.Rest;
with Porion.Builds.Beans;
with Porion.Builds.Rest;
package body Porion.Builds.Modules is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builds.Module");

   package Register is new AWA.Modules.Beans (Module => Build_Module,
                                              Module_Access => Build_Module_Access);

   --  ------------------------------
   --  Initialize the builds module.
   --  ------------------------------
   overriding
   procedure Initialize (Plugin : in out Build_Module;
                         App    : in AWA.Modules.Application_Access;
                         Props  : in ASF.Applications.Config) is
   begin
      Log.Info ("Initializing the builds module");

      --  Register here any bean class, servlet, filter.
      Register.Register (Plugin => Plugin,
                         Name   => "Porion.Builds.Beans.Builds_Bean",
                         Handler => Porion.Builds.Beans.Create_Build_Bean'Access);

      AWA.Modules.Module (Plugin).Initialize (App, Props);

      Servlet.Rest.Register (App.all, Rest.API_Get_Build_Log.Definition);
      Servlet.Rest.Register (App.all, Rest.API_Get_Build_Tests.Definition);
      Servlet.Rest.Register (App.all, Rest.API_Jenkins_Get_Last_Completed_Build.Definition);
      Servlet.Rest.Register (App.all, Rest.API_Get_Project_Schields_Status.Definition);
      Servlet.Rest.Register (App.all, Rest.API_Get_Project_Tests.Definition);
      Servlet.Rest.Register (App.all, Rest.API_Get_Project_Tests_Builds.Definition);
      Servlet.Rest.Register (App.all, Rest.API_Get_Project_Coverage.Definition);
   end Initialize;

   --  ------------------------------
   --  Get the builds module.
   --  ------------------------------
   function Get_Build_Module return Build_Module_Access is
      function Get is new AWA.Modules.Get (Build_Module, Build_Module_Access, NAME);
   begin
      return Get;
   end Get_Build_Module;

end Porion.Builds.Modules;
