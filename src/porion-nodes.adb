-----------------------------------------------------------------------
--  porion-nodes -- Build node information and management
--  Copyright (C) 2021, 2023 Stephane Carrez
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
with Ada.Characters.Handling;
with Ada.Environment_Variables;
with Util.Streams.Texts;
with Util.Files;
with Util.Log.Loggers;
package body Porion.Nodes is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Nodes");

   --  ------------------------------
   --  Returns true if commands are not executed but collected.
   --  ------------------------------
   function Is_Dry_Run (Controller : in Controller_Type'Class) return Boolean is
   begin
      return Controller.Listener /= null and then Controller.Listener.Is_Dry_Run;
   end Is_Dry_Run;

   --  ------------------------------
   --  Record a command that is executed during the build step.
   --  The command is not executed but added to the list of commands.
   --  ------------------------------
   procedure Record_Command (Controller : in out Controller_Type'Class;
                             Command    : in String) is
   begin
      if Controller.Listener /= null then
         Controller.Listener.Record_Command (Command);
      end if;
   end Record_Command;

   --  ------------------------------
   --  Set the listener instance.
   --  ------------------------------
   procedure Set_Listener (Controller : in out Controller_Type'Class;
                           Listener   : in Listener_Access) is
   begin
      Controller.Listener := Listener;
   end Set_Listener;

   --  ------------------------------
   --  Return the usage identified when running commands on this build node.
   --  ------------------------------
   function Get_Usage (Controller : in Controller_Type'Class) return Usage_Type is
   begin
      return Controller.Usage;
   end Get_Usage;

   function Find_Command_Path (Command : in String) return String is
   begin
      if not Ada.Environment_Variables.Exists ("PATH") then
         return Command;
      end if;

      declare
         Path : constant String := Ada.Environment_Variables.Value ("PATH");
      begin
         return Util.Files.Find_File_Path (Command, Path, ':');
      end;
   end Find_Command_Path;

   protected body Report_Output is

      procedure Print (Kind : in Output_Type;
                       Line : in String;
                       Process : not null access
                         procedure (Kind : in Output_Type;
                                    Line : in String)) is
      begin
         Process (Kind, Line);
      end Print;

   end Report_Output;

   procedure Read_Input (Report  : in out Report_Output;
                         Stream  : in out Input_Buffer_Stream'Class;
                         Strip_Crlf : in Boolean := False;
                         Kind    : in Output_Type;
                         Process : not null access
                           procedure (Kind : in Output_Type;
                                      Line : in String)) is
      Reader  : Util.Streams.Texts.Reader_Stream;
   begin
      Log.Debug ("Read input {0}", Kind'Image);

      Reader.Initialize (Stream'Unchecked_Access);
      while not Reader.Is_Eof loop
         declare
            Line : Ada.Strings.Unbounded.Unbounded_String;
         begin
            Reader.Read_Line (Line, Strip_Crlf);
            exit when Reader.Is_Eof and then Length (Line) = 0;
            --  Log.Debug ("Line: {0}: {1}", Kind'Image, To_String (Line));
            Report.Print (Kind, Ada.Strings.Unbounded.To_String (Line), Process);
         end;
      end loop;
   end Read_Input;

   --  ------------------------------
   --  Execute the command in the working directory and for each output
   --  line produced by the command call the Process procedure.
   --  ------------------------------
   procedure Execute (Controller  : in out Controller_Type'Class;
                      Command     : in String;
                      Working_Dir : in String := "";
                      Process     : not null access
                        procedure (Kind : in Output_Type;
                                   Line : in String);
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer) is
      procedure Read_Input (Out_Stream : in out Input_Buffer_Stream'Class;
                            Err_Stream : in out Input_Buffer_Stream'Class);

      procedure Read_Input (Out_Stream : in out Input_Buffer_Stream'Class;
                            Err_Stream : in out Input_Buffer_Stream'Class) is
         Report : Report_Output;
         task Reader is
         end Reader;
         task body Reader is
         begin
            Read_Input (Report, Err_Stream, Strip_Crlf, STDERR, Process);
         end Reader;
      begin
         Read_Input (Report, Out_Stream, Strip_Crlf, STDOUT, Process);
      end Read_Input;

   begin
      Controller.Record_Command (Command);
      if Controller.Is_Dry_Run then
         Status := 0;
         return;
      end if;
      declare
         Args  : Util.Strings.Vectors.Vector;
         Ignore_Working_Dir : Boolean;
      begin
         Controller.Expand (Command, Working_Dir, Ignore_Working_Dir, Args);
         if Args.Is_Empty then
            Status := 1;
            return;
         end if;

         Controller.Execute (Args, (if Ignore_Working_Dir then "" else Working_Dir),
                             Read_Input'Access, Status);
      end;
   end Execute;

   procedure Expand (Controller  : in out Controller_Type;
                     Command     : in String;
                     Working_Dir : in String;
                     Ignore_Working_Dir : out Boolean;
                     Args        : in out Util.Strings.Vectors.Vector) is
      pragma Unreferenced (Controller, Working_Dir);

      function Is_Space (C : in Character) return Boolean renames
        Ada.Characters.Handling.Is_Space;

      First : Natural := Command'First;
      Pos   : Natural := First;
   begin
      loop
         while First <= Command'Last and then Is_Space (Command (First)) loop
            First := First + 1;
         end loop;
         exit when First > Command'Last;
         Pos := First;
         while Pos <= Command'Last and then not Is_Space (Command (Pos)) loop
            Pos := Pos + 1;
         end loop;
         Args.Append (Command (First .. Pos - 1));
         First := Pos;
      end loop;

      Args.Replace_Element (1, Find_Command_Path (Args.First_Element));
      Ignore_Working_Dir := True;
   end Expand;

   RANDOM_PATH_LEN : constant := 15;
   RANDOM_PATH_EXT : constant String := ".txt";
   RANDOM_PATH_MAP : constant String := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      & "_abcdefghijklmnopqrstuvwxyz";

   --  ------------------------------
   --  Create a random path on the target node to store some temporary content.
   --  ------------------------------
   function Create_Random_Path (Controller : in out Controller_Type) return String is
      use Ada.Streams;
      Dir    : constant String := To_String (Controller.Build_Dir);
      Data   : Stream_Element_Array (1 .. RANDOM_PATH_LEN);
      Result : String (1 .. Dir'Length + RANDOM_PATH_LEN + RANDOM_PATH_EXT'Length + 1);
      Pos    : Positive := Dir'Length;
   begin
      Controller.Sec_Gen.Generate (Data);
      Result (1 .. Pos) := Dir;
      Result (Pos + 1) := '/';
      Pos := Pos + 2;
      for I in 1 .. Stream_Element_Offset (RANDOM_PATH_LEN) loop
         declare
            C : constant Stream_Element_Offset
               := Stream_Element_Offset (Data (I) and 16#7F#) mod RANDOM_PATH_MAP'Length;
         begin
            Result (Pos) := RANDOM_PATH_MAP (1 + Natural (C));
            Pos := Pos + 1;
         end;
      end loop;
      Result (Pos .. Result'Last) := RANDOM_PATH_EXT;
      return Result;
   end Create_Random_Path;

end Porion.Nodes;
