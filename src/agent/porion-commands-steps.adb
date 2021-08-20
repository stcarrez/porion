-----------------------------------------------------------------------
--  porion-commands-steps -- Command to add, update remove build steps
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
with Util.Strings.Vectors;
with Porion.Builds.Models;
package body Porion.Commands.Steps is

   --  ------------------------------
   --  Add, update or remove a build step.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Log.Error (-("missing project name"));
         raise Error;
      end if;
      if Command.Has_Several_Actions then
         Porion.Commands.Log.Error (-("use only one of --insert, --update or --delete option"));
         raise Error;
      end if;
      Context.Project_Service.Open;

      declare
         Name          : constant String := Args.Get_Argument (1);
      begin
         Context.Project_Service.Load_Project (Name);

         Context.Build_Service.Open (Context.Project_Service);

         Context.Build_Service.Load_Config;

         if Command.Delete_Pos > 0 then
            Context.Build_Service.Delete_Step (Command.Delete_Pos);
            return;
         end if;
      end;

      declare
         First  : constant String := Args.Get_Argument (2);
         Kind   : Porion.Builds.Models.Builder_Type;
         Params : Util.Strings.Vectors.Vector;
         Pos    : Positive := 2;
      begin
         if First = "xunit" then
            Kind := Porion.Builds.Models.BUILDER_XUNIT;
            Pos := 3;
         else
            Kind := Porion.Builds.Models.BUILDER_SCRIPT;
         end if;
         while Pos <= Args.Get_Count loop
            Params.Append (Args.Get_Argument (Pos));
            Pos := Pos + 1;
         end loop;
         Context.Build_Service.Insert_Step (Command.Insert_Pos, Kind, Params);
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
                        Long_Switch => "--delete=",
                        Argument => "POSITION",
                        Help => -("Delete the build step"));
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
   end Setup;

   --  Write the help associated with the command.
   overriding
   procedure Help (Command   : in out Command_Type;
                   Name      : in String;
                   Context   : in out Context_Type) is
   begin
      null;
   end Help;

end Porion.Commands.Steps;
