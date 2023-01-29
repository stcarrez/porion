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
with Ada.Unchecked_Deallocation;
with Util.Files;
package body Porion.Templates is

   --  ------------------------------
   --  Set the search path to find and load templates.
   --  ------------------------------
   procedure Set_Search_Paths (Repository : in out Repository_Type;
                               Path       : in String) is
   begin
      Repository.Search_Paths := To_UString (Path);
   end Set_Search_Paths;

   --  ------------------------------
   --  Get the template path for the given name and looking at the current
   --  search directories.
   --  ------------------------------
   function Get_Template_Path (Repository : in Repository_Type;
                               Name       : in String) return String is
      Path     : constant String := To_String (Repository.Search_Paths);
      Filename : constant String := Name & ".porion";
   begin
      return Util.Files.Find_File_Path (Filename, Path, ':');
   end Get_Template_Path;

   function "=" (Left, Right : in Variable_Refs.Ref) return Boolean is
   begin
      if Left.Is_Null then
         return Right.Is_Null;
      elsif Right.Is_Null then
         return False;
      else
         declare
            Left_Var : constant Variable_Refs.Element_Accessor := Left.Value;
            Right_Var : constant Variable_Refs.Element_Accessor := Right.Value;
         begin
            return Left_Var.Element = Right_Var.Element;
         end;
      end if;
   end "=";

   function "=" (Left, Right : in Step_Refs.Ref) return Boolean is
   begin
      if Left.Is_Null then
         return Right.Is_Null;
      elsif Right.Is_Null then
         return False;
      else
         declare
            Left_Var : constant Step_Refs.Element_Accessor := Left.Value;
            Right_Var : constant Step_Refs.Element_Accessor := Right.Value;
         begin
            return Left_Var.Element = Right_Var.Element;
         end;
      end if;
   end "=";

   function Null_Step return Step_Refs.Ref is
      Null_Step_Instance : Step_Refs.Ref;
   begin
      return Null_Step_Instance;
   end Null_Step;

   function "=" (Left, Right : in Recipe_Refs.Ref) return Boolean is
   begin
      if Left.Is_Null then
         return Right.Is_Null;
      elsif Right.Is_Null then
         return False;
      else
         declare
            Left_Var : constant Recipe_Refs.Element_Accessor := Left.Value;
            Right_Var : constant Recipe_Refs.Element_Accessor := Right.Value;
         begin
            return Left_Var.Element = Right_Var.Element;
         end;
      end if;
   end "=";

   function Null_Recipe return Recipe_Refs.Ref is
      Null_Recipe_Instance : Recipe_Refs.Ref;
   begin
      return Null_Recipe_Instance;
   end Null_Recipe;

   function "=" (Left, Right : in Template_Refs.Ref) return Boolean is
   begin
      if Left.Is_Null then
         return Right.Is_Null;
      elsif Right.Is_Null then
         return False;
      else
         declare
            Left_Var : constant Template_Refs.Element_Accessor := Left.Value;
            Right_Var : constant Template_Refs.Element_Accessor := Right.Value;
         begin
            return Left_Var.Element = Right_Var.Element;
         end;
      end if;
   end "=";

   overriding
   procedure Finalize (Template : in out Template_Type) is
      procedure Free is
        new Ada.Unchecked_Deallocation (Util.Log.Locations.File_Info,
                                        Util.Log.Locations.File_Info_Access);
   begin
      Free (Template.File);
   end Finalize;

end Porion.Templates;
