-----------------------------------------------------------------------
--  porion-commands-check -- Check for source changes and queue builds
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
with Porion.Builds.Services;
with Porion.Services;
with Porion.Sources;
with Porion.Executors;
package body Porion.Commands.Check is

   --  ------------------------------
   --  Remove a project and all its build data.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);

      Count : constant Natural := Args.Get_Count;
      Old_Queue_Size : Natural;
      New_Queue_Size : Natural;
   begin
      Context.Open;

      Old_Queue_Size := Builds.Services.Get_Queue_Size (Context.Project_Service);
      if Count = 0 then
         declare
            Executor : Porion.Executors.Executor_Type;
         begin
            Projects.Services.Check_Sources (Context.Project_Service, Executor, Command.Check_All);
         end;
      else
         for I in 1 .. Count loop
            declare
               Identification : constant String := Args.Get_Argument (I);
               Source_Status  : Porion.Sources.Status_Type;
               Executor       : Porion.Executors.Executor_Type;
               Ident          : Porion.Projects.Ident_Type;
            begin
               Ident := Porion.Projects.Parse (Identification);
               Context.Project_Service.Load (Ident);

               Projects.Services.Check_Sources (Context.Project_Service, Source_Status, Executor);
            end;
         end loop;
      end if;

      New_Queue_Size := Builds.Services.Get_Queue_Size (Context.Project_Service);
      if New_Queue_Size = 0 then
         Context.Notice (-("no change detected: build queue is empty, projects are up to date"));
      elsif Old_Queue_Size < New_Queue_Size then
         Context.Notice (-("{0} recipes added: build queue contains{0} recipes"),
                         Natural'Image (New_Queue_Size - Old_Queue_Size),
                         Natural'Image (New_Queue_Size));
      else
         Context.Notice (-("no change detected: build queue contains{0} recipes"),
                         Natural'Image (New_Queue_Size));
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
      GC.Define_Switch (Config, Command.Check_All'Access,
                        "-a", "--all", -("check every project"));
   end Setup;

end Porion.Commands.Check;
