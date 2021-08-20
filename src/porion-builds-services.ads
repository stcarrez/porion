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
with Porion.Sources;
with Porion.Builders;
with Porion.Configs;
with Porion.Builds.Models;
with Porion.Services;
private with Util.Strings.Maps;
package Porion.Builds.Services is

   type Build_Step is record
      Step   : Porion.Builds.Models.Build_Step_Ref;
      Config : Porion.Configs.Config_Type;
   end record;

   package Build_Step_Vectors is
     new Ada.Containers.Vectors (Index_Type   => Positive,
                                 Element_Type => Build_Step);
   subtype Build_Step_Vector is Build_Step_Vectors.Vector;
   subtype Build_Step_Cursor is Build_Step_Vectors.Cursor;

   type Context_Type is limited new Porion.Services.Context_Type with private;

   procedure Build (Service     : in out Context_Type;
                    Branch_Name : in String;
                    Branch      : in Porion.Sources.Branch_Type) with
     Pre => Service.Has_Project;

   procedure Start_Build (Service     : in out Context_Type;
                          Branch_Name : in String;
                          Branch      : in Porion.Sources.Branch_Type) with
     Pre => Service.Has_Project;

   function Get_Build (Service : in Context_Type) return Porion.Builds.Models.Build_Ref;

   procedure Load_Config (Service : in out Context_Type) with
     Pre => Service.Has_Project;

   --  Delete the build step at the given execution order.
   procedure Delete_Step (Service  : in out Context_Type;
                          Position : in Natural) with
     Pre => Service.Has_Project;

   procedure Insert_Step (Service   : in out Context_Type;
                          Position  : in Natural;
                          Kind      : in Porion.Builds.Models.Builder_Type;
                          Arguments : in Util.Strings.Vectors.Vector) with
     Pre => Service.Has_Project;

private

   type Context_Type is limited new Porion.Services.Context_Type with record
      Source_Controller : Porion.Sources.Controller_Access;
      Build_Controller  : Porion.Builders.Controller_Access;
      Environments      : Util.Strings.Maps.Map;
      Steps             : Build_Step_Vector;
   end record;

   procedure Load_Environment (Service : in out Context_Type);

   procedure Load_Build_Steps (Service : in out Context_Type) with
     Pre => Service.Has_Project;

end Porion.Builds.Services;
