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
with ASF.Applications;
with ADO;

with AWA.Modules;
package Porion.Notifications.Modules is

   --  The name under which the module is registered.
   NAME : constant String := "notifications";

   --  ------------------------------
   --  Module notifications
   --  ------------------------------
   type Notification_Module is new AWA.Modules.Module with private;
   type Notification_Module_Access is access all Notification_Module'Class;

   --  Initialize the notifications module.
   overriding
   procedure Initialize (Plugin : in out Notification_Module;
                         App    : in AWA.Modules.Application_Access;
                         Props  : in ASF.Applications.Config);

   --  Get the notifications module.
   function Get_Notification_Module return Notification_Module_Access;

   procedure Create_Subscriber (Module  : in out Notification_Module;
                                Project : in String;
                                Email   : in String;
                                Result  : out ADO.Identifier);

private

   type Notification_Module is new AWA.Modules.Module with null record;

end Porion.Notifications.Modules;
