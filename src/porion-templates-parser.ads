-----------------------------------------------------------------------
--  porion-templates-parser -- Parser for porion build template syntax
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
with Ada.Strings.Unbounded;
private with Util.Concurrent.Counters;
private with Util.Strings.Vectors;
private with Util.Log.Locations;
private with Ada.Finalization;
package Porion.Templates.Parser is

   procedure Load (Path       : in String;
                   Repository : in out Repository_Type);

   --  The parser token or expression.
   type YYSType is private;

   --  Return a printable representation of the parser token value.
   function To_String (Val : in YYSType) return String;

   --  Empty token.
   EMPTY : constant YYSType;

private

   type Time_Unit_Type is (UNIT_MS, UNIT_SEC, UNIT_MINUTE, UNIT_HOUR);

   type Node_Type is (TYPE_NULL, TYPE_IDENT, TYPE_STRING, TYPE_TIMEOUT, TYPE_RULE,
                      TYPE_WITH, TYPE_STEP,
                      TYPE_RENAMES,
                      TYPE_METRIC,
                      TYPE_RUN,
                      TYPE_XUNIT,
                      TYPE_VARIABLE,
                      TYPE_NAMES);

   --  Set the parser token with a string.
   --  The line and column number are recorded in the token.
   procedure Set_String (Into   : in out YYSType;
                         Value  : in String;
                         Line   : in Natural;
                         Column : in Natural);

   --  Append the token as a string.
   procedure Append_String (Into   : in out YYSType;
                            Value  : in YYSType) with
     Pre => Into.Kind = TYPE_STRING;

   procedure Append_String (Into   : in out YYSType;
                            Value  : in String) with
     Pre => Into.Kind = TYPE_STRING;

   --  Set the parser token with a string that represent an identifier.
   --  The line and column number are recorded in the token.
   procedure Set_Ident (Into   : in out YYSType;
                        Value  : in String;
                        Line   : in Natural;
                        Column : in Natural);

   --  Set the parser token with an number value with an optional unit or dimension.
   --  The line and column number are recorded in the token.
   procedure Set_Number (Into   : in out YYSType;
                         Value  : in String;
                         Unit   : in Time_Unit_Type;
                         Line   : in Natural;
                         Column : in Natural);

   procedure Set_Value (Into     : in out YYSType;
                        Value    : in YYSType);

   procedure Set_Options (Into   : in out YYSType;
                          First  : in YYSType;
                          Second : in YYSType);

   procedure Set_Names (Into   : in out YYSType;
                        First  : in YYSType;
                        Second : in YYSType);

   type Parser_Node_Type;
   type Parser_Node_Access is access all Parser_Node_Type;
   type Parser_Node_Type (Kind : Node_Type) is limited record
      Ref_Counter : Util.Concurrent.Counters.Counter;
      case Kind is
         when TYPE_STRING | TYPE_IDENT | TYPE_WITH =>
            Str_Value : Ada.Strings.Unbounded.Unbounded_String;

         when TYPE_TIMEOUT =>
            Timeout : Natural := 0;

         when TYPE_RULE =>
            Rule : Natural := 0;

         when TYPE_NAMES =>
            Names : Util.Strings.Vectors.Vector;

         when TYPE_STEP =>
            Step  : Step_Refs.Ref;

         when others =>
            null;

      end case;
   end record;

   function To_String (Val : in Parser_Node_Access) return String;

   type Parser_Context_Type is limited record
      File      : Util.Log.Locations.File_Info_Access;
      Template  : Template_Refs.Ref;
      Recipe    : Recipe_Refs.Ref;
      Step      : Step_Refs.Ref;
      Ignore    : Util.Nullables.Nullable_Boolean;
      Timeout   : Util.Nullables.Nullable_Integer;
   end record;

   procedure Finish_Template (Repository : in out Repository_Type;
                              Template   : in Template_Refs.Ref) with
     Pre => not Template.Is_Null;

   --  Create a template instance with the given name and that could
   --  extend an another template.
   procedure Create_Template (Repository : in out Repository_Type;
                              Context    : in out Parser_Context_Type;
                              Name       : in YYSType;
                              Extends    : in YYSType);

   --  Create a recipe instance with the given name and that could
   --  extend an another recipe.
   procedure Create_Recipe (Context    : in out Parser_Context_Type;
                            Name       : in YYSType;
                            Extends    : in YYSType);

   --  Create a ste[ instance with the given name and that could
   --  extend an another step.
   procedure Create_Step (Context    : in out Parser_Context_Type;
                          Name       : in YYSType;
                          Extends    : in YYSType);

   procedure Delete_Recipe (Context : in out Parser_Context_Type;
                            Name    : in YYSType);

   procedure Set_Config (Context : in out Parser_Context_Type;
                         Name    : in YYSType;
                         Value   : in YYSType);

   procedure Add_Variable (Context  : in out Parser_Context_Type;
                           Name     : in YYSType;
                           Of_Type  : in YYSType;
                           Secret   : in Boolean;
                           Value    : in YYSType);

   procedure Add_With (Repository : in out Repository_Type;
                       Context    : in out Parser_Context_Type;
                       Value      : in YYSType);

   procedure Add_Step (Context : in out Parser_Context_Type;
                       Kind    : in YYSType;
                       Content : in YYSType);

   procedure Add_Step (Context : in out Parser_Context_Type;
                       Kind    : in Porion.Builds.Step_Type;
                       Content : in YYSType);

   procedure Finish_Template (Context : in out Parser_Context_Type;
                              Name    : in YYSType);

   procedure Finish_Step (Context : in out Parser_Context_Type;
                          Name    : in YYSType);

   procedure Finish_Recipe (Context : in out Parser_Context_Type;
                            Name    : in YYSType);

   procedure Set_Type (Into   : in out YYSType;
                       Kind   : in Node_Type;
                       Line   : in Natural;
                       Column : in Natural);

   type YYSType is new Ada.Finalization.Controlled with record
      Line     : Natural    := 0;
      Column   : Natural    := 0;
      Kind     : Node_Type := TYPE_NULL;
      Node     : Parser_Node_Access;
   end record;

   overriding
   procedure Adjust (Object : in out YYSType);

   overriding
   procedure Finalize (Object : in out YYSType);

   function Get_UString (Node : in YYSType) return UString is
     (if Node.Kind in TYPE_IDENT | TYPE_STRING | TYPE_WITH
      then Node.Node.Str_Value else To_UString (""));

   function Get_String (Node : in YYSType) return String is
     (if Node.Kind in TYPE_IDENT | TYPE_STRING | TYPE_WITH
      then To_String (Node.Node.Str_Value) else "");

   function Get_Location (Context : in Parser_Context_Type;
                          Item    : in YYSType) return Location_Type is
     (Util.Log.Locations.Create_Line_Info (Context.File, Item.Line, Item.Column));

   function Get_Location (Context : in Parser_Context_Type;
                          Line    : in Natural;
                          Column  : in Natural) return Location_Type is
     (Util.Log.Locations.Create_Line_Info (Context.File, Line, Column));

   procedure Error (Context : in out Parser_Context_Type;
                    Line    : in Natural;
                    Column  : in Natural;
                    Message : in String);

   procedure Error (Context : in out Parser_Context_Type;
                    Place   : in YYSType;
                    Message : in String);

   procedure Error (Context : in out Parser_Context_Type;
                    Place   : in YYSType;
                    Message : in String;
                    Arg1    : in UString);

   procedure Error (Context : in out Parser_Context_Type;
                    Place   : in YYSType;
                    Message : in String;
                    Object  : in YYSType);

   procedure Error (Line    : in Natural;
                    Column  : in Natural;
                    Message : in String);

   procedure Warning (Line    : in Natural;
                      Column  : in Natural;
                      Message : in String);

   EMPTY : constant YYSType := YYSType '(Ada.Finalization.Controlled with
                                         Line => 0, Column => 0,
                                         Kind => TYPE_NULL,
                                         Node => null);

end Porion.Templates.Parser;
