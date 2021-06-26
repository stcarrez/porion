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
with Util.Properties;
with Util.Strings.Vectors;
with EL.Expressions;
with Porion.Configs;
with Porion.Projects.Models;
with Porion.Sources;
with Porion.Builders;
with Ado.Statements;
with Ado.Queries;
private with ADO.Sessions.Factory;
package Porion.Projects.Services is

   Name_Used : exception;

   type Context_Type is tagged limited private;

   function Make_Project_Name (URI : in String) return String;

   procedure Add_Project (Service   : in out Context_Type;
                          Name      : in String;
                          Mode      : in String;
                          Parameter : in String);

   procedure Load_Project (Service : in out Context_Type;
                           Name    : in String);

   procedure Check_Sources (Service : in out Context_Type;
                            Status  : in out Porion.Sources.Status_Type);

   procedure Build (Service     : in out Context_Type;
                    Branch_Name : in String;
                    Branch      : in Porion.Sources.Branch_Type);

   procedure Load (Service : in out Context_Type;
                   Path : in String);

   procedure Open (Service : in out Context_Type);

   function Create_Query (Service : in out Context_Type;
                          Query   : in ADO.Queries.Context) return Ado.Statements.Query_Statement;
 
private

   type Context_Type is tagged limited record
      Factory           : ADO.Sessions.Factory.Session_Factory;
      DB                : ADO.Sessions.Master_Session;
      Project           : Porion.Projects.Models.Project_Ref;
      Branch            : Porion.Projects.Models.Branch_Ref;
      Build             : Porion.Projects.Models.Build_Ref;
      Source_Controller : Porion.Sources.Controller_Access;
      Build_Controller  : Porion.Builders.Controller_Access;
   end record;

end Porion.Projects.Services;
