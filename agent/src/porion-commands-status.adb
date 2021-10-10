-----------------------------------------------------------------------
--  porion-commands-status -- Status command
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
with Util.Streams.Texts;
with Util.Serialize.IO.XML;
with Util.Serialize.IO.JSON;
with Porion.Configs;
package body Porion.Commands.Status is

   --  Get a value from the keystore.
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
   begin
      if Args.Get_Count = 0 then
         Ada.Text_IO.Put ("Porion directory : ");
         Ada.Text_IO.Put_Line (Porion.Configs.Get_Porion_Directory);
         return;
      end if;
      Context.Open;

      for I in 1 .. Args.Get_Count loop
         declare
            Name      : constant String := Args.Get_Argument (1);
            Output    : aliased Util.Streams.Texts.Print_Stream;
         begin
            Context.Project_Service.Load_Project (Name);
            Context.Build_Service.Open (Context.Project_Service);
            Context.Build_Service.Load_Recipe;

            Output.Initialize (Size => 100000);
            if Command.Json then
               declare
                  Stream : Util.Serialize.IO.JSON.Output_Stream;
               begin
                  Stream.Initialize (Output => Output'Unchecked_Access);
                  Command.Stats (Stream, Context);
               end;
            else
               declare
                  Stream : Util.Serialize.IO.XML.Output_Stream;
               begin
                  Stream.Initialize (Output => Output'Unchecked_Access);
                  Stream.Set_Indentation (2);
                  Command.Stats (Stream, Context);
               end;
            end if;
            Ada.Text_IO.Put_Line (Util.Streams.Texts.To_String (Output));
         end;
      end loop;
   end Execute;

   procedure Stats (Command : in out Command_Type;
                    Stream  : in out Util.Serialize.IO.Output_Stream'Class;
                    Context : in out Context_Type) is
      procedure Process (Stream : in out Util.Serialize.IO.Output_Stream'Class);

      procedure Process (Stream : in out Util.Serialize.IO.Output_Stream'Class) is
      begin
         Context.Build_Service.Export (Stream);
      end Process;

   begin
      Stream.Start_Document;
      Projects.Services.Export (Context.Project_Service, Stream, Process'Access);
      Stream.End_Document;
   end Stats;

   --  Setup the command before parsing the arguments and executing it.
   overriding
   procedure Setup (Command : in out Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Context_Type) is
   begin
      Drivers.Command_Type (Command).Setup (Config, Context);
      GC.Define_Switch (Config, Command.Json'Access,
                        "-j", "json", -("Produce a JSON output"));
      GC.Define_Switch (Config, Command.Xml'Access,
                        "-x", "xml", -("Produce a XML output"));
   end Setup;

end Porion.Commands.Status;
