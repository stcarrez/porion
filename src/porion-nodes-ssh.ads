-----------------------------------------------------------------------
--  porion-nodes-ssh -- SSH build node management
--  Copyright (C) 2021, 2022, 2023 Stephane Carrez
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
with Porion.Nodes.Local;
with Porion.Nodes.Models;
private with EL.Expressions;
private with Util.Processes;
private with Util.Streams.Texts;
private with Util.Streams.Buffered.Parts;
private package Porion.Nodes.SSH is

   SSH_COMMAND_NAME : constant String := "command_ssh";
   SCP_COMMAND_NAME : constant String := "command_scp";

   SSH_COMMAND      : constant String := "ssh -x "
     & "#{not empty identity ? '-i ' : ''}#{identity} "
     & "#{not empty login ? '-l ' : ''}#{login} #{hostname}";

   SCP_COMMAND      : constant String := "scp "
     & "#{not empty identity ? '-i ' : ''}#{identity} #{srcPath} "
     & "#{login}#{not empty login ? '@' : ''}#{hostname}:#{dstPath}";

   type Controller_Type is limited new Local.Controller_Type with private;
   type Controller_Access is access all Controller_Type'Class;

   --  Create the controller for the management of the given build node.
   function Create (Listener : in Listener_Access;
                    Node     : in Models.Node_Ref) return Nodes.Controller_Access;

   --  Returns true if this executor runs locally.
   overriding
   function Is_Local (Controller : in Controller_Type) return Boolean is (False);

   overriding
   procedure Expand (Controller  : in out Controller_Type;
                     Command     : in String;
                     Working_Dir : in String;
                     Ignore_Working_Dir : out Boolean;
                     Args        : in out Util.Strings.Vectors.Vector);

   --  Export the file described by `Source_Path` to build in the directory
   --  defined by `Build_Path`.  Update `Exported_Path` to indicate the path
   --  of the exported file as seen from the build node.  If the build node
   --  is local, the operation does nothing.  If the build node is remote,
   --  it must be copied so that it is accessed from the build node.
   overriding
   procedure Export_File (Controller    : in out Controller_Type;
                          Source_Path   : in String;
                          Build_Path    : in String;
                          Exported_Path : out UString);

   --  Execute the command in the working directory and for each output
   --  line produced by the command call the Process procedure.
   overriding
   procedure Execute (Controller  : in out Controller_Type;
                      Args        : in Util.Strings.Vectors.Vector;
                      Working_Dir : in String := "";
                      Process     : not null access
                        procedure (Out_Stream : in out Input_Buffer_Stream'Class;
                                   Err_Stream : in out Input_Buffer_Stream'Class);
                      Status      : out Integer);

   --  Create the directory and optionally make sure it is cleaned.
   overriding
   procedure Create_Directory (Controller : in out Controller_Type;
                               Path       : in String;
                               Clean      : in Boolean;
                               Process    : not null access
                                 procedure (Kind : in Output_Type;
                                            Line : in String));

   --  Read the file with the controller and execute the `Process` procedure with the
   --  input buffer stream that gives access to the file content.
   overriding
   procedure Read_File (Controller : in out Controller_Type;
                        Path       : in String;
                        Process    : not null access
                           procedure (Stream : in out Input_Buffer_Stream'Class));

   --  Scan the directory for files matching the given pattern.
   overriding
   procedure Scan_Directory (Controller : in out Controller_Type;
                             Path       : in String;
                             Pattern    : in String;
                             List       : in out Util.Strings.Sets.Set);

   overriding
   procedure Start (Controller : in out Controller_Type);

   overriding
   procedure Stop (Controller : in out Controller_Type);

private

   BOUNDARY_LENGTH : constant := 60;

   type Shell_Type is (USE_SH, USE_CSH);

   type Controller_Type is limited new Local.Controller_Type with record
      Hostname    : Porion.UString;
      Login       : Porion.UString;
      Identity    : Porion.UString;
      Command     : EL.Expressions.Expression;
      Scp_Command : EL.Expressions.Expression;
      Shell       : Shell_Type := USE_SH;
      Proc        : Util.Processes.Process;
      Error       : Util.Streams.Input_Stream_Access;
      Output      : Util.Streams.Input_Stream_Access;
      Input       : Util.Streams.Output_Stream_Access;
      Cmd_Writer  : Util.Streams.Texts.Print_Stream;
      Out_Reader  : Util.Streams.Buffered.Parts.Input_Part_Stream;
      Err_Reader  : Util.Streams.Buffered.Parts.Input_Part_Stream;
      Boundary    : String (1 .. BOUNDARY_LENGTH);
   end record;

   --  Write the command on the ssh input stream for execution.
   --  Two 'echo' statements are added for the standard output and standard error
   --  with a boundary indication.  The 'echo' on standard error includes the execution
   --  status of the command.
   procedure Execute (Controller : in out Controller_Type;
                      Command    : in String);

   --  Send the environment variables to be used by the remote shell.
   procedure Send_Environment (Controller : in out Controller_Type);

end Porion.Nodes.SSH;
