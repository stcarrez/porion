-----------------------------------------------------------------------
--  porion-builds-beans -- Beans for module builds
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

with Swagger.Servers;
with Porion.Services;
with Porion.Projects.Operation;
package Porion.Builds.Rest is

   procedure Get_Build_Log
     (Req     : in out Swagger.Servers.Request'Class;
      Reply   : in out Swagger.Servers.Response'Class;
      Stream  : in out Swagger.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type);

   procedure Jenkins_Get_Last_Completed_Build
     (Req     : in out Swagger.Servers.Request'Class;
      Reply   : in out Swagger.Servers.Response'Class;
      Stream  : in out Swagger.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type);

   procedure Get_Project_Schields_Status
     (Req     : in out Swagger.Servers.Request'Class;
      Reply   : in out Swagger.Servers.Response'Class;
      Stream  : in out Swagger.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type);

   package API_Get_Build_Log is
     new Porion.Projects.Operation (Handler => Get_Build_Log,
                                    Method  => Swagger.Servers.GET,
                                    URI     => "/api/v1/builds/{buildId}/logs");

   package API_Jenkins_Get_Last_Completed_Build is
     new Porion.Projects.Operation (Handler => Jenkins_Get_Last_Completed_Build,
                                    Method  => Swagger.Servers.GET,
                                    URI     => "/api/v1/jenkins/{project}/lastCompletedBuild/api/json");

   package API_Get_Project_Schields_Status is
     new Porion.Projects.Operation (Handler => Get_Project_Schields_Status,
                                    Method  => Swagger.Servers.GET,
                                    URI     => "/api/v1/projects/{project}/badges/{mode}");

end Porion.Builds.Rest;
