-----------------------------------------------------------------------
--  porion-services -- Project information
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
with ADO.Sessions;
with ADO.Sessions.Factory;

with Keystore.Files;

with Porion.Nodes.Models;
with Porion.Projects.Models;
with Porion.Builds.Models;
with Porion.Resources;
with Porion.Templates;
package Porion.Services is

   Not_Found : exception;

   Invalid_Workspace : exception;

   type Context_Type is tagged limited record
      Factory           : ADO.Sessions.Factory.Session_Factory;
      DB                : ADO.Sessions.Master_Session;
      Project           : Porion.Projects.Models.Project_Ref;
      Branch            : Porion.Projects.Models.Branch_Ref;
      Build             : Porion.Builds.Models.Build_Ref;
      Build_Node        : Porion.Nodes.Models.Node_Ref;
      Recipe            : Porion.Builds.Models.Recipe_Ref;
      Queue             : Porion.Builds.Models.Build_Queue_Ref;
      Ident             : Porion.Projects.Ident_Type;
      Dry_Run           : Boolean := False;
      Wallet            : Keystore.Files.Wallet_File;
      Templates         : Porion.Templates.Repository_Type;
   end record;

   --  Returns True if the service is opened.
   function Is_Open (Service : in Context_Type) return Boolean;

   function Has_Project (Service : in Context_Type) return Boolean is
      (not Service.Project.Is_Null);

   function Has_Branch (Service : in Context_Type) return Boolean is
      (not Service.Branch.Is_Null);

   function Has_Build (Service : in Context_Type) return Boolean is
      (not Service.Build.Is_Null);

   function Has_Recipe (Service : in Context_Type) return Boolean is
      (not Service.Recipe.Is_Null);

   function Has_Node (Service : in Context_Type) return Boolean is
      (not Service.Build_Node.Is_Null);

   --  Get the current project id.
   function Get_Project_Id (Service : in Context_Type) return ADO.Identifier;

   --  Get the project branch identification string in the form <project>#<branch>.
   function Get_Branch_Name (Service : in Context_Type) return String with
      Pre => Service.Has_Branch;

   --  Get the identification of the current recipe in the form <project>#<branc>~<recipe>.
   function Get_Recipe_Name (Service : in Context_Type) return String with
      Pre => Service.Has_Recipe;
   function Get_Recipe_Name (Service : in Context_Type;
                             Recipe  : in Porion.Builds.Models.Recipe_Ref'Class) return String with
      Pre => Service.Has_Project and not Recipe.Is_Null;

   function Get_Secret (Service : in out Context_Type;
                        Name    : in String) return String is
      (Service.Wallet.Get (Name));
   function Get_Secret (Service : in out Context_Type;
                        Name    : in String) return UString is
      (To_UString (Service.Wallet.Get (Name)));

   procedure Load_Project (Service : in out Context_Type;
                           Name    : in String);

   procedure Load (Service : in out Context_Type;
                   Ident   : in Porion.Projects.Ident_Type) with
      Pre  => Service.Is_Open and Porion.Projects.Is_Valid (Ident),
      Post => Service.Has_Project
         and (Service.Has_Branch = (Projects.Has_Branch (Ident)
                                    or Projects.Has_Recipe (Ident)
                                    or Projects.Has_Build (Ident)
                                    or Service.Has_Recipe))
         and (Service.Has_Build = Projects.Has_Build (Ident));

   procedure Open (Service  : in out Context_Type;
                   Resource : in Resources.Get_Resource_Access;
                   Schema   : in Resources.Content_Access);

   procedure Open (Service : in out Context_Type;
                   From    : in out Context_Type'Class);

   procedure Import (Service : in out Context_Type;
                     Path    : in String);

   --  Setup the directory to hold the database, configuration files
   --  and project space to checkout and build projects.
   procedure Setup (Service  : in out Context_Type;
                    Path     : in String;
                    Resource : in Resources.Get_Resource_Access;
                    Schema   : in Resources.Content_Access);

end Porion.Services;
