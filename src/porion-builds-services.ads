-----------------------------------------------------------------------
--  porion-builds-services -- build service to manage builds
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
with Porion.Projects.Models;
with Porion.Sources;
with Porion.Builders;
with ADO.Statements;
with ADO.Queries;
with ADO.Sessions;
with Porion.Nodes.Models;
with Porion.Builds.Models;
with Porion.Services;
package Porion.Builds.Services is

   type Context_Type is limited new Porion.Services.Context_Type with private;

   procedure Build (Service     : in out Context_Type;
                    Branch_Name : in String;
                    Branch      : in Porion.Sources.Branch_Type);

   procedure Start_Build (Service     : in out Context_Type;
                          Branch_Name : in String;
                          Branch      : in Porion.Sources.Branch_Type);

   function Get_Build (Service : in Context_Type) return Porion.Builds.Models.Build_Ref;

private

   type Context_Type is limited new Porion.Services.Context_Type with record
      --  Build_Config      : Porion.Builds.Models.Build_Config_Ref;
      Source_Controller : Porion.Sources.Controller_Access;
      Build_Controller  : Porion.Builders.Controller_Access;
   end record;

end Porion.Builds.Services;
