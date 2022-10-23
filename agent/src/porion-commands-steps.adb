-----------------------------------------------------------------------
--  porion-commands-steps -- Command to add, update remove build steps
--  Copyright (C) 2021, 2022 Stephane Carrez
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
with Util.Strings.Vectors;
with Porion.Sources;
with Porion.Services;
with Porion.Projects;
with Porion.Builds.Services;
package body Porion.Commands.Steps is

   use type Porion.Sources.Source_Control_Type;

   procedure Add_Step (Command : in out Command_Type;
                       Recipe  : in out Porion.Builds.Models.Recipe_Ref;
                       Args    : in Argument_List'Class;
                       Context : in out Context_Type) is
      First  : constant String := Args.Get_Argument (2);
      Kind   : Porion.Builds.Models.Builder_Type;
      Step   : Porion.Builds.Step_Type;
      Params : Util.Strings.Vectors.Vector;
      Pos    : Positive := 2;
   begin
      if First = "xunit" then
         Kind := Porion.Builds.Models.BUILDER_XUNIT;
         Step := Porion.Builds.STEP_TEST;
         Pos := 3;
      elsif First = "metric" then
         Kind := Porion.Builds.Models.BUILDER_METRIC;
         Step := Porion.Builds.STEP_METRIC;
         Pos := 3;
      else
         Kind := Porion.Builds.Models.BUILDER_SCRIPT;
         Step := Porion.Builds.STEP_MAKE;
      end if;
      while Pos <= Args.Get_Count loop
         Params.Append (Args.Get_Argument (Pos));
         Pos := Pos + 1;
      end loop;

      if Command.Insert_Pos > 0 then
         if Context.Project_Service.Project.Get_Scm = Porion.Sources.SRC_GIT then
            Command.Insert_Pos := Command.Insert_Pos - 1;
         end if;
         Command.Insert_Pos := Command.Insert_Pos - 1;
         if Command.Insert_Pos <= 0 then
            Porion.Commands.Error (-("cannot insert before or at the checkout commands"));
            return;
         end if;
      end if;
      Builds.Services.Insert_Step (Context.Project_Service, Recipe,
                                   Command.Insert_Pos, Kind, Step, Params);
   end Add_Step;

   procedure Update_Step (Command : in out Command_Type;
                          Recipe  : in out Porion.Builds.Models.Recipe_Ref;
                          Args    : in Argument_List'Class;
                          Context : in out Context_Type) is
      procedure Update (Step : in out Porion.Builds.Models.Recipe_Step_Ref);

      procedure Update (Step : in out Porion.Builds.Models.Recipe_Step_Ref) is
      begin
         if Command.Timeout > 0 then
            Step.Set_Timeout (Command.Timeout);
         end if;
         if Command.Disable then
            Step.Set_Execution (Porion.Builds.EXEC_DISABLED);
         elsif Command.Ignore_Error then
            Step.Set_Execution (Porion.Builds.EXEC_IGNORE_ERROR);
         end if;
      end Update;

   begin
      if Context.Project_Service.Project.Get_Scm = Porion.Sources.SRC_GIT then
         Command.Update_Pos := Command.Update_Pos - 1;
      end if;
      if Command.Update_Pos = 1 then
         Porion.Commands.Error (-("cannot update the first step"));
         return;
      end if;
      if Recipe.Is_Null then
         Porion.Commands.Error (-("recipe was not found"));
         return;
      end if;

      if Args.Get_Count = 1 then
         Builds.Services.Update_Step (Context.Project_Service, Recipe,
                                      Command.Update_Pos - 1, Update'Access);
      else
         declare
            First  : constant String := Args.Get_Argument (2);
            Kind   : Porion.Builds.Models.Builder_Type;
            Step   : Porion.Builds.Step_Type;
            Params : Util.Strings.Vectors.Vector;
            Pos    : Positive := 2;
         begin
            if First = "xunit" then
               Kind := Porion.Builds.Models.BUILDER_XUNIT;
               Step := Porion.Builds.STEP_TEST;
               Pos := 3;
            elsif First = "metric" then
               Kind := Porion.Builds.Models.BUILDER_METRIC;
               Step := Porion.Builds.STEP_METRIC;
               Pos := 3;
            else
               Kind := Porion.Builds.Models.BUILDER_SCRIPT;
               Step := Porion.Builds.STEP_MAKE;
            end if;
            while Pos <= Args.Get_Count loop
               Params.Append (Args.Get_Argument (Pos));
               Pos := Pos + 1;
            end loop;

            Builds.Services.Update_Step (Context.Project_Service, Recipe,
                                         Command.Update_Pos - 1, Kind, Step, Params);
         end;
      end if;
   end Update_Step;

   procedure Delete_Step (Command : in out Command_Type;
                          Recipe  : in out Porion.Builds.Models.Recipe_Ref;
                          Context : in out Context_Type) is
   begin
      if Context.Project_Service.Project.Get_Scm = Porion.Sources.SRC_GIT then
         Command.Delete_Pos := Command.Delete_Pos - 1;
      end if;
      if Command.Delete_Pos <= 1 then
         Porion.Commands.Error (-("cannot delete the first step"));
         return;
      end if;
      if Recipe.Is_Null then
         Porion.Commands.Error (-("recipe was not found"));
         return;
      end if;

      Builds.Services.Delete_Step (Context.Project_Service,
                                   Recipe,
                                   Command.Delete_Pos - 1);

   exception
      when Porion.Builds.Services.Invalid_Position =>
         Porion.Commands.Error (-("delete position{0} is out of range"),
                                Natural'Image (Command.Delete_Pos));
   end Delete_Step;

   --  ------------------------------
   --  Add, update or remove a build step.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Error (-("missing project name"));
         return;
      end if;
      if Command.Has_Several_Actions then
         Porion.Commands.Log.Error (-("use only one of --insert, --update or --delete option"));
         return;
      end if;

      Context.Open;

      declare
         Name    : constant String := Args.Get_Argument (1);
         Ident   : Porion.Projects.Ident_Type;
      begin
         Ident := Porion.Projects.Parse (Name);
         Context.Project_Service.Load (Ident);

         if Command.Delete_Pos > 0 then
            Command.Delete_Step (Context.Project_Service.Recipe, Context);
         elsif Command.Update_Pos > 0 then
            Command.Update_Step (Context.Project_Service.Recipe, Args, Context);
         else
            if Args.Get_Count = 1 then
               Porion.Commands.Error (-("missing step action"));
               return;
            end if;

            Command.Add_Step (Context.Project_Service.Recipe, Args, Context);
         end if;

         if not Command.Quiet and not Context.Project_Service.Recipe.Is_Null then
            Porion.Commands.Print_Recipe_Steps (Context);
         end if;

      exception
         when Porion.Services.Not_Found =>
            Context.Error_Not_Found (Ident);
            return;

         when Porion.Projects.Invalid_Ident =>
            Commands.Error (-("invalid project or build identifier: {0}"), Name);
            return;

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
      GC.Define_Switch (Config => Config,
                        Output => Command.Delete_Pos'Access,
                        Long_Switch => "--remove=",
                        Argument => "POSITION",
                        Help => -("Remove the build step"));
      GC.Define_Switch (Config => Config,
                        Output => Command.Insert_Pos'Access,
                        Long_Switch => "--insert=",
                        Argument => "POSITION",
                        Help => -("Insert the build step"));
      GC.Define_Switch (Config => Config,
                        Output => Command.Update_Pos'Access,
                        Long_Switch => "--update=",
                        Argument => "POSITION",
                        Help => -("Update the build step"));
      GC.Define_Switch (Config => Config,
                        Output => Command.Timeout'Access,
                        Long_Switch => "--timeout=",
                        Argument => "TIMEOUT",
                        Help => -("Define the build step timeout"));
      GC.Define_Switch (Config => Config,
                        Output => Command.Ignore_Error'Access,
                        Long_Switch => "--ignore-error",
                        Help => -("Ignore error when executing this build step"));
      GC.Define_Switch (Config => Config,
                        Output => Command.Disable'Access,
                        Long_Switch => "--disable",
                        Help => -("Disable the build step"));
      GC.Define_Switch (Config, Command.Quiet'Access,
                        "-q", "--quiet", -("Quiet execution don't print the build steps"));
   end Setup;

end Porion.Commands.Steps;
