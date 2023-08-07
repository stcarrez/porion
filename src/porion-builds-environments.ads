-----------------------------------------------------------------------
--  porion-builds-environments -- Environment variables to execute build recipes
--  Copyright (C) 2023 Stephane Carrez
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
with Porion.Nodes;
with Porion.Builds.Models;
with Porion.Services;
private with Util.Strings.Maps;
package Porion.Builds.Environments is

   --  Prefix of environment variables stored in the keystore.
   SECRET_PREFIX : constant String := "env.";

   --  Holds the list of variables used for executing all steps of a recipe.
   --  Some variables are specific to a single step.  Variables are either
   --  made available through shell variable, environment variable or a temporary
   --  file.
   type Environment_Type is tagged limited private;

   --  Load the environment variable definitions to execute the recipe.
   procedure Load (Env     : in out Environment_Type;
                   Service : in out Porion.Services.Context_Type) with
     Pre => Service.Is_Open and Service.Has_Recipe;

   --  Prepare the environment to execute the given step number.
   procedure Prepare (Env  : in out Environment_Type;
                      Step : in Positive;
                      Node : in Porion.Nodes.Controller_Access);

   --  Cleanup after execution of all build steps.
   procedure Cleanup (Env  : in out Environment_Type;
                      Node : in Porion.Nodes.Controller_Access);

private

   type Variable_Type is record
      Var     : Porion.Builds.Models.Variable_Info;
      Content : UString;
   end record;

   package Variable_Vectors is
     new Ada.Containers.Vectors (Index_Type   => Positive,
                                 Element_Type => Variable_Type);

   type Environment_Type is tagged limited record
      Vars : Variable_Vectors.Vector;
      Step : Natural := 0;
      Env  : Util.Strings.Maps.Map;
   end record;

   procedure Prepare (Env  : in out Environment_Type;
                      Node : in Porion.Nodes.Controller_Access;
                      Var  : in Variable_Type);

end Porion.Builds.Environments;
