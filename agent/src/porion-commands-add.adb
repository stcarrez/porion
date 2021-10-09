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
with Porion.Sources.Factories;
package body Porion.Commands.Add is

   --  ------------------------------
   --  Add a project with source control described by the URI.
   --  ------------------------------
   procedure Add_Project (Command : in out Command_Type;
                          URI     : in String;
                          Context : in out Context_Type) is
      Executor : Porion.Executors.Executor_Type;
      Info     : Porion.Sources.Source_Info_Type;
      Config   : Porion.Configs.Config_Type;
      Status   : Porion.Sources.Status_Type;
   begin
      --  Step 1: guess the source manager to be used with project info.
      Porion.Sources.Factories.Guess (Path     => URI,
                                      Config   => Config,
                                      Result   => Info,
                                      Executor => Executor);

      Context.Project_Service.Add_Project (Info);
      Context.Console.Notice (N_INFO, Format (-("Project {0} - {1} added"),
                              To_String (Info.Name), URI));

      --  Step 2: identify the branches of the project (only the main branch is enabled).
      Context.Project_Service.Check_Sources (Status, Executor);

      Context.Build_Service.Open (Context.Project_Service);

      --  Step 3: make a default build config for the branch.
      Context.Build_Service.Make_Build_Config (To_String (Status.Head), Executor);

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
                         Name    : in String;
                         Context : in out Context_Type) is
      Sep : constant Natural := Util.Strings.Index (Name, '@');
   begin
      if Sep = 0 then
         return;
      end if;

      Context.Project_Service.Load_Project (Name (Name'First .. Sep - 1));

      Context.Project_Service.Load_Node (Name (Sep + 1 .. Name'Last));
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

      declare
         URI : constant String := Args.Get_Argument (1);
      begin
         if Command.Recipe then
            Command.Add_Recipe (URI, Context);
         else
            Command.Add_Project (URI, Context);
         end if;
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
      GC.Define_Switch (Config, Command.Recipe'Access,
                        "-r", "--recipe", -("Add a build configuration to a project"));
   end Setup;

end Porion.Commands.Add;
