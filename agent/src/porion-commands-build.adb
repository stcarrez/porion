-----------------------------------------------------------------------
--  porion-commands-build -- Build command
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
with Ada.Text_IO;
with Util.Strings.Vectors;
with Porion.Executors;
with Porion.Sources;
with Porion.Builds.Models;
package body Porion.Commands.Build is

   --  Build a project.
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      Count : constant Natural := Args.Get_Count;
   begin
      if Count = 0 then
         Porion.Commands.Error (-("missing project name"));
         return;
      end if;

      Context.Open;

      for I in 1 .. Count loop
         declare
            use Porion.Sources.Maps;

            Name          : constant String := Args.Get_Argument (Count);
            Source_Status : Porion.Sources.Status_Type;
            Executor      : Porion.Executors.Executor_Type;
            Build_Configs : Porion.Builds.Models.Build_Config_Vector;
         begin
            Context.Project_Service.Load_Project (Name);

            Context.Project_Service.Check_Sources (Source_Status, Executor);

            Context.Build_Service.Open (Context.Project_Service);

            if Command.Dry_Run then
               Executor.Enable_Dry_Run;
            end if;
            if not Command.Quiet and not (Context.Verbose or Context.Dump) then
               Executor.Enable_Log;
            end if;

            Context.Build_Service.Find_Build_Configs (Command.Force, Build_Configs);
            for Build_Config of Build_Configs loop
               Porion.Builds.Services.Build (Context.Build_Service, Build_Config, Executor);
               if Command.Dry_Run then
                  declare
                     Commands : Util.Strings.Vectors.Vector;
                     Step     : Natural := 0;
                  begin
                     Executor.Fetch_Commands (Commands);
                     for Cmd of Commands loop
                        Step := Step + 1;
                        Context.Console.Notice (N_INFO, Util.Strings.Image (Step)
                                                  & ". " & Cmd);
                     end loop;
                  end;
               end if;
            end loop;
         end;
      end loop;
   end Execute;

   --  Setup the command before parsing the arguments and executing it.
   overriding
   procedure Setup (Command : in out Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Context_Type) is
   begin
      Drivers.Command_Type (Command).Setup (Config, Context);
      GC.Define_Switch (Config, Command.Force'Access,
                        "-f", "--force", -("Force the build"));
      GC.Define_Switch (Config, Command.Clean'Access,
                        "-c", "--clean", -("Clean before building"));
      GC.Define_Switch (Config, Command.Quiet'Access,
                        "-q", "--quiet", -("Quiet execution where build logs are not printed"));
      GC.Define_Switch (Config, Command.Dry_Run'Access,
                        "-n", "--dry-run", -("Don't build but print commands for building"));
   end Setup;

end Porion.Commands.Build;
