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
with Porion.Sources;
with Porion.Builders;
with Porion.Configs;
with Porion.Builds.Models;
with Porion.Projects.Models;
with Porion.Services;
with Porion.Executors;
private with Util.Strings.Maps;
package Porion.Builds.Services is

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

   type Context_Type is limited new Porion.Services.Context_Type with private;

   procedure Build (Service     : in out Context_Type;
                    Recipe      : in Porion.Builds.Models.Recipe_Ref;
                    Executor    : in out Porion.Executors.Executor_Type'Class) with
     Pre => Service.Has_Project and Recipe.Is_Loaded;

   procedure Start_Build (Service     : in out Context_Type;
                          Recipe      : in Porion.Builds.Models.Recipe_Ref;
                          Executor    : in out Porion.Executors.Executor_Type'Class) with
     Pre => Service.Has_Project;

   function Get_Build (Service : in Context_Type) return Porion.Builds.Models.Build_Ref;

   procedure Load_Recipe (Service : in out Context_Type) with
     Pre => Service.Has_Project;

   --  Delete the build step at the given execution order.
   procedure Delete_Step (Service  : in out Context_Type;
                          Position : in Natural) with
     Pre => Service.Has_Project;

   procedure Insert_Step (Service   : in out Context_Type;
                          Position  : in Natural;
                          Kind      : in Porion.Builds.Models.Builder_Type;
                          Step      : in Porion.Builds.Step_Type;
                          Arguments : in Util.Strings.Vectors.Vector) with
     Pre => Service.Has_Project;

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

   procedure Make_Build_Config (Service  : in out Context_Type;
                                Branch   : in String;
                                Executor : in out Porion.Executors.Executor_Type'Class);

   procedure Copy_Recipe (Service  : in out Context_Type;
                          Branch   : in String;
                          Node     : in String);

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

   type Context_Type is limited new Porion.Services.Context_Type with record
      Source_Controller : Porion.Sources.Controller_Access;
      Build_Controller  : Porion.Builders.Controller_Access;
      Environments      : Util.Strings.Maps.Map;
      Steps             : Build_Step_Vector;
   end record;

   procedure Build (Service     : in out Context_Type;
                    Executor    : in out Porion.Executors.Executor_Type'Class);

   procedure Update_Build (Service : in out Context_Type;
                           Status  : in Builds.Models.Build_Status_Type);

   procedure Load_Environment (Service : in out Context_Type);

   procedure Load_Build_Steps (Service : in out Context_Type) with
     Pre => Service.Has_Project;

end Porion.Builds.Services;
