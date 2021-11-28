-----------------------------------------------------------------------
--  porion-commands-set -- Set command to configure a project, branch or recipe
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
with Util.Strings.Builders;
with Porion.Services;
with Porion.Projects.Services;
with Porion.Builds.Services;
package body Porion.Commands.Set is

   VAR_NAME         : constant String := "name";
   VAR_DESCRIPTION  : constant String := "description";
   VAR_STATUS       : constant String := "status";
   VAR_RATE_FACTOR  : constant String := "rate_factor";
   VAR_FILTER_RULES : constant String := "filter_rules";

   function Get_Name (Args : in Argument_List'Class;
                      Pos   :in Positive) return String is
      Arg     : constant String := Args.Get_Argument (Pos);
      Sep_Pos : constant Natural := Util.Strings.Index (Arg, '=');
   begin
      if Sep_Pos > 0 then
         return Arg (Arg'First .. Sep_Pos - 1);
      else
         return Arg;
      end if;
   end Get_Name;

   function Get_Value (Args : in Argument_List'Class;
                       Pos  : in Positive) return String is
      Arg     : constant String := Args.Get_Argument (Pos);
      Sep_Pos : constant Natural := Util.Strings.Index (Arg, '=');
      Val     : Util.Strings.Builders.Builder (256);
   begin
      if Sep_Pos > 0 then
         Util.Strings.Builders.Append (Val, Arg (Sep_Pos + 1 .. Arg'Last));
      end if;
      for I in Pos + 1 .. Args.Get_Count - 1 loop
         Util.Strings.Builders.Append (Val, Args.Get_Argument (I));
      end loop;
      return Util.Strings.Builders.To_Array (Val);
   end Get_Value;

   procedure Print_Help (Context : in out Context_Type;
                         Name    : in String;
                         Help    : in String) is
      Var_Name : String (1 .. 32) := (others => ' ');
   begin
      Var_Name (1 .. Name'Length) := Name;
      Context.Notice (Var_Name & Help);
   end Print_Help;

   procedure Set_Project (Command : in out Command_Type;
                          Args    : in Argument_List'Class;
                          Context : in out Context_Type) is
      Name     : constant String := Get_Name (Args, 2);
      Value    : constant String := Get_Value (Args, 2);
      Modified : Boolean;
   begin
      if Name = VAR_NAME then
         Porion.Projects.Services.Set_Name (Context.Project_Service, Value, Modified);
      elsif Name = VAR_DESCRIPTION then
         Porion.Projects.Services.Set_Description (Context.Project_Service, Value, Modified);
      elsif Name = VAR_STATUS then
         Porion.Projects.Services.Set_Status (Context.Project_Service, Value, Modified);
      elsif Name = VAR_RATE_FACTOR then
         if not Context.Project_Service.Has_Branch then
            Commands.Error (-("The 'rate_factor' can be set on a branch or a recipe"));
            return;
         end if;
         Porion.Projects.Services.Set_Rate_Factor (Context.Project_Service, Value, Modified);

      elsif Name = VAR_FILTER_RULES then
         if not Context.Project_Service.Has_Recipe then
            Commands.Error (-("The 'filter_rules' can be set on a recipe"));
            return;
         end if;
         Porion.Projects.Services.Set_Filter_Rules (Context.Project_Service, Value, Modified);

      else
         Commands.Error (-("Unknown configuration '{0}"), Name);
         return;
      end if;

      if Modified then
         Notice (Context, -("Value set to {0}"), Value);
      end if;

   exception
      when Porion.Projects.Services.Bad_Value =>
         Commands.Error (-("cannot set '{0}'' to '{1}'': invalid value"), Name, Value);

   end Set_Project;

   --  ------------------------------
   --  Set a project, branch or recipe variable.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);

      Count : constant Natural := Args.Get_Count;
   begin
      if Count = 0 then
         Porion.Commands.Error (-("missing project name and variable to set"));
         return;
      end if;

      Context.Open;

      declare
         Arg   : constant String := Args.Get_Argument (1);
         Ident : Porion.Projects.Ident_Type;
      begin
         Ident := Porion.Projects.Parse (Arg);
         Context.Project_Service.Load (Ident);
         if Count = 1 then
            Print_Help (Context, VAR_NAME, -("name of the project, recipe"));
            Print_Help (Context, VAR_DESCRIPTION, -("description of the project, branch, recipe"));
            Print_Help (Context, VAR_STATUS, -("enable or disable the project, branch, recipe"));
            if Porion.Projects.Has_Recipe (Ident) then
               Print_Help (Context, VAR_FILTER_RULES, -("recipe filtering rules for log reports"));
               Print_Help (Context, VAR_RATE_FACTOR, -("recipe rate factor"));

            elsif Porion.Projects.Has_Branch (Ident) then
               Print_Help (Context, VAR_RATE_FACTOR, -("branch rate factor"));

            end if;
            return;
         end if;

         Command.Set_Project (Args, Context);

      exception
         when Porion.Services.Not_Found =>
            Context.Error_Not_Found (Ident);

         when Porion.Projects.Invalid_Ident =>
            Commands.Error (-("invalid project or build identifier: {0}"), Arg);

      end;
   end Execute;

   --  ------------------------------
   --  Setup the command before parsing the arguments and executing it.
   --  ------------------------------
   overriding
   procedure Setup (Command : in out Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Context_Type) is
   begin
      Drivers.Command_Type (Command).Setup (Config, Context);
   end Setup;

end Porion.Commands.Set;
