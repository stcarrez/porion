-----------------------------------------------------------------------
--  porion-projects-operation -- Rest server operation on a project or build
--  Copyright (C) 2017, 2018, 2021 Stephane Carrez
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
with Security.Permissions;
with Servlet.Rest;
with Swagger.Servers;
with Porion.Services;
generic
   with procedure Handler (Req     : in out Swagger.Servers.Request'Class;
                           Reply   : in out Swagger.Servers.Response'Class;
                           Stream  : in out Swagger.Servers.Output_Stream'Class;
                           Context : in out Porion.Services.Context_Type);
   Method     : Servlet.Rest.Method_Type := Servlet.Rest.GET;
   URI        : String;
   Permission : Security.Permissions.Permission_Index := Security.Permissions.NONE;
package Porion.Projects.Operation is

   function Definition return Servlet.Rest.Descriptor_Access;

end Porion.Projects.Operation;
