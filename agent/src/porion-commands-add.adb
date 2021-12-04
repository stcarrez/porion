-----------------------------------------------------------------------
--  porion-commands-add -- Add command
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
with Porion.Projects.Services;
with Porion.Configs;
with Porion.Executors;
with Porion.Services;
with Porion.Nodes.Services;
with Porion.Builds.Models;
with Porion.Builds.Services;
with Porion.Sources;
package body Porion.Commands.Add is

   --  ------------------------------
   --  Add a project with source control described by the URI.
   --  ------------------------------
   procedure Add_Project (Command : in out Command_Type;
                          URI     : in String;
                          Context : in out Context_Type) is
      Info     : Porion.Sources.Source_Info_Type;
      Config   : Porion.Configs.Config_Type;
      Status   : Porion.Sources.Status_Type;
      Executor : Porion.Executors.Executor_Type;
   begin
      --  Step 1: guess the source manager to be used with project info.
      Porion.Sources.Guess (Path     => URI,
                            Config   => Config,
                            Result   => Info,
                            Executor => Executor);

      Projects.Services.Add_Project (Context.Project_Service, Info);
      Context.Notice (-("Project {0} - {1} added"), To_String (Info.Name), URI);

      --  Step 2: identify the branches of the project (only the main branch is enabled).
      Projects.Services.Check_Sources (Context.Project_Service, Status, Executor);

      --  Step 3: make a default build config for the branch.
      Builds.Services.Make_Recipes (Context.Project_Service, To_String (Status.Head), Executor);

      if not Command.Quiet then
         Porion.Commands.Print_Recipe_Steps (Context);
      end if;

      Context.Notice (-("Use 'porion step {0} <command>' to add a new build step"),
                      To_String (Info.Name));
      Context.Notice (-("Use 'porion step {0} xunit <pattern>' to add a unit test analysis step"),
                      To_String (Info.Name));

   exception
      when Porion.Projects.Services.Name_Used =>
         Porion.Commands.Error (-("project '{0}' already exists"),
                                To_String (Info.Name));

      when Porion.Projects.Services.Invalid_Name =>
         Porion.Commands.Error (-("invalid project name '{0}'"),
                                To_String (Info.Name));

   end Add_Project;

   --  ------------------------------
   --  Add a recipe to build an existing project.
   --  ------------------------------
   procedure Add_Recipe (Command : in out Command_Type;
                         Target  : in String;
                         Source  : in String;
                         Context : in out Context_Type) is
      Ident   : Porion.Projects.Ident_Type;
      Recipes : Porion.Builds.Models.Recipe_Vector;
   begin
      if Source'Length > 0 then
         begin
            Ident := Porion.Projects.Parse (Source);

         exception
            when Porion.Projects.Invalid_Ident =>
               Commands.Error (-("invalid source '{0}'"), Source);
               return;
         end;

         begin
            Porion.Builds.Services.Load_Recipes (Context.Project_Service, Ident, Recipes);

         exception
            when Porion.Services.Not_Found =>
               Commands.Error (-("source project '{0}' not found"),
                               To_String (Ident.Name));
               return;
         end;

         if Recipes.Is_Empty then
            Commands.Error (-("no recipe found for source '{0}'"), Source);
            return;
         end if;
      end if;

      Ident := Porion.Projects.Parse (Target);

      begin
         Context.Project_Service.Load (Ident);
         if not Context.Project_Service.Has_Recipe then
            Commands.Error (-("missing source recipe identification to copy"));
            return;
         end if;

      exception
         when Porion.Services.Not_Found =>
            Commands.Error (-("project '{0}' not found"),
                            To_String (Ident.Name));
            return;
      end;

      Builds.Services.Copy_Recipe (Context.Project_Service,
                                   Command.Recipe.all,
                                   Context.Project_Service.Recipe);

      if Context.Project_Service.Branch.Is_Null then
         Commands.Error (-("branch '{0}' not found for project '{1}'"),
                         To_String (Ident.Branch), To_String (Ident.Name));
         return;
      end if;

      Context.Notice (-("New recipe added to project {0} branch {1}"),
                      To_String (Ident.Name), Context.Project_Service.Branch.Get_Name);

      if not Command.Quiet then
         Porion.Commands.Print_Recipe_Steps (Context);
      end if;

   exception
      when Porion.Nodes.Services.Not_Found =>
         Commands.Error (-("invalid build node '{0}'"), To_String (Ident.Node));

      when Porion.Projects.Invalid_Ident =>
         Commands.Error (-("invalid project identification '{0}'"), Target);
   end Add_Recipe;

   --  ------------------------------
   --  Add a project, identify its source control scheme and build steps.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Error (-("missing project URL or file to add"));
         return;
      end if;
      Context.Open;

      if Command.Recipe'Length > 0 then
         if Args.Get_Count = 2 then
            Command.Add_Recipe (Args.Get_Argument (1), Args.Get_Argument (2), Context);
         else
            Command.Add_Recipe (Args.Get_Argument (1), "", Context);
         end if;
      else
         Command.Add_Project (Args.Get_Argument (1), Context);
      end if;
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
      GC.Define_Switch (Config, Command.Recipe'Access,
                        "-r=", "--recipe=",
                        Argument => "IDENT",
                        Help     =>  -("Add a build recipe to a project"));
      GC.Define_Switch (Config, Command.Quiet'Access,
                        "-q", "--quiet", -("Quiet execution don't print the build steps"));
   end Setup;

end Porion.Commands.Add;
