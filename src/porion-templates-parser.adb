-----------------------------------------------------------------------
--  porion-templates-parser -- Parser for porion build template syntax
--  Copyright (C) 2022 Stephane Carrez
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
with Ada.Characters.Handling;
with Ada.Text_IO;
with Ada.Directories;
with Util.Strings.Formats;
with Util.Log.Loggers;
with Porion.Templates.Parser.Parser;
with Porion.Templates.Parser.Parser_Tokens;
package body Porion.Templates.Parser is

   use Ada.Strings.Unbounded;
   use Ada.Characters.Handling;
   use Util.Concurrent.Counters;

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Parser");

   procedure Load (Path       : in String;
                   Repository : in out Repository_Type) is
      Result  : Integer;
      Context : Parser_Context_Type;
   begin
      Log.Info ("Loading template {0}", Path);

      Context.File := Util.Log.Locations.Create_File_Info (Path, Path'First);
      begin
         Porion.Templates.Parser.Parser.Parse (Path, Repository, Context, Result);

      exception
         when Parser_Tokens.Syntax_Error =>
            Result := -1;
            Log.Error ("syntax error while parsing template {0}", Path);
      end;

      if Result = 0 then
         Finish_Template (Repository, Context.Template);
         Repository.Templates.Insert (To_UString (Path), Context.Template);
      end if;
   end Load;

   procedure Finish_Template (Repository : in out Repository_Type;
                              Template   : in Template_Refs.Ref) is
      Name : constant UString := To_UString (To_Lower (To_String (Template.Value.Name)));
   begin
      if not Repository.Templates.Contains (Name) then
         Repository.Templates.Insert (Name, Template);
      end if;
   end Finish_Template;

   function To_String (Val : in Parser_Node_Access) return String is
   begin
      if Val = null then
         return "null";
      end if;
      case Val.Kind is
         when TYPE_STRING | TYPE_IDENT | TYPE_WITH =>
            return Ada.Strings.Unbounded.To_String (Val.Str_Value);

         when TYPE_TIMEOUT =>
            return Natural'Image (Val.Timeout);

         when TYPE_NAMES =>
            return "Names";

         when TYPE_RULE =>
            return "Rule";

         when TYPE_STEP =>
            return "Step";

         when others =>
            return "";

      end case;
   end To_String;

   --  ------------------------------
   --  Return a printable representation of the parse value.
   --  ------------------------------
   function To_String (Val : in YYSType) return String is
   begin
      case Val.Kind is
         when TYPE_NULL =>
            return "null";

         when TYPE_STRING | TYPE_IDENT | TYPE_TIMEOUT | TYPE_NAMES | TYPE_STEP | TYPE_RULE =>
            return To_String (Val.Node);

         when others =>
            return "?";

      end case;
   end To_String;

   procedure Set_Type (Into   : in out YYSType;
                       Kind   : in Node_Type;
                       Line   : in Natural;
                       Column : in Natural) is
      procedure Free is
         new Ada.Unchecked_Deallocation (Parser_Node_Type, Parser_Node_Access);

      Release : Boolean;
   begin
      if Into.Node /= null then
         Util.Concurrent.Counters.Decrement (Into.Node.Ref_Counter, Release);
         if Release then
            Free (Into.Node);
         else
            Into.Node := null;
         end if;
      end if;
      Into.Kind   := Kind;
      Into.Line   := Line;
      Into.Column := Column;
   end Set_Type;

   --  ------------------------------
   --  Set the parser token with a string that represent an identifier.
   --  The line and column number are recorded in the token.
   --  ------------------------------
   procedure Set_Ident (Into   : in out YYSType;
                        Value  : in String;
                        Line   : in Natural;
                        Column : in Natural) is
   begin
      Set_Type (Into, TYPE_IDENT, Line, Column);
      Into.Node := new Parser_Node_Type '(Kind        => TYPE_IDENT,
                                          Ref_Counter => ONE,
                                          others      => <>);
      Ada.Strings.Unbounded.Set_Unbounded_String (Into.Node.Str_Value, Value);
   end Set_Ident;

   --  ------------------------------
   --  Set the parser token with a string.
   --  The line and column number are recorded in the token.
   --  ------------------------------
   procedure Set_String (Into   : in out YYSType;
                         Value  : in String;
                         Line   : in Natural;
                         Column : in Natural) is
   begin
      Set_Type (Into, TYPE_STRING, Line, Column);
      Into.Node := new Parser_Node_Type '(Kind        => TYPE_STRING,
                                          Ref_Counter => ONE,
                                          others      => <>);
      Ada.Strings.Unbounded.Set_Unbounded_String (Into.Node.Str_Value,
                                                  Value (Value'First + 1 .. Value'Last - 1));
   end Set_String;

   function Is_Digit (C : in Character) return Boolean
     is (C >= '0' and then C <= '9');

   --  ------------------------------
   --  Set the parser token with an number value with an optional unit or dimension.
   --  The line and column number are recorded in the token.
   --  ------------------------------
   procedure Set_Number (Into   : in out YYSType;
                         Value  : in String;
                         Unit   : in Time_Unit_Type;
                         Line   : in Natural;
                         Column : in Natural) is
      Last : Positive := Value'Last;
   begin
      while Last > Value'First and then not Is_Digit (Value (Last)) loop
         Last := Last - 1;
      end loop;
      Set_Type (Into, TYPE_IDENT, Line, Column);
      Into.Kind := TYPE_TIMEOUT;
      Into.Node := new Parser_Node_Type '(Kind        => TYPE_TIMEOUT,
                                          Ref_Counter => ONE,
                                          others      => <>);
      Into.Node.Timeout := Natural'Value (Value (Value'First .. Last));
      case Unit is
         when UNIT_MS =>
            null;
         when UNIT_SEC =>
            Into.Node.Timeout := Into.Node.Timeout * 1000;
         when UNIT_MINUTE =>
            Into.Node.Timeout := Into.Node.Timeout * 1000 * 60;
         when UNIT_HOUR =>
            Into.Node.Timeout := Into.Node.Timeout * 1000 * 3600;
      end case;
   end Set_Number;

   --  ------------------------------
   --  Append the token as a string.
   --  ------------------------------
   procedure Append_String (Into   : in out YYSType;
                            Value  : in YYSType) is
   begin
      Append (Into.Node.Str_Value, Get_String (Value));
   end Append_String;

   procedure Append_String (Into   : in out YYSType;
                            Value  : in String) is
   begin
      Append (Into.Node.Str_Value, Value);
   end Append_String;

   procedure Delete_Recipe (Context : in out Parser_Context_Type;
                            Name    : in YYSType) is
   begin
      Log.Error ("Delete recipe {0}", To_String (Name));
   end Delete_Recipe;

   procedure Add_Variable (Context  : in out Parser_Context_Type;
                           Name     : in YYSType;
                           Of_Type  : in YYSType;
                           Secret   : in Boolean;
                           Value    : in YYSType) is
      Var_Name : constant UString := Get_UString (Name);
      Var      : constant Variable_Refs.Ref := Variable_Refs.Create;
   begin
      Log.Debug ("Add variable {0} type {1}", Var_Name,
                 To_String (Of_Type));

      Var.Value.Name := Var_Name;
      Var.Value.Loc := Get_Location (Context, Name);
      if Value.Kind in TYPE_STRING | TYPE_IDENT then
         Var.Value.Value := Get_UString (Value);
      end if;

      if not Context.Step.Is_Null then
         Context.Step.Value.Vars.Append (Var);
      elsif not Context.Recipe.Is_Null then
         Context.Recipe.Value.Vars.Append (Var);
      elsif not Context.Template.Is_Null then
         Context.Template.Value.Vars.Append (Var);
      else
         Error (Context, Name, "variable '{0}' ignored due to invalid context",
                Var_Name);
      end if;
   end Add_Variable;

   procedure Set_Value (Into     : in out YYSType;
                        Value    : in YYSType) is
   begin
      Set_Type (Into, TYPE_NULL, Value.Line, Value.Column);
      Into.Node := new Parser_Node_Type '(Kind        => TYPE_NULL,
                                          Ref_Counter => ONE);
      --  Into.Node.V := Create_Value (Document, Value);
   end Set_Value;

   procedure Set_Options (Into   : in out YYSType;
                          First  : in YYSType;
                          Second : in YYSType) is
   begin
      if First.Kind = TYPE_NAMES then
         Into := First;
      else
         Set_Type (Into, TYPE_NAMES, First.Line, First.Column);
         Into.Node := new Parser_Node_Type '(Kind        => TYPE_NAMES,
                                             Ref_Counter => ONE,
                                             others      => <>);
         Into.Node.Names.Append (To_String (First.Node.Str_Value));
      end if;
      Into.Node.Names.Append (To_String (Second.Node.Str_Value));
   end Set_Options;

   procedure Set_Names (Into   : in out YYSType;
                        First  : in YYSType;
                        Second : in YYSType) is
   begin
      if First.Kind = TYPE_NAMES then
         Into := First;
      else
         Set_Type (Into, TYPE_NAMES, First.Line, First.Column);
         Into.Node := new Parser_Node_Type '(Kind        => TYPE_NAMES,
                                             Ref_Counter => ONE,
                                             others      => <>);
         if First.Kind in TYPE_STRING | TYPE_IDENT then
            Into.Node.Names.Append (To_String (First.Node.Str_Value));
         end if;
      end if;
      Into.Node.Names.Append (To_String (Second.Node.Str_Value));
   end Set_Names;

   procedure Add_With (Repository : in out Repository_Type;
                       Context    : in out Parser_Context_Type;
                       Value      : in YYSType) is
      With_Name : constant UString := Get_UString (Value);
      Path      : constant String
        := Get_Template_Path (Repository, To_String (With_Name));
   begin
      Log.Debug ("Add with {0}", With_Name);

      if Path'Length = 0 or else not Ada.Directories.Exists (Path) then
         Error (Context, Value, "template '{0}' not found", With_Name);
         return;
      end if;

      declare
         Name : constant UString := To_UString (To_Lower (To_String (With_Name)));
         Pos  : constant Template_Maps.Cursor := Repository.Templates.Find (Name);
      begin
         if Template_Maps.Has_Element (Pos) then
            --  Error (Context, Value, "circular with '{0}' clause", With_Name);
            return;
         end if;
         Load (Path, Repository);
      end;
   end Add_With;

   procedure Error (Context : in out Parser_Context_Type;
                    Line    : in Natural;
                    Column  : in Natural;
                    Message : in String) is
      Loc : constant Location_Type := Get_Location (Context, Line, Column);
      L   : constant String := Util.Log.Locations.To_String (Loc);
   begin
      Ada.Text_IO.Put_Line (L & ": error: " & Message);
   end Error;

   procedure Error (Context : in out Parser_Context_Type;
                    Place   : in YYSType;
                    Message : in String) is
      Loc : constant Location_Type := Get_Location (Context, Place);
      L   : constant String := Util.Log.Locations.To_String (Loc);
   begin
      Ada.Text_IO.Put_Line (L & ": error: " & Message);
   end Error;

   procedure Error (Context : in out Parser_Context_Type;
                    Place   : in YYSType;
                    Message : in String;
                    Arg1    : in UString) is
   begin
      Error (Context, Place, Util.Strings.Formats.Format (Message, To_String (Arg1)));
   end Error;

   procedure Error (Context : in out Parser_Context_Type;
                    Place   : in YYSType;
                    Message : in String;
                    Object  : in YYSType) is
      Loc : constant Location_Type := Get_Location (Context, Place);
      L   : constant String := Util.Log.Locations.To_String (Loc);
      Val : constant String := Get_String (Object);
   begin
      Ada.Text_IO.Put_Line (L & ": error: " & Message & "'" & Val & "'");
   end Error;

   procedure Error (Line    : in Natural;
                    Column  : in Natural;
                    Message : in String) is
   begin
      Log.Error ("{0}:{1}: {2}", Natural'Image (Line),
                 Natural'Image (Column), Message);
      --  Report_Handler.Error (Loc, Message);
   end Error;

   procedure Warning (Line    : in Natural;
                      Column  : in Natural;
                      Message : in String) is
   begin
      Log.Warn ("{0}:{1}: {2}", Natural'Image (Line),
                Natural'Image (Column), Message);
   end Warning;

   overriding
   procedure Adjust (Object : in out YYSType) is
   begin
      if Object.Node /= null then
         Util.Concurrent.Counters.Increment (Object.Node.Ref_Counter);
      end if;
   end Adjust;

   overriding
   procedure Finalize (Object : in out YYSType) is
   begin
      Set_Type (Object, TYPE_NULL, 0, 0);
   end Finalize;

   --  ------------------------------
   --  Create a template instance with the given name and that could
   --  extend an another template.
   --  ------------------------------
   procedure Create_Template (Repository : in out Repository_Type;
                              Context    : in out Parser_Context_Type;
                              Name       : in YYSType;
                              Extends    : in YYSType) is
      Template_Name : constant UString := Get_UString (Name);
   begin
      Log.Debug ("Create template {0}", Template_Name);

      if Repository.Templates.Contains (Template_Name) then
         Error (Context, Name, "template '{0}' is already defined", Template_Name);
      end if;

      Context.Template := Template_Refs.Create;
      Context.Template.Value.Name := Template_Name;
      Context.Template.Value.Loc := Get_Location (Context, Name);
      if Extends.Kind in TYPE_STRING | TYPE_IDENT then
         Context.Template.Value.Extends := Get_UString (Extends);
      end if;
   end Create_Template;

   --  ------------------------------
   --  Create a recipe instance with the given name and that could
   --  extend an another recipe.
   --  ------------------------------
   procedure Create_Recipe (Context    : in out Parser_Context_Type;
                            Name       : in YYSType;
                            Extends    : in YYSType) is
      Recipe_Name : constant UString := Get_UString (Name);
   begin
      Log.Debug ("Create recipe {0}", Recipe_Name);

      Context.Recipe := Recipe_Refs.Create;
      Context.Recipe.Value.Name := Recipe_Name;
      Context.Recipe.Value.Loc := Get_Location (Context, Name);
      if Extends.Kind in TYPE_STRING | TYPE_IDENT then
         Context.Recipe.Value.Extends := Get_UString (Extends);
      end if;

      if not Context.Template.Is_Null then
         if Context.Template.Value.Recipes.Contains (Recipe_Name) then
            Error (Context, Name, "recipe '{0}' already declared", Recipe_Name);
         else
            Context.Template.Value.Recipes.Insert (Recipe_Name, Context.Recipe);
         end if;
      end if;
   end Create_Recipe;

   --  ------------------------------
   --  Create a ste[ instance with the given name and that could
   --  extend an another step.
   --  ------------------------------
   procedure Create_Step (Context    : in out Parser_Context_Type;
                          Name       : in YYSType;
                          Extends    : in YYSType) is
      Step_Name : constant UString := Get_UString (Name);
   begin
      Log.Debug ("Create step {0}", Step_Name);

      Context.Step := Step_Refs.Create;
      Context.Step.Value.Name := Step_Name;
      Context.Step.Value.Loc := Get_Location (Context, Name);
      if Extends.Kind in TYPE_STRING | TYPE_IDENT then
         Context.Step.Value.Extends := Get_UString (Extends);
      end if;

      if not Context.Template.Is_Null then
         if Context.Template.Value.Steps.Contains (Step_Name) then
            Error (Context, Name, "step '{0}' is already declared", Step_Name);
         else
            Context.Template.Value.Steps.Insert (Step_Name, Context.Step);
         end if;
      end if;
   end Create_Step;

   procedure Add_Step (Context : in out Parser_Context_Type;
                       Kind    : in YYSType;
                       Content : in YYSType) is
      Value : constant String := Get_String (Kind);
   begin
      if Value = "configure" then
         Add_Step (Context, Porion.Builds.STEP_CONFIGURE, Content);
      elsif Value = "publish" then
         Add_Step (Context, Porion.Builds.STEP_PUBLISH, Content);
      elsif Value = "setup" then
         Add_Step (Context, Porion.Builds.STEP_SETUP, Content);
      elsif Value = "generate" then
         Add_Step (Context, Porion.Builds.STEP_GENERATE, Content);
      elsif Value = "make" or else Value = "build" then
         Add_Step (Context, Porion.Builds.STEP_MAKE, Content);
      elsif Value = "package" then
         Add_Step (Context, Porion.Builds.STEP_PACKAGE, Content);
      elsif Value = "test" then
         Add_Step (Context, Porion.Builds.STEP_TEST, Content);
      elsif Value = "install" then
         Add_Step (Context, Porion.Builds.STEP_INSTALL, Content);
      else
         Error (Context, Kind, "unknown step role '{0}'", To_UString (Value));
         Add_Step (Context, Porion.Builds.STEP_MAKE, Content);
      end if;
   end Add_Step;

   procedure Add_Step (Context : in out Parser_Context_Type;
                       Kind    : in Porion.Builds.Step_Type;
                       Content : in YYSType) is
      Action : Step_Action;
   begin
      Log.Debug ("Add step {0} - {1}", Kind'Image, To_String (Content));

      Action.Ignore := Context.Ignore;
      Action.Timeout := Context.Timeout;
      Action.Kind := Kind;
      if Content.Kind = TYPE_NAMES then
         Action.Arg1 := Content.Node.Names;
      else
         Action.Arg1.Append (Get_String (Content));
      end if;
      if not Context.Step.Is_Null then
         Context.Step.Value.Actions.Append (Action);
      end if;
   end Add_Step;

   procedure Set_Config (Context : in out Parser_Context_Type;
                         Name    : in YYSType;
                         Value   : in YYSType) is
      Config : constant String := To_Lower (Get_String (Name));
   begin
      Log.Debug ("Set config {0} = {1}", Config, To_String (Value));

      if Config = "ignore" then
         null;
      elsif Config = "timeout" then
         Context.Timeout.Is_Null := False;
         Context.Timeout.Value := Value.Node.Timeout;
      elsif Config = "filtering" and then not Context.Recipe.Is_Null then
         Context.Recipe.Value.Filtering := Value.Node.Str_Value;
      else
         Error (Context, Name, "unkown configuration: '{0}'", Get_UString (Name));
      end if;
   end Set_Config;

   procedure Finish_Template (Context : in out Parser_Context_Type;
                            Name    : in YYSType) is
      Template_Name : constant String := To_String (Name.Node.Str_Value);
   begin
      Log.Debug ("Finish template {0}", Template_Name);

      if not Context.Template.Is_Null and then Context.Template.Value.Name /= Template_Name then
         Error (Context, Name,
                Message => "expecting template name '{0}'",
                Arg1    => Context.Template.Value.Name);
      end if;
   end Finish_Template;

   procedure Finish_Step (Context : in out Parser_Context_Type;
                          Name    : in YYSType) is
      Step_Name : constant String := Get_String (Name);
   begin
      Log.Debug ("Finish step {0}", Step_Name);

      if Context.Step.Is_Null then
         return;
      end if;

      --  Context.Step.Value.Ignore := Context.Ignore;
      --  Context.Step.Value.Timeout := Context.Timeout;
      Context.Ignore := Util.Nullables.Null_Boolean;
      Context.Timeout := Util.Nullables.Null_Integer;

      if Context.Step.Value.Name /= Step_Name then
         Error (Context => Context,
                Place   => Name,
                Message => "expecting step name '{0}'",
                Arg1    => Context.Step.Value.Name);
      end if;
      Context.Step := Null_Step;
   end Finish_Step;

   procedure Finish_Recipe (Context : in out Parser_Context_Type;
                            Name    : in YYSType) is
      Recipe_Name : constant String := Get_String (Name);
   begin
      Log.Debug ("Finish recipe {0}", Recipe_Name);

      if not Context.Recipe.Is_Null and then Context.Recipe.Value.Name /= Recipe_Name then
         Error (Context,
                Place   => Name,
                Message => "expecting recipe name '{0}'",
                Arg1    => Context.Recipe.Value.Name);
      end if;
      Context.Recipe := Null_Recipe;
   end Finish_Recipe;

end Porion.Templates.Parser;
