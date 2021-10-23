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
with Ada.Containers.Vectors;
with Util.Strings.Vectors;
with Util.Serialize.IO;
with ADO.Sessions;
with Porion.Configs;
with Porion.Builds.Models;
with Porion.Projects.Models;
with Porion.Services;
with Porion.Executors;
package Porion.Builds.Services is

   Invalid_Position : exception;

   type Build_Step is record
      Step   : Porion.Builds.Models.Recipe_Step_Ref;
      Config : Porion.Configs.Config_Type;
   end record;

   package Build_Step_Vectors is
     new Ada.Containers.Vectors (Index_Type   => Positive,
                                 Element_Type => Build_Step);
   subtype Build_Step_Vector is Build_Step_Vectors.Vector;
   subtype Build_Step_Cursor is Build_Step_Vectors.Cursor;

   type Build_Config is record
      Config : Porion.Builds.Models.Recipe_Ref;
      Steps  : Build_Step_Vector;
   end record;

   package Build_Config_Vectors is
     new Ada.Containers.Vectors (Index_Type   => Positive,
                                 Element_Type => Build_Config);
   subtype Build_Config_Vector is Build_Config_Vectors.Vector;
   subtype Build_Config_Cursor is Build_Config_Vectors.Cursor;

   subtype Context_Type is Porion.Services.Context_Type;

   procedure Build (Service     : in out Context_Type;
                    Executor    : in out Porion.Executors.Executor_Type'Class);

   procedure Build (Service     : in out Context_Type;
                    Recipe      : in Porion.Builds.Models.Recipe_Ref;
                    Executor    : in out Porion.Executors.Executor_Type'Class) with
     Pre => Service.Has_Project and Recipe.Is_Loaded;

   procedure Start_Build (Service     : in out Context_Type;
                          Recipe      : in Porion.Builds.Models.Recipe_Ref;
                          Executor    : in out Porion.Executors.Executor_Type'Class) with
     Pre => Service.Has_Project;

   --  Delete the build step at the given execution order.
   --  Raises Invalid_Position if the position is invalid.
   procedure Delete_Step (Service  : in out Context_Type;
                          Recipe   : in Porion.Builds.Models.Recipe_Ref;
                          Position : in Positive) with
     Pre => Service.Has_Project and Recipe.Is_Loaded;

   --  Insert the build step in the recipe at the given position.
   procedure Insert_Step (Service   : in out Context_Type;
                          Recipe    : in Porion.Builds.Models.Recipe_Ref;
                          Position  : in Natural;
                          Kind      : in Porion.Builds.Models.Builder_Type;
                          Step      : in Porion.Builds.Step_Type;
                          Arguments : in Util.Strings.Vectors.Vector) with
     Pre => Service.Has_Project and Recipe.Is_Loaded;

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class);

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Recipe  : in Porion.Builds.Models.Recipe_Ref;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class);

   procedure Update_Parameters (Service : in out Context_Type;
                                Step    : in out Builds.Models.Recipe_Step_Ref;
                                Config  : in out Porion.Configs.Config_Type);

   procedure Update (Service : in out Context_Type;
                     Config  : in out Build_Config);

   procedure Update (Service : in out Context_Type;
                     Configs : in out Build_Config_Vector);

   procedure Make_Recipes (Service  : in out Context_Type;
                           Branch   : in String;
                           Executor : in out Porion.Executors.Executor_Type'Class) with
     Pre => Service.Is_Open and Service.Has_Project;

   --  Load the recipes of a project according to the identification.
   procedure Load_Recipes (Service : in out Context_Type;
                           Ident   : in Porion.Projects.Ident_Type;
                           List    : in out Porion.Builds.Models.Recipe_Vector) with
     Pre => Service.Is_Open;

   procedure Copy_Recipe (Service  : in out Context_Type;
                          Project  : in String;
                          Branch   : in String;
                          Node     : in String;
                          Recipe   : in out Models.Recipe_Ref);

   procedure Guess (Service  : in out Context_Type;
                    Path     : in String;
                    Executor : in out Porion.Executors.Executor_Type'Class);

   procedure Find_Build_Configs (Service : in out Context_Type;
                                 Force   : in Boolean;
                                 List    : in out Porion.Builds.Models.Recipe_Vector);

   procedure Update_Branch_Config (Branch  : in Porion.Projects.Models.Branch_Ref;
                                   Status  : in Porion.Builds.Models.Config_Status_Type;
                                   Session : in out ADO.Sessions.Master_Session);

private

   function Get_Build_Directory (Service : in Context_Type) return String;

   procedure Build (Service     : in out Context_Type;
                    Steps       : in Build_Step_Vector;
                    Executor    : in out Porion.Executors.Executor_Type'Class);

   procedure Update_Build (Service : in out Context_Type;
                           Status  : in Builds.Models.Build_Status_Type);

   procedure Load_Environment (Service : in out Context_Type;
                               Recipe  : in Models.Recipe_Ref);

   procedure Load_Recipe (Service : in out Context_Type;
                          Recipe  : in Models.Recipe_Ref;
                          Steps   : in out Build_Step_Vector) with
     Pre => Service.Has_Project;

end Porion.Builds.Services;
