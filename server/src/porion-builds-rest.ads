-----------------------------------------------------------------------
--  porion-builds-beans -- Beans for module builds
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

with Servlet.REST.Operation;
with Security.Permissions;
with OpenAPI.Servers;
with Porion.Services;
with Porion.Projects.Operation;
package Porion.Builds.Rest is

   procedure Get_Build_Log
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type);

   procedure Get_Build_Tests
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type);

   procedure Jenkins_Get_Last_Completed_Build
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type);

   procedure Get_Project_Schields_Status
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type);

   procedure Get_Project_Tests_Builds
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type);

   procedure Get_Project_Tests
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type);

   procedure Get_Project_Coverage
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type);

   procedure Get_Node_Usage
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class);

   procedure Get_Global_Activity
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class);

   package API_Get_Build_Log is
     new Porion.Projects.Operation
        (Handler => Get_Build_Log,
         Method  => OpenAPI.Servers.GET,
         URI     => "/api/v1/builds/{buildId}/logs");

   package API_Get_Build_Tests is
     new Porion.Projects.Operation
        (Handler => Get_Build_Tests,
         Method  => OpenAPI.Servers.GET,
         URI     => "/api/v1/builds/{buildId}/tests");

   package API_Jenkins_Get_Last_Completed_Build is
     new Porion.Projects.Operation
        (Handler => Jenkins_Get_Last_Completed_Build,
         Method  => OpenAPI.Servers.GET,
         URI     => "/api/v1/jenkins/{project}/lastCompletedBuild/api/json");

   package API_Get_Project_Schields_Status is
     new Porion.Projects.Operation
        (Handler => Get_Project_Schields_Status,
         Method  => OpenAPI.Servers.GET,
         URI     => "/api/v1/projects/{project}/badges/{mode}");

   package API_Get_Project_Tests_Builds is
     new Porion.Projects.Operation
        (Handler => Get_Project_Tests_Builds,
         Method  => OpenAPI.Servers.GET,
         URI     => "/api/v1/projects/{project}/tests/builds");

   package API_Get_Project_Coverage is
     new Porion.Projects.Operation
        (Handler => Get_Project_Coverage,
         Method  => OpenAPI.Servers.GET,
         URI     => "/api/v1/projects/{project}/coverage");

   package API_Get_Project_Tests is
     new Porion.Projects.Operation
        (Handler => Get_Project_Tests,
         Method  => OpenAPI.Servers.GET,
         URI     => "/api/v1/projects/{project}/tests");

   package API_Get_Node_Usage is
     new Servlet.REST.Operation
        (Handler => Get_Node_Usage'Access,
         Method  => OpenAPI.Servers.GET,
         Permission => Security.Permissions.NONE,
         URI     => "/api/v1/nodes/{node}/usage");

   package API_Get_Global_Activity is
     new Servlet.REST.Operation
        (Handler => Get_Global_Activity'Access,
         Method  => OpenAPI.Servers.GET,
         Permission => Security.Permissions.NONE,
         URI     => "/api/v1/activity/global");

end Porion.Builds.Rest;
