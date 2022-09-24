-----------------------------------------------------------------------
--  porion-notifications-rest -- REST API for the notifications
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

with ADO;
with Util.Strings;
with Porion.Services;
with Porion.Notifications.Modules;
package body Porion.Notifications.Rest is

   procedure Post_Subscriber
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out OpenAPI.Servers.Context_Type) is
      pragma Unreferenced (Req, Reply, Stream);

      Project_Name : UString;
      Email : UString;
      Result : ADO.Identifier;
   begin
      if not Context.Is_Authenticated then
         Context.Set_Error (401, "Not authenticated");
         return;
      end if;

      OpenAPI.Servers.Get_Parameter (Context, "project", Project_Name);
      OpenAPI.Servers.Get_Parameter (Context, "email", Email);
      declare
         Module : constant Modules.Notification_Module_Access := Modules.Get_Notification_Module;
      begin
         Module.Create_Subscriber (To_String (Project_Name), To_String (Email), Result);
         Context.Set_Location ("/porion/api/v1/subscribers/"
                               & Util.Strings.Image (Long_Long_Integer (Result)));
      end;

   exception
      when Porion.Services.Not_Found =>
         Context.Set_Error (400, "Project not found");

   end Post_Subscriber;

end Porion.Notifications.Rest;
