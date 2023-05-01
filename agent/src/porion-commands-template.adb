-----------------------------------------------------------------------
--  porion-commands-template -- Template management command
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
with Util.Strings.Vectors;
with Porion.Configs;
with Porion.Sources;
with Porion.Services;
with Porion.Projects;
with Porion.Builds.Services;
with Porion.Templates.Parser;
with Porion.Templates.Generator;
package body Porion.Commands.Template is

   use type Porion.Sources.Source_Control_Type;

   procedure Import_Template (Command : in out Command_Type;
                              Args    : in Argument_List'Class;
                              Context : in out Context_Type) is
      Repo : Porion.Templates.Repository_Type;
      Path : constant String := Porion.Configs.Get_Templates_Search_Path;
   begin
      Porion.Templates.Set_Search_Paths (Repo, Path);
      Porion.Templates.Parser.Load (Command.Template.all, Repo);
   end Import_Template;

   procedure Apply_Template (Command : in out Command_Type;
                             Args    : in Argument_List'Class;
                             Context : in out Context_Type) is
      Path : constant String := Porion.Configs.Get_Templates_Search_Path;
      Name : constant String := Args.Get_Argument (1);
      Prj  : constant String := Args.Get_Argument (2);
      Build : Porion.Builds.Services.Build_Config_Vector;
      Ident : Porion.Projects.Ident_Type;
      Tmpl  : Porion.Templates.Template_Ref;
   begin
      Context.Open;
      begin
         Ident := Porion.Projects.Parse (Prj);
         Context.Project_Service.Load (Ident);

      exception
         when Porion.Services.Not_Found =>
            Context.Error_Not_Found (Ident);

         when Porion.Projects.Invalid_Ident =>
            Commands.Error (-("invalid project identifier: {0}"), Prj);
            return;
      end;

      Porion.Templates.Set_Search_Paths (Context.Project_Service.Templates, Path);
      Porion.Templates.Parser.Load (Name, Context.Project_Service.Templates, Tmpl);
      Porion.Templates.Generator.Generate (Context.Project_Service, Tmpl, Build);
      Porion.Builds.Services.Update (Context.Project_Service, Build);
   end Apply_Template;

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
      if Command.Apply then
         if Args.Get_Count /= 2 then
            Porion.Commands.Error (-("invalid number of arguments"));
            return;
         end if;

         Apply_Template (Command, Args, Context);
         return;
      end if;
      if Command.Template'Length > 0 then
         Import_Template (Command, Args, Context);
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
      GC.Define_Switch (Config => Config,
                        Output => Command.Check'Access,
                        Long_Switch => "--check",
                        Help => -("Check the template syntax and validity"));
      GC.Define_Switch (Config => Config,
                        Output => Command.Apply'Access,
                        Long_Switch => "--apply",
                        Help => -("Apply the template recipes on the project"));
      GC.Define_Switch (Config => Config,
                        Output => Command.Template'Access,
                        Long_Switch => "--import=",
                        Argument => "PATH",
                        Help => -("Path of the template file to use"));
   end Setup;

end Porion.Commands.Template;
