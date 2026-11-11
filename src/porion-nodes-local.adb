-----------------------------------------------------------------------
--  porion-nodes-local -- Local build node management
--  Copyright (C) 2021, 2022, 2024 Stephane Carrez
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
with Ada.Streams.Stream_IO;

with Util.Log.Loggers;
with Util.Files;
with Util.Streams;
with Util.Streams.Texts;
with Util.Streams.Files;
with Util.Systems.Constants;
with Porion.Tools;
package body Porion.Nodes.Local is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Nodes.Local");

   procedure Sys_Rusage (Usage : out Usage_Type)
     with Import => True, Convention => C,
          Link_Name => Util.Systems.Constants.SYMBOL_PREFIX & "porion_get_rusage";

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
   --  Set the environment variables when running commands in the build node.
   --  ------------------------------
   overriding
   procedure Set_Environment (Controller : in out Controller_Type;
                              Env        : in Util.Strings.Maps.Map) is
   begin
      Controller.Env := Env;
   end Set_Environment;

   --  ------------------------------
   --  Set the environment variables before launching the process.
   --  ------------------------------
   procedure Set_Environment (Controller : in out Controller_Type;
                              Proc       : in out Util.Processes.Process) is
      procedure Iterate (Process_Env : not null access procedure (Name, Value : in String));

      procedure Iterate (Process_Env : not null access procedure (Name, Value : in String)) is
      begin
         for Env in Controller.Env.Iterate loop
            declare
               Name  : constant String := Util.Strings.Maps.Key (Env);
               Value : constant String := Util.Strings.Maps.Element (Env);
            begin
               Log.Debug ("setenv {0} {1}", Name, Value);

               Process_Env (Name, Value);
            end;
         end loop;
      end Iterate;
   begin
      if not Controller.Env.Is_Empty then
         Util.Processes.Set_Environment (Proc, Iterate'Access);
      end if;
   end Set_Environment;

   overriding
   procedure Expand (Controller  : in out Controller_Type;
                     Command     : in String;
                     Working_Dir : in String;
                     Ignore_Working_Dir : out Boolean;
                     Args        : in out Util.Strings.Vectors.Vector) is
      pragma Unreferenced (Controller, Working_Dir);
   begin
      Args.Append (Find_Command_Path ("sh"));
      Args.Append ("-c");
      Args.Append (Command);
      Ignore_Working_Dir := False;
   end Expand;

   --  ------------------------------
   --  Export the file described by `Source_Path` to build in the directory
   --  defined by `Build_Path`.  Update `Exported_Path` to indicate the path
   --  of the exported file as seen from the build node.  If the build node
   --  is local, the operation does nothing.  If the build node is remote,
   --  it must be copied so that it is accessed from the build node.
   --  ------------------------------
   overriding
   procedure Export_File (Controller    : in out Controller_Type;
                          Source_Path   : in String;
                          Build_Path    : in String;
                          Exported_Path : out UString) is
   begin
      Exported_Path := To_UString ("");
   end Export_File;

   --  ------------------------------
   --  Execute the command in the working directory and for each output
   --  line produced by the command call the Process procedure.
   --  ------------------------------
   overriding
   procedure Execute (Controller  : in out Controller_Type;
                      Args        : in Util.Strings.Vectors.Vector;
                      Working_Dir : in String := "";
                      Process     : not null access
                        procedure (Out_Stream : in out Input_Buffer_Stream'Class;
                                   Err_Stream : in out Input_Buffer_Stream'Class);
                      Status      : out Integer) is

      Command : constant String := Porion.Tools.To_String (Args);
   begin
      Controller.Record_Command (Command);
      if Controller.Is_Dry_Run then
         Status := 0;
         return;
      end if;

      declare
         Proc       : Util.Processes.Process;
         Error      : Util.Streams.Input_Stream_Access;
         Output     : Util.Streams.Input_Stream_Access;
         Input      : Util.Streams.Output_Stream_Access;
         Out_Reader : Util.Streams.Texts.Reader_Stream;
         Err_Reader : Util.Streams.Texts.Reader_Stream;
         Start      : Usage_Type;
         Usage      : Usage_Type;
      begin
         if Working_Dir'Length > 0 then
            Log.Info ("Running '{0}' in '{1}'", Command, Working_Dir);
            Util.Processes.Set_Working_Directory (Proc, Working_Dir);
         else
            Log.Info ("Running '{0}'", Command);
         end if;

         Controller.Set_Environment (Proc);
         Sys_Rusage (Start);
         Util.Processes.Set_Allocate_TTY (Proc, Allocate => True);
         Util.Processes.Spawn (Proc      => Proc,
                               Arguments => Args,
                               Mode      => Util.Processes.READ_WRITE_ALL_SEPARATE);
         Input := Util.Processes.Get_Input_Stream (Proc);
         Output := Util.Processes.Get_Output_Stream (Proc);
         Error := Util.Processes.Get_Error_Stream (Proc);
         Out_Reader.Initialize (Output, 4096);
         Err_Reader.Initialize (Error, 4096);
         Input.Close;
         Process (Out_Reader, Err_Reader);
         Util.Processes.Wait (Proc);

         Sys_Rusage (Usage);
         Controller.Usage := Controller.Usage + (Usage - Start);

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
                                 procedure (Kind : in Output_Type;
                                            Line : in String)) is
      pragma Unreferenced (Controller, Process);
   begin
      if Clean and then Ada.Directories.Exists (Path) then
         --  Don't use Ada.Directories.Delete_Tree because it fails if the directory
         --  contains some special files such as sockets or symbolic links to missing files.
         Util.Files.Delete_Tree (Path);
      end if;

      Ada.Directories.Create_Path (Path);
   end Create_Directory;

   --  ------------------------------
   --  Read the file with the controller and execute the `Process` procedure with the
   --  input buffer stream that gives access to the file content.
   --  ------------------------------
   overriding
   procedure Read_File (Controller : in out Controller_Type;
                        Path       : in String;
                        Process    : not null access
                           procedure (Stream : in out Input_Buffer_Stream'Class)) is
      pragma Unreferenced (Controller);

      Stream     : aliased Util.Streams.Files.File_Stream;
      Buffer     : Util.Streams.Buffered.Input_Buffer_Stream;
   begin
      Buffer.Initialize (Input  => Stream'Unchecked_Access,
                         Size   => 1024);
      Stream.Open (Mode => Ada.Streams.Stream_IO.In_File, Name => Path);
      Process (Buffer);
   end Read_File;

   --  ------------------------------
   --  Scan the directory for files matching the given pattern.
   --  ------------------------------
   overriding
   procedure Scan_Directory (Controller : in out Controller_Type;
                             Path       : in String;
                             Pattern    : in String;
                             List       : in out Util.Strings.Sets.Set) is
      pragma Unreferenced (Controller);
      use Ada.Directories;

      Filter  : constant Filter_Type := [Ordinary_File => True,
                                         Directory     => True,
                                         others        => False];
      Search  : Search_Type;
      Ent     : Ada.Directories.Directory_Entry_Type;
   begin
      Log.Debug ("Scan directroy {0} for {1}", Path, Pattern);

      Start_Search (Search, Directory => Path,
                    Pattern => Pattern, Filter => Filter);
      while More_Entries (Search) loop
         Get_Next_Entry (Search, Ent);
         declare
            Name      : constant String := Ada.Directories.Simple_Name (Ent);
            Full_Path : constant String := Ada.Directories.Full_Name (Ent);
         begin
            if Name /= "." and Name /= ".." then
               List.Include (Full_Path);
            end if;
         end;
      end loop;

      Log.Info ("Scanned directory {0} for {1} found {2} entries",
                Path, Pattern, List.Length'Image);
   end Scan_Directory;

   --  ------------------------------
   --  Create a file with the given content.
   --  ------------------------------
   overriding
   procedure Create_File (Controller : in out Controller_Type;
                          Path       : in String;
                          Content    : in String) is
      Stream : Util.Streams.Files.File_Stream;
      Data   : Ada.Streams.Stream_Element_Array (1 .. Content'Length);
      for Data'Address use Content'Address;
   begin
      Stream.Create (Ada.Streams.Stream_IO.Out_File, Path);
      Stream.Write (Data);
      Stream.Close;
   end Create_File;

end Porion.Nodes.Local;
