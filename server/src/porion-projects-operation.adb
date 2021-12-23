-----------------------------------------------------------------------
--  porion-projects-operation -- Rest server operation on a project or build
--  Copyright (C) 2017, 2018, 2019, 2021 Stephane Carrez
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

with Servlet.Rest.Operation;
with Porion.Projects.Modules;
package body Porion.Projects.Operation is

   procedure Op (Req     : in out Swagger.Servers.Request'Class;
                 Reply   : in out Swagger.Servers.Response'Class;
                 Stream  : in out Swagger.Servers.Output_Stream'Class);

   procedure Op (Req     : in out Swagger.Servers.Request'Class;
                 Reply   : in out Swagger.Servers.Response'Class;
                 Stream  : in out Swagger.Servers.Output_Stream'Class) is
      Ctx      : Swagger.Servers.Context_Type;
      Prj_Ctx  : Porion.Services.Context_Type;
      Module   : constant Projects.Modules.Project_Module_Access := Modules.Get_Project_Module;
      Id       : constant String := Req.Get_Path_Parameter (1);
   begin
      Ctx.Initialize (Req, Reply, Stream);
      Prj_Ctx.Ident := Porion.Projects.Parse (Id);
      Prj_Ctx.DB := Module.Get_Master_Session;
      Prj_Ctx.Load (Prj_Ctx.Ident);
      Handler (Req, Reply, Stream, Prj_Ctx);

   exception
      when Porion.Projects.Invalid_Ident =>
         Ctx.Set_Error (404, "invalid identifier");

      when Porion.Services.Not_Found =>
         Ctx.Set_Error (404, "project not found");

      when others =>
         Ctx.Set_Error (500, "Internal server error");
   end Op;

   package API is new Servlet.Rest.Operation (Handler    => Op'Access,
                                              Method     => Method,
                                              URI        => URI,
                                              Permission => Permission);

   function Definition return Servlet.Rest.Descriptor_Access is
   begin
      return API.Definition;
   end Definition;

end Porion.Projects.Operation;
