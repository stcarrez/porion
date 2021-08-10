-----------------------------------------------------------------------
--  porion-projects -- Project information
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
private with ADO.Sessions.Factory;
package Porion.Projects.Services is

   Name_Used : exception;

   type Context_Type is tagged limited private;

   function Make_Project_Name (URI : in String) return String;

   --  Add a build node
   procedure Add_Node (Service   : in out Context_Type;
                       Hostname  : in String;
                       Login     : in String);

   --  Load the build node corresponding to the given hostname.
   procedure Load_Node (Service  : in out Context_Type;
                        Hostname : in String);

   procedure Add_Project (Service   : in out Context_Type;
                          Info      : in Porion.Sources.Source_Info_Type);

   --  Get the current project id.
   function Get_Project_Id (Service : in Context_Type) return ADO.Identifier;

   procedure Load_Project (Service : in out Context_Type;
                           Name    : in String);

   procedure Check_Sources (Service : in out Context_Type;
                            Status  : in out Porion.Sources.Status_Type);

   procedure Build (Service     : in out Context_Type;
                    Branch_Name : in String;
                    Branch      : in Porion.Sources.Branch_Type);

   procedure Start_Build (Service     : in out Context_Type;
                          Branch_Name : in String;
                          Branch      : in Porion.Sources.Branch_Type);

   procedure Load (Service : in out Context_Type;
                   Path : in String);

   procedure Open (Service : in out Context_Type;
                   Create  : in Boolean := False);

   function Create_Query (Service : in out Context_Type;
                          Query   : in ADO.Queries.Context) return Ado.Statements.Query_Statement;

   function Get_Database (Service : in Context_Type) return ADO.Sessions.Master_Session;

   function Get_Build (Service : in Context_Type) return Porion.Builds.Models.Build_Ref;

private

   type Context_Type is tagged limited record
      Factory           : ADO.Sessions.Factory.Session_Factory;
      DB                : ADO.Sessions.Master_Session;
      Project           : Porion.Projects.Models.Project_Ref;
      Branch            : Porion.Projects.Models.Branch_Ref;
      Build             : Porion.Builds.Models.Build_Ref;
      Build_Config      : Porion.Builds.Models.Build_Config_Ref;
      Build_Node        : Porion.Nodes.Models.Node_Ref;
      Source_Controller : Porion.Sources.Controller_Access;
      Build_Controller  : Porion.Builders.Controller_Access;
   end record;

end Porion.Projects.Services;
