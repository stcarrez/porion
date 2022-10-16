-----------------------------------------------------------------------
--  porion-notifications-beans -- Beans for module notifications
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

with ADO.Sessions;
with ADO.Queries;
with AWA.Services.Contexts;
package body Porion.Notifications.Beans is

   package ASC renames AWA.Services.Contexts;

   --  ------------------------------
   --  Get the value identified by the name.
   --  ------------------------------
   overriding
   function Get_Value (From : in Notification_List_Bean;
                       Name : in String) return Util.Beans.Objects.Object is
   begin
      if Name = "notifications" then
         return Util.Beans.Objects.To_Object (Value   => From.Notifications_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      else
         return Util.Beans.Objects.Null_Object;
      end if;
   end Get_Value;

   --  ------------------------------
   --  Set the value identified by the name.
   --  ------------------------------
   overriding
   procedure Set_Value (From  : in out Notification_List_Bean;
                        Name  : in String;
                        Value : in Util.Beans.Objects.Object) is
   begin
      null;
   end Set_Value;

   --  ------------------------------
   --  Load the list of notifications.
   --  ------------------------------
   overriding
   procedure Load (Bean    : in out Notification_List_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String) is
      pragma Unreferenced (Outcome);

      Ctx     : constant ASC.Service_Context_Access := ASC.Current;
      Session : ADO.Sessions.Session := ASC.Get_Session (Ctx);
      Query   : ADO.Queries.Context;
   begin
      Query.Set_Query (Porion.Notifications.Models.Query_Notification_List);
      Porion.Notifications.Models.List (Bean.Notifications, Session, Query);
   end Load;

   --  ------------------------------
   --  Create the Notification_List_Bean bean instance.
   --  ------------------------------
   function Create_Notification_List_Bean
     (Module : in Porion.Notifications.Modules.Notification_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access is
      Object : constant Notification_List_Bean_Access := new Notification_List_Bean;
   begin
      Object.Module := Module;
      Object.Notifications_Bean := Object.Notifications'Access;
      return Object.all'Access;
   end Create_Notification_List_Bean;

end Porion.Notifications.Beans;
