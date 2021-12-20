-----------------------------------------------------------------------
--  porion -- porion applications
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

with Util.Log.Loggers;

package body Porion.Applications is

   use AWA.Applications;

   Log     : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion");

   --  ------------------------------
   --  Initialize the servlets provided by the application.
   --  This procedure is called by <b>Initialize</b>.
   --  It should register the application servlets.
   --  ------------------------------
   overriding
   procedure Initialize_Servlets (App : in out Application) is
   begin
      Log.Info ("Initializing application servlets...");

      App.Self := App'Unchecked_Access;
      AWA.Applications.Application (App).Initialize_Servlets;
      App.Add_Servlet (Name => "faces", Server => App.Self.Faces'Access);
      App.Add_Servlet (Name => "files", Server => App.Self.Files'Access);
      App.Add_Servlet (Name => "ajax", Server => App.Self.Ajax'Access);
      App.Add_Servlet (Name => "measures", Server => App.Self.Measures'Access);
      App.Add_Servlet (Name => "auth", Server => App.Self.Auth'Access);
      App.Add_Servlet (Name => "verify-auth", Server => App.Self.Verify_Auth'Access);
   end Initialize_Servlets;

   --  ------------------------------
   --  Initialize the filters provided by the application.
   --  This procedure is called by <b>Initialize</b>.
   --  It should register the application filters.
   --  ------------------------------
   overriding
   procedure Initialize_Filters (App : in out Application) is
   begin
      Log.Info ("Initializing application filters...");

      AWA.Applications.Application (App).Initialize_Filters;
      App.Add_Filter (Name => "dump", Filter => App.Self.Dump'Access);
      App.Add_Filter (Name => "measures", Filter => App.Self.Measures'Access);
      App.Add_Filter (Name => "service", Filter => App.Self.Service_Filter'Access);
      App.Add_Filter (Name => "no-cache", Filter => App.Self.No_Cache'Access);
      App.Set_Global ("contextPath", CONTEXT_PATH);
   end Initialize_Filters;

   --  ------------------------------
   --  Initialize the AWA modules provided by the application.
   --  This procedure is called by <b>Initialize</b>.
   --  It should register the modules used by the application.
   --  ------------------------------
   overriding
   procedure Initialize_Modules (App : in out Application) is
   begin
      Log.Info ("Initializing application modules...");

      App.Add_Converter (Name      => "smartDateConverter",
                         Converter => App.Self.Rel_Date_Converter'Access);
      App.Add_Converter (Name      => "sizeConverter",
                         Converter => App.Self.Size_Converter'Access);
      App.Add_Converter (Name      => "microsecondConverter",
                         Converter => App.Self.Microsec_Converter'Access);
      App.Add_Converter (Name      => "millisecondConverter",
                         Converter => App.Self.Millisec_Converter'Access);

      App.Self.Microsec_Converter.Unit := ASF.Converters.Durations.MICROSECOND;
      App.Self.Millisec_Converter.Unit := ASF.Converters.Durations.MILLISECOND;

      Register (App    => App.Self.all'Access,
                Name   => AWA.Users.Modules.NAME,
                URI    => "user",
                Module => App.User_Module'Access);

      Register (App    => App.Self.all'Access,
                Name   => AWA.Mail.Modules.NAME,
                URI    => "mail",
                Module => App.Mail_Module'Access);

      Register (App    => App.Self.all'Access,
                Name   => Porion.Dashboards.Modules.NAME,
                URI    => "dashboards",
                Module => App.Dashboard_Module'Access);
      Register (App    => App.Self.all'Access,
                Name   => Porion.Projects.Modules.NAME,
                URI    => "projects",
                Module => App.Project_Module'Access);
      Register (App    => App.Self.all'Access,
                Name   => Porion.Builds.Modules.NAME,
                URI    => "builds",
                Module => App.Build_Module'Access);
   end Initialize_Modules;

end Porion.Applications;
