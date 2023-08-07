-----------------------------------------------------------------------
--  porion-notifications-modules -- Module notifications
--  Copyright (C) 2022 Stephane Carrez
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

with Servlet.Rest;
with ADO.Sessions;
with ADO.Queries;
with AWA.Modules.Beans;
with AWA.Modules.Get;
with AWA.Services.Contexts;
with AWA.Users.Models;
with Util.Log.Loggers;
with Porion.Services;
with Porion.Projects;
with Porion.Notifications.Beans;
with Porion.Notifications.Rest;
with Porion.Notifications.Models;
package body Porion.Notifications.Modules is

   package ASC renames AWA.Services.Contexts;

   Log : constant Util.Log.Loggers.Logger
     := Util.Log.Loggers.Create ("Porion.Notifications.Module");

   package Register is new AWA.Modules.Beans (Module => Notification_Module,
                                              Module_Access => Notification_Module_Access);

   --  ------------------------------
   --  Initialize the notifications module.
   --  ------------------------------
   overriding
   procedure Initialize (Plugin : in out Notification_Module;
                         App    : in AWA.Modules.Application_Access;
                         Props  : in ASF.Applications.Config) is
   begin
      Log.Info ("Initializing the notifications module");

      --  Register here any bean class, servlet, filter.
      Register.Register (Plugin => Plugin,
                         Name   => "Porion.Notifications.Beans.Notification_List_Bean",
                         Handler => Beans.Create_Notification_List_Bean'Access);

      AWA.Modules.Module (Plugin).Initialize (App, Props);

      Servlet.Rest.Register (App.all, Rest.API_POST_Subscriber.Definition);

      --  Add here the creation of manager instances.
   end Initialize;

   --  ------------------------------
   --  Get the notifications module.
   --  ------------------------------
   function Get_Notification_Module return Notification_Module_Access is
      function Get is new AWA.Modules.Get (Notification_Module, Notification_Module_Access, NAME);
   begin
      return Get;
   end Get_Notification_Module;

   procedure Create_Subscriber (Module  : in out Notification_Module;
                                Project : in String;
                                Email   : in String;
                                Result  : out ADO.Identifier) is
      Ctx        : constant ASC.Service_Context_Access := ASC.Current;
      DB         : ADO.Sessions.Master_Session := Module.Get_Master_Session;
      Query      : ADO.Queries.Context;
      Prj_Ctx    : Porion.Services.Context_Type;
      User_Email : AWA.Users.Models.Email_Ref;
      Subscriber : Porion.Notifications.Models.Subscriber_Ref;
      Found      : Boolean;
   begin
      Result := ADO.NO_IDENTIFIER;

      Prj_Ctx.DB := DB;
      Prj_Ctx.Ident := Porion.Projects.Parse (Project);
      Prj_Ctx.Load (Prj_Ctx.Ident);

      if Email'Length = 0 then
         User_Email := AWA.Users.Models.Email_Ref (Ctx.Get_User.Get_Email);
      else
         Query.Set_Filter ("o.email = :email");
         Query.Bind_Param ("email", Email);
         User_Email.Find (DB, Query, Found);
      end if;

      Subscriber.Set_Project (Prj_Ctx.Project);
      Subscriber.Set_Email (User_Email);
      Subscriber.Set_Frequency (Porion.Notifications.Models.NOTIFY_DAILY);
      Subscriber.Set_Send_Count (0);
      Subscriber.Set_Notify_Config (True);
      Subscriber.Set_Notify_Build (True);
      Subscriber.Set_Notify_Xunit (True);
      Subscriber.Save (DB);

      Result := Subscriber.Get_Id;
   end Create_Subscriber;

end Porion.Notifications.Modules;
