-----------------------------------------------------------------------
--  porion-templates -- build template description
--  Copyright (C) 2022, 2023 Stephane Carrez
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
with Util.Refs;
with Util.Log.Locations;
with Util.Nullables;
with Util.Strings.Vectors;
with Ada.Containers.Vectors;
with Ada.Containers.Ordered_Maps;
with Porion.Builds;
package Porion.Templates is

   type Repository_Type is limited private;

   --  Set the search path to find and load templates.
   procedure Set_Search_Paths (Repository : in out Repository_Type;
                               Path       : in String);

   --  Get the template path for the given name and looking at the current
   --  search directories.
   function Get_Template_Path (Repository : in Repository_Type;
                               Name       : in String) return String;

private

   subtype Location_Type is Util.Log.Locations.Line_Info;

   type Variable_Kind is (VAR_DEFAULT,
                          VAR_SECRET,
                          VAR_SECRET_FILE,
                          VAR_SECRET_ENV);

   type Variable_Type is new Util.Refs.Ref_Entity with record
      Loc    : Location_Type;
      Kind   : Variable_Kind := VAR_DEFAULT;
      Name   : UString;
      Value  : UString;
   end record;
   type Variable_Access is access all Variable_Type;

   package Variable_Refs is
     new Util.Refs.References (Element_Type   => Variable_Type,
                               Element_Access => Variable_Access);

   function "=" (Left, Right : in Variable_Refs.Ref) return Boolean;

   package Variable_Vectors is
     new Ada.Containers.Vectors (Element_Type => Variable_Refs.Ref,
                                 Index_Type   => Positive);

   type Step_Action is record
      Kind    : Porion.Builds.Step_Type := Porion.Builds.STEP_MAKE;
      Ignore  : Util.Nullables.Nullable_Boolean;
      Timeout : Util.Nullables.Nullable_Integer;
      Arg1    : Util.Strings.Vectors.Vector;
      Arg2    : Util.Strings.Vectors.Vector;
   end record;

   package Step_Action_Vectors is
     new Ada.Containers.Vectors (Element_Type => Step_Action,
                                 Index_Type   => Positive);

   type Step_Type is new Util.Refs.Ref_Entity with record
      Loc     : Location_Type;
      Name    : UString;
      Extends : UString;
      Value   : UString;
      Vars    : Variable_Vectors.Vector;
      Actions : Step_Action_Vectors.Vector;
   end record;
   type Step_Access is access all Step_Type;

   package Step_Refs is
     new Util.Refs.References (Element_Type   => Step_Type,
                               Element_Access => Step_Access);

   function "=" (Left, Right : in Step_Refs.Ref) return Boolean;

   function Null_Step return Step_Refs.Ref;

   package Step_Vectors is
     new Ada.Containers.Vectors (Element_Type => Step_Refs.Ref,
                                 Index_Type   => Positive);

   package Step_Maps is
     new Ada.Containers.Ordered_Maps (Key_Type     => UString,
                                      Element_Type => Step_Refs.Ref,
                                      "<"          => Ada.Strings.Unbounded."<");

   type Recipe_Type is new Util.Refs.Ref_Entity with record
      Loc       : Location_Type;
      Name      : UString;
      Extends   : UString;
      Filtering : UString;
      Steps     : Step_Vectors.Vector;
      Vars      : Variable_Vectors.Vector;
   end record;
   type Recipe_Access is access all Recipe_Type;

   package Recipe_Refs is
     new Util.Refs.References (Element_Type   => Recipe_Type,
                               Element_Access => Recipe_Access);

   function Null_Recipe return Recipe_Refs.Ref;

   function "=" (Left, Right : in Recipe_Refs.Ref) return Boolean;

   package Recipe_Vectors is
     new Ada.Containers.Vectors (Element_Type => Recipe_Refs.Ref,
                                 Index_Type   => Positive);

   package Recipe_Maps is
     new Ada.Containers.Ordered_Maps (Key_Type     => UString,
                                      Element_Type => Recipe_Refs.Ref,
                                      "<"          => Ada.Strings.Unbounded."<");

   type Template_Type is new Util.Refs.Ref_Entity with record
      Loc     : Location_Type;
      File    : Util.Log.Locations.File_Info_Access;
      Name    : UString;
      Extends : UString;
      Withs   : Util.Strings.Vectors.Vector;
      Vars    : Variable_Vectors.Vector;
      Steps   : Step_Maps.Map;
      Recipes : Recipe_Maps.Map;
   end record;
   type Template_Access is access all Template_Type;

   overriding
   procedure Finalize (Template : in out Template_Type);

   package Template_Refs is
     new Util.Refs.References (Element_Type   => Template_Type,
                               Element_Access => Template_Access);

   function "=" (Left, Right : in Template_Refs.Ref) return Boolean;

   package Template_Maps is
     new Ada.Containers.Ordered_Maps (Key_Type     => UString,
                                      Element_Type => Template_Refs.Ref,
                                      "<"          => Ada.Strings.Unbounded."<");

   type Repository_Type is limited record
      Templates    : Template_Maps.Map;
      Search_Paths : UString;
   end record;

end Porion.Templates;
