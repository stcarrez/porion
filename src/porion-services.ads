-----------------------------------------------------------------------
--  porion-services -- Project information
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
with ADO.Statements;
with ADO.Queries;
with ADO.Sessions;
with ADO.Sessions.Factory;

with Porion.Nodes.Models;
with Porion.Projects.Models;
with Porion.Builds.Models;
with Porion.Resources;
package Porion.Services is

   Not_Found : exception;

   type Context_Type is tagged limited record
      Factory           : ADO.Sessions.Factory.Session_Factory;
      DB                : ADO.Sessions.Master_Session;
      Project           : Porion.Projects.Models.Project_Ref;
      Branch            : Porion.Projects.Models.Branch_Ref;
      Build             : Porion.Builds.Models.Build_Ref;
      Build_Node        : Porion.Nodes.Models.Node_Ref;
      Build_Config      : Porion.Builds.Models.Recipe_Ref;
      Dry_Run           : Boolean := False;
   end record;

   --  Returns True if the service is opened.
   function Is_Open (Service : in Context_Type) return Boolean;

   function Has_Project (Service : in Context_Type) return Boolean is
      (not Service.Project.Is_Null);


   --  Get the current project id.
   function Get_Project_Id (Service : in Context_Type) return ADO.Identifier;

   procedure Load_Project (Service : in out Context_Type;
                           Name    : in String);

   procedure Load (Service : in out Context_Type;
                   Ident   : in Porion.Projects.Ident_Type);

   procedure Open (Service  : in out Context_Type;
                   Resource : in Resources.Get_Resource_Access;
                   Schema   : in Resources.Content_Access);

   procedure Open (Service : in out Context_Type;
                   From    : in out Context_Type'Class);

   procedure Import (Service : in out Context_Type;
                     Path    : in String);

end Porion.Services;
