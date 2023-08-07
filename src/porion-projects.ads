-----------------------------------------------------------------------
--  porion-projects -- Project information
--  Copyright (C) 2021, 2023 Stephane Carrez
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

with Porion.Configs;
package Porion.Projects is

   Invalid_Ident : exception;

   subtype Config_Type is Porion.Configs.Config_Type;

   --  Identify a project, branch, build recipe, build node and build number.
   type Ident_Type is record
      Name   : UString;
      Branch : UString;
      Recipe : UString;
      Node   : UString;
      Build  : Natural := 0;
   end record;

   --  Check if the identification is valid.
   function Is_Valid (Ident : in Ident_Type) return Boolean
      is (Length (Ident.Name) > 0);

   --  Check if the identification indicates a project branch.
   function Has_Branch (Ident : in Ident_Type) return Boolean
      is (Length (Ident.Name) > 0 and Length (Ident.Branch) > 0);

   --  Check if the identification indicates a project recipe.
   function Has_Recipe (Ident : in Ident_Type) return Boolean
      is (Length (Ident.Name) > 0 and Length (Ident.Recipe) > 0);

   --  Check if the identification indicates a build node.
   function Has_Node (Ident : in Ident_Type) return Boolean
      is (Length (Ident.Name) > 0 and Length (Ident.Node) > 0);

   --  Check if the identification indicates a build number.
   function Has_Build (Ident : in Ident_Type) return Boolean
      is (Length (Ident.Name) > 0 and Ident.Build > 0);

   --  Parse an identification string with the format:
   --   <project>[#<branch>][~<recipe>][@<node][:<build-number>]
   --  The following format is also recognized for URL compatibility and there must
   --  be at least one `recipe`, `node` or `build-number` component:
   --   <project>:<branch>{[~<recipe>][@<node][:<build-number>]}
   --  Raises the Invalid_Ident exception if the format is invalid.
   function Parse (Ident : in String) return Ident_Type with
      Post => Is_Valid (Parse'Result);

   --  Get a printable representation of the split identification string.
   function To_String (Ident : in Ident_Type) return String with
      Pre => Is_Valid (Ident);

   --  Returns true if the name can be used for a recipe name.
   function Is_Valid_Recipe (Name : in String) return Boolean;

   type Project_Type is record
      Name    : UString;
      Path    : UString;
      Sources : Config_Type;
      Builds  : Config_Type;
   end record;

   --  Load the project description.
   procedure Load_Project (Name    : in String;
                           Project : in out Project_Type);

end Porion.Projects;
