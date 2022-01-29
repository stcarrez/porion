-----------------------------------------------------------------------
--  porion-commands-env -- Env command to configure environment variables
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
with Porion.Services;
with Porion.Nodes.Models;
with Porion.Nodes.Services;
with Porion.Projects.Models;
with Porion.Builds.Models;
with Porion.Builds.Services;
package body Porion.Commands.Env is

   --  ------------------------------
   --  Set or unset environment variables for build recipes.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Command, Name);

      Count : constant Natural := Args.Get_Count;
   begin
      Context.Open;

      if Count = 0 then
         Porion.Reports.List_Environment (Service => Context.Project_Service,
                                          Printer => Context.Printer.all,
                                          Styles  => Context.Styles);
         return;
      end if;

      declare
         Arg   : constant String := Args.Get_Argument (1);
         First : Positive := 1;
         Ident : Porion.Projects.Ident_Type;
      begin
         if Util.Strings.Starts_With (Arg, "@") then
            Porion.Nodes.Services.Load_Node (Context.Project_Service,
                                             Arg (Arg'First + 1 .. Arg'Last));
            First := 2;

         elsif Util.Strings.Index (Arg, '=') = 0 then
            Ident := Porion.Projects.Parse (Arg);
            Context.Project_Service.Load (Ident);

            if not Porion.Projects.Has_Recipe (Ident) then
               Context.Project_Service.Recipe := Porion.Builds.Models.Null_Recipe;
            end if;

            if not Porion.Projects.Has_Branch (Ident)
              and not Porion.Projects.Has_Recipe (Ident)
            then
               Context.Project_Service.Branch := Porion.Projects.Models.Null_Branch;
            end if;

            if not Porion.Projects.Has_Node (Ident) then
               Context.Project_Service.Build_Node := Porion.Nodes.Models.Null_Node;
            end if;

            First := 2;
         end if;

         for I in First .. Count loop
            declare
               Env : constant String := Args.Get_Argument (I);
               Sep : constant Natural := Util.Strings.Index (Env, '=');
            begin
               if Sep = 0 then
                  Commands.Error (-("Invalid environment variable"));
               else
                  Porion.Builds.Services.Set_Environment (Context.Project_Service,
                                                          Env (Env'First .. Sep - 1),
                                                          Env (Sep + 1 .. Env'Last));
               end if;
            end;
         end loop;

      exception
         when Porion.Nodes.Services.Not_Found =>
            Commands.Error (-("build node {0} not found"), Arg (Arg'First + 1 .. Arg'Last));

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

end Porion.Commands.Env;
