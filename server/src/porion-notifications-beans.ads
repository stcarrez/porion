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

with Ada.Strings.Unbounded;

with Util.Beans.Basic;
with Util.Beans.Objects;
with Porion.Beans;
with Porion.Notifications.Modules;
with Porion.Notifications.Models;
package Porion.Notifications.Beans is

   type Notification_List_Bean is new Porion.Beans.Notification_List_Bean with record
      Module             : Porion.Notifications.Modules.Notification_Module_Access := null;
      Notifications      : aliased Porion.Notifications.Models.Notification_Info_List_Bean;
      Notifications_Bean : Porion.Notifications.Models.Notification_Info_List_Bean_Access;
   end record;
   type Notification_List_Bean_Access is access all Notification_List_Bean'Class;

   --  Get the value identified by the name.
   overriding
   function Get_Value (From : in Notification_List_Bean;
                       Name : in String) return Util.Beans.Objects.Object;

   --  Set the value identified by the name.
   overriding
   procedure Set_Value (From  : in out Notification_List_Bean;
                        Name  : in String;
                        Value : in Util.Beans.Objects.Object);

   --  Load the list of notifications.
   overriding
   procedure Load (Bean    : in out Notification_List_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String);

   --  Create the Notification_List_Bean bean instance.
   function Create_Notification_List_Bean
     (Module : in Porion.Notifications.Modules.Notification_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access;

end Porion.Notifications.Beans;
