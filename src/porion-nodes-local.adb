-----------------------------------------------------------------------
--  porion-nodes-local -- Local build node management
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
with Ada.Directories;
with Util.Processes;
with Util.Log.Loggers;
with Util.Streams;
with Util.Streams.Texts;
with Porion.Tools;
package body Porion.Nodes.Local is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Nodes.Local");

   --  ------------------------------
   --  Create the controller for the management of the given build node.
   --  ------------------------------
   function Create (Listener : in Listener_Access) return Nodes.Controller_Access is
      Controller : constant Controller_Access := new Controller_Type;
   begin
      Controller.Listener := Listener;
      return Controller.all'Access;
   end Create;

   --  ------------------------------
   --  Execute the command in the working directory and for each output
   --  line produced by the command call the Process procedure.
   --  ------------------------------
   overriding
   procedure Execute (Controller  : in out Controller_Type;
                      Command     : in String;
                      Working_Dir : in String := "";
                      Process     : not null access procedure (Line : in String);
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer) is
   begin
      if Controller.Is_Dry_Run then
         Controller.Record_Command (Command);
         Status := 0;
         return;
      end if;

      declare
         Proc    : Util.Processes.Process;
         Output  : Util.Streams.Input_Stream_Access;
         Input   : Util.Streams.Output_Stream_Access;
         Reader  : Util.Streams.Texts.Reader_Stream;
      begin
         if Working_Dir'Length > 0 then
            Log.Info ("Running '{0}' in '{1}'", Command, Working_Dir);
            Util.Processes.Set_Working_Directory (Proc, Working_Dir);
         else
            Log.Info ("Running '{0}'", Command);
         end if;

         Util.Processes.Spawn (Proc    => Proc,
                               Command => Command,
                               Mode    => Util.Processes.READ_WRITE_ALL);
         Input := Util.Processes.Get_Input_Stream (Proc);
         Output := Util.Processes.Get_Output_Stream (Proc);
         Reader.Initialize (Output, 4096);
         Input.Close;
         while not Reader.Is_Eof loop
            declare
               Line : Ada.Strings.Unbounded.Unbounded_String;
            begin
               Reader.Read_Line (Line, Strip_Crlf);
               Process (Ada.Strings.Unbounded.To_String (Line));
            end;
         end loop;
         Util.Processes.Wait (Proc);
         Status := Util.Processes.Get_Exit_Status (Proc);
         if Status /= 0 then
            Log.Warn ("Command '{0}' terminated with exit code{1}", Command,
                      Integer'Image (Status));
         end if;
      end;
   end Execute;

   procedure Execute (Controller  : in out Controller_Type;
                      Args        : in Util.Strings.Vectors.Vector;
                      Working_Dir : in String := "";
                      Process     : not null access procedure (Line : in String);
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer) is

      Command : constant String := Porion.Tools.To_String (Args);
   begin
      if Controller.Is_Dry_Run then
         Controller.Record_Command (Command);
         Status := 0;
         return;
      end if;

      declare
         Proc    : Util.Processes.Process;
         Output  : Util.Streams.Input_Stream_Access;
         Input   : Util.Streams.Output_Stream_Access;
         Reader  : Util.Streams.Texts.Reader_Stream;
      begin
         if Working_Dir'Length > 0 then
            Log.Info ("Running '{0}' in '{1}'", Command, Working_Dir);
            Util.Processes.Set_Working_Directory (Proc, Working_Dir);
         else
            Log.Info ("Running '{0}'", Command);
         end if;

         Util.Processes.Spawn (Proc      => Proc,
                               Arguments => Args,
                               Mode      => Util.Processes.READ_WRITE_ALL);
         Input := Util.Processes.Get_Input_Stream (Proc);
         Output := Util.Processes.Get_Output_Stream (Proc);
         Reader.Initialize (Output, 4096);
         Input.Close;
         while not Reader.Is_Eof loop
            declare
               Line : Ada.Strings.Unbounded.Unbounded_String;
            begin
               Reader.Read_Line (Line, Strip_Crlf);
               Process (Ada.Strings.Unbounded.To_String (Line));
            end;
         end loop;
         Util.Processes.Wait (Proc);
         Status := Util.Processes.Get_Exit_Status (Proc);
         if Status /= 0 then
            Log.Warn ("Command '{0}' terminated with exit code{1}", Command,
                      Integer'Image (Status));
         end if;
      end;
   end Execute;

   --  ------------------------------
   --  Create the directory and optionally make sure it is cleaned.
   --  ------------------------------
   overriding
   procedure Create_Directory (Controller : in out Controller_Type;
                               Path       : in String;
                               Clean      : in Boolean;
                               Process    : not null access
                                 procedure (Line : in String)) is
   begin
      if Clean and then Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;

      Ada.Directories.Create_Path (Path);
   end Create_Directory;

end Porion.Nodes.Local;
