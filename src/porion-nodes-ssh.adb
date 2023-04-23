-----------------------------------------------------------------------
--  porion-nodes-ssh -- SSH build node management
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
with Ada.Streams;
with Util.Strings.Vectors;
with Util.Files;
with Util.Log.Loggers;
with Porion.Configs;
with EL.Contexts.Default;
with Security.Random;
with Porion.Tools;
package body Porion.Nodes.SSH is

   package UBO renames Util.Beans.Objects;

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Nodes.SSH");

   --  ------------------------------
   --  Create the controller for the management of the given build node.
   --  ------------------------------
   function Create (Listener : in Listener_Access;
                    Node     : in Models.Node_Ref) return Nodes.Controller_Access is
      Controller : constant Controller_Access := new Controller_Type;
      Cmd        : constant String := Configs.Get (SSH_COMMAND_NAME, SSH_COMMAND);
      Ctx        : EL.Contexts.Default.Default_Context;
   begin
      Porion.Nodes.Set_Listener (Controller.all, Listener);
      Controller.Hostname := Node.Get_Name;
      Controller.Login := Node.Get_Login;
      Controller.Command := EL.Expressions.Create_Expression (Cmd, Ctx);
      return Controller.all'Access;
   end Create;

   overriding
   procedure Expand (Controller  : in out Controller_Type;
                     Command     : in String;
                     Working_Dir : in String;
                     Ignore_Working_Dir : out Boolean;
                     Args        : in out Util.Strings.Vectors.Vector) is
      pragma Unreferenced (Controller, Working_Dir);
   begin
      Args.Append (Command);
      Ignore_Working_Dir := False;
   end Expand;

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

      if Working_Dir'Length > 0 then
         Log.Info ("Running '{0}' in '{1}' on '{2}'", Command, Working_Dir,
                   To_String (Controller.Hostname));
         Controller.Cmd_Writer.Write ("cd '");
         Controller.Cmd_Writer.Write (Working_Dir);
         Controller.Cmd_Writer.Write ("' && ");
      else
         Log.Info ("Running '{0}' on '{1}'", Command, To_String (Controller.Hostname));
      end if;
      Controller.Send_Environment;

      declare
         Start       : Usage_Type;
         Usage       : Usage_Type;
         Status_Line : UString;
      begin
         --  Sys_Rusage (Start);
         Controller.Execute (Command);
         Controller.Out_Reader.Next_Part;
         Controller.Err_Reader.Set_Boundary (Controller.Boundary);

         Process (Controller.Out_Reader, Controller.Err_Reader);
         Controller.Err_Reader.Set_Boundary (Controller.Boundary & ASCII.LF);
         Controller.Err_Reader.Read (Status_Line);
         begin
            Status := Natural'Value (To_String (Status_Line));
            if Status = 0 then
               Log.Debug ("Remote execution status is 0");
            else
               Log.Info ("Remote execution failed with status{0}", Status'Image);
            end if;

         exception
            when others =>
               Status := -1;
               Log.Warn ("Remove execution failed, unkown output: '{0}'",
                         To_String (Status_Line));
         end;
         --  Util.Processes.Wait (Proc);

         --  Sys_Rusage (Usage);
         --  Controller.Usage := Controller.Usage + (Usage - Start);
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
      Status : Integer;
   begin
      if Clean then
         Controller.Execute (Command => "rm -rf " & Path & " && mkdir -p " & Path,
                             Working_Dir => "",
                             Process => Process,
                             Strip_Crlf => False,
                             Status => Status);
      else
         Controller.Execute (Command => "mkdir -p " & Path,
                             Working_Dir => "",
                             Process => Process,
                             Strip_Crlf => False,
                             Status => Status);
      end if;
   end Create_Directory;

   --  Read the file with the controller and execute the `Process` procedure with the
   --  input buffer stream that gives access to the file content.
   overriding
   procedure Read_File (Controller : in out Controller_Type;
                        Path       : in String;
                        Process    : not null access
                           procedure (Stream : in out Input_Buffer_Stream'Class)) is
      procedure Read_Input (Out_Stream : in out Input_Buffer_Stream'Class;
                            Err_Stream : in out Input_Buffer_Stream'Class);

      procedure Print (Kind : in Output_Type;
                       Line : in String);
      procedure Print (Kind : in Output_Type;
                       Line : in String) is
      begin
         Log.Error ("{0}", Line);
      end Print;

      procedure Read_Input (Out_Stream : in out Input_Buffer_Stream'Class;
                            Err_Stream : in out Input_Buffer_Stream'Class) is
         Report : Report_Output;
         task Reader is
         end Reader;
         task body Reader is
         begin
            Read_Input (Report, Err_Stream, True, STDERR, Print'Access);
         end Reader;

      begin
         Process (Out_Stream);
      end Read_Input;

      Status : Integer;
      Args   : Util.Strings.Vectors.Vector;
      Ignore_Working_Dir : Boolean;
   begin
      Controller.Expand ("cat " & Path, "", Ignore_Working_Dir, Args);
      Controller.Execute (Args => Args,
                          Working_Dir => "",
                          Process => Read_Input'Access,
                          Status => Status);
   end Read_File;

   --  ------------------------------
   --  Scan the directory for files matching the given pattern.
   --  ------------------------------
   overriding
   procedure Scan_Directory (Controller : in out Controller_Type;
                             Path       : in String;
                             Pattern    : in String;
                             List       : in out Util.Strings.Sets.Set) is
      procedure Process (Kind : in Output_Type;
                         Line : in String);

      procedure Process (Kind : in Output_Type;
                         Line : in String) is
      begin
         if Kind = STDERR then
            Log.Error ("{0}", Line);
            return;
         end if;
         if Line'Length > 0 then
            List.Include (Util.Files.Compose (Path, Line));
         end if;
      end Process;

      Status : Integer;
   begin
      Controller.Execute (Command => "ls -c " & Pattern,
                          Working_Dir => Path,
                          Process => Process'Access,
                          Strip_Crlf => True,
                          Status => Status);
   end Scan_Directory;

   BOUNDARY_MAP : constant String := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      & "=/.+_abcdefghijklmnopqrstuvwxyz";

   overriding
   procedure Start (Controller : in out Controller_Type) is
      use Ada.Streams;

      Sec_Gen : Security.Random.Generator;
      Data    : Stream_Element_Array (1 .. BOUNDARY_LENGTH);
      Props   : aliased EL.Contexts.Default.Default_ELResolver;
      Ctx     : EL.Contexts.Default.Default_Context;
   begin
      Log.Info ("Start ssh on remote node {0}", Controller.Hostname);

      Sec_Gen.Generate (Data);
      for I in 1 .. Stream_Element_Offset (BOUNDARY_LENGTH) loop
         declare
            Pos : constant Stream_Element_Offset
               := Stream_Element_Offset (Data (I) and 16#7F#) mod BOUNDARY_MAP'Length;
         begin
            Controller.Boundary (Positive (I)) := BOUNDARY_MAP (1 + Natural (Pos));
         end;
      end loop;
      --  Controller.Boundary := (others => '0');
      Log.Debug ("Using boundary '{0}'", Controller.Boundary);

      Props.Register (To_UString ("login"), UBO.To_Object (Controller.Login));
      Props.Register (To_UString ("hostname"), UBO.To_Object (Controller.Hostname));
      Props.Register (To_UString ("identity"), UBO.To_Object (Controller.Identity));
      Ctx.Set_Resolver (Props'Unchecked_Access);
      declare
         Cmd   : constant UBO.Object := Controller.Command.Get_Value (Ctx);
         Ssh   : constant String := UBO.To_String (Cmd);
         Args  : Util.Strings.Vectors.Vector;
         Ignore_Working_Dir : Boolean;
      begin
         Porion.Nodes.Controller_Type (Controller).Expand (Ssh, ".",
                                                           Ignore_Working_Dir, Args);
         Util.Processes.Spawn (Proc      => Controller.Proc,
                               Arguments => Args,
                               Mode      => Util.Processes.READ_WRITE_ALL_SEPARATE);
      end;

      Controller.Input := Util.Processes.Get_Input_Stream (Controller.Proc);
      Controller.Output := Util.Processes.Get_Output_Stream (Controller.Proc);
      Controller.Error := Util.Processes.Get_Error_Stream (Controller.Proc);
      Controller.Cmd_Writer.Initialize (Controller.Input, 1024);
      Controller.Out_Reader.Initialize (Controller.Output, 4096);
      Controller.Err_Reader.Initialize (Controller.Error, 4096);
      Controller.Out_Reader.Set_Boundary (Controller.Boundary & ASCII.LF);
      Controller.Err_Reader.Set_Boundary (Controller.Boundary);
   end Start;

   overriding
   procedure Stop (Controller : in out Controller_Type) is
   begin
      Controller.Cmd_Writer.Close;
      null;
   end Stop;

   --  ------------------------------
   --  Write the command on the ssh input stream for execution.
   --  Two 'echo' statements are added for the standard output and standard error
   --  with a boundary indication.  The 'echo' on standard error includes the execution
   --  status of the command.
   --  ------------------------------
   procedure Execute (Controller : in out Controller_Type;
                      Command    : in String) is
   begin
      Log.Debug ("Sending command '{0}'", Command);

      Controller.Cmd_Writer.Write (Command);
      Controller.Cmd_Writer.Write (ASCII.LF);
      Controller.Cmd_Writer.Write ("echo '");
      Controller.Cmd_Writer.Write (Controller.Boundary);
      Controller.Cmd_Writer.Write ("' $? '");
      Controller.Cmd_Writer.Write (Controller.Boundary);
      Controller.Cmd_Writer.Write ("' >&2");
      Controller.Cmd_Writer.Write (ASCII.LF);
      Controller.Cmd_Writer.Write ("echo '");
      Controller.Cmd_Writer.Write (Controller.Boundary);
      Controller.Cmd_Writer.Write ("'");
      Controller.Cmd_Writer.Write (ASCII.LF);
      Controller.Cmd_Writer.Flush;
   end Execute;

   --  ------------------------------
   --  Send the environment variables to be used by the remote shell.
   --  ------------------------------
   procedure Send_Environment (Controller : in out Controller_Type) is
   begin
      for Env in Controller.Env.Iterate loop
         declare
            Name  : constant String := Util.Strings.Maps.Key (Env);
            Value : constant String := Util.Strings.Maps.Element (Env);
         begin
            case Controller.Shell is
               when USE_SH =>
                  Log.Debug ("export {0}='{1}'", Name, Value);

                  Controller.Cmd_Writer.Write ("export ");
                  Controller.Cmd_Writer.Write (Name);
                  Controller.Cmd_Writer.Write ("='");
                  Controller.Cmd_Writer.Write (Value);
                  Controller.Cmd_Writer.Write ("'" & ASCII.LF);

               when USE_CSH =>
                  Log.Debug ("setenv {0} '{1}'", Name, Value);

                  Controller.Cmd_Writer.Write ("setenv ");
                  Controller.Cmd_Writer.Write (Name);
                  Controller.Cmd_Writer.Write (" '");
                  Controller.Cmd_Writer.Write (Value);
                  Controller.Cmd_Writer.Write ("'" & ASCII.LF);

            end case;
         end;
      end loop;
   end Send_Environment;

end Porion.Nodes.SSH;
