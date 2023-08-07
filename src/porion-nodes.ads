-----------------------------------------------------------------------
--  porion-nodes -- Build node information and management
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
with Ada.Finalization;
with Util.Strings.Maps;
with Util.Strings.Sets;
with Util.Streams.Buffered;
with Util.Strings.Vectors;
with Util.Beans.Objects.Enums;
private with Security.Random;
package Porion.Nodes is

   subtype System_Time is Long_Long_Integer;
   subtype Input_Buffer_Stream is Util.Streams.Buffered.Input_Buffer_Stream;

   type Usage_Type is record
      User_Time : System_Time;
      Sys_Time  : System_Time;
   end record;

   function "-" (Left, Right : in Usage_Type) return Usage_Type is
      ((User_Time => Left.User_Time - Right.User_Time,
        Sys_Time  => Left.Sys_Time - Right.Sys_Time));

   function "+" (Left, Right : in Usage_Type) return Usage_Type is
      ((User_Time => Left.User_Time + Right.User_Time,
        Sys_Time  => Left.Sys_Time + Right.Sys_Time));

   type Node_Type is (NODE_LOCAL, NODE_SSH, NODE_DOCKER, NODE_VIRSH);

   --  Use a fixed enum configuration because the value is stored in database.
   for Node_Type use (NODE_LOCAL  => 0,
                      NODE_SSH    => 1,
                      NODE_DOCKER => 2,
                      NODE_VIRSH  => 3);

   package Node_Type_Objects is new Util.Beans.Objects.Enums (Node_Type);

   type Node_Status_Type is (NODE_ERROR,
                             NODE_DISABLED,
                             NODE_ENABLED,
                             NODE_STARTING,
                             NODE_ONLINE,
                             NODE_STOPPING,
                             NODE_OFFLINE);

   --  Use a fixed enum configuration because the value is stored in database.
   --  Use -1 for error so that it helps in trouble shotting.
   for Node_Status_Type use (NODE_ERROR    => -1,
                             NODE_DISABLED => 0,
                             NODE_ENABLED  => 1,
                             NODE_STARTING => 2,
                             NODE_ONLINE   => 3,
                             NODE_STOPPING => 4,
                             NODE_OFFLINE  => 5);

   package Node_Status_Type_Objects is new Util.Beans.Objects.Enums (Node_Status_Type);

   type Output_Type is (STDOUT, STDERR);

   type Listener_Type is limited interface;
   type Listener_Access is access all Listener_Type'Class;

   --  Returns true if commands are not executed but collected.
   function Is_Dry_Run (Listener : in Listener_Type) return Boolean is abstract;

   --  Record a command that is executed during the build step.
   --  The command is not executed but added to the list of commands.
   procedure Record_Command (Listener : in out Listener_Type;
                             Command  : in String) is abstract;

   type Controller_Type is abstract limited new Ada.Finalization.Limited_Controlled with private;
   type Controller_Access is access all Controller_Type'Class;

   --  Returns true if this executor runs locally.
   function Is_Local (Controller : in Controller_Type) return Boolean is (True);

   --  Return the usage identified when running commands on this build node.
   function Get_Usage (Controller : in Controller_Type'Class) return Usage_Type;

   procedure Start (Controller : in out Controller_Type) is null;

   procedure Stop (Controller : in out Controller_Type) is null;

   --  Set the environment variables when running commands in the build node.
   procedure Set_Environment (Controller : in out Controller_Type;
                              Env        : in Util.Strings.Maps.Map) is abstract;

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
   procedure Export_File (Controller    : in out Controller_Type;
                          Source_Path   : in String;
                          Build_Path    : in String;
                          Exported_Path : out UString) is abstract;

   --  Execute the command in the working directory and for each output
   --  line produced by the command call the Process procedure.
   procedure Execute (Controller  : in out Controller_Type;
                      Args        : in Util.Strings.Vectors.Vector;
                      Working_Dir : in String := "";
                      Process     : not null access
                        procedure (Out_Stream : in out Input_Buffer_Stream'Class;
                                   Err_Stream : in out Input_Buffer_Stream'Class);
                      Status      : out Integer) is abstract;

   procedure Execute (Controller  : in out Controller_Type'Class;
                      Command     : in String;
                      Working_Dir : in String := "";
                      Process     : not null access
                        procedure (Kind : in Output_Type;
                                   Line : in String);
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer);

   --  Create the directory and optionally make sure it is cleaned.
   procedure Create_Directory (Controller : in out Controller_Type;
                               Path       : in String;
                               Clean      : in Boolean;
                               Process    : not null access
                                 procedure (Kind : in Output_Type;
                                            Line : in String)) is abstract;

   --  Read the file with the controller and execute the `Process` procedure with the
   --  input buffer stream that gives access to the file content.
   procedure Read_File (Controller : in out Controller_Type;
                        Path       : in String;
                        Process    : not null access
                           procedure (Stream : in out Input_Buffer_Stream'Class)) is null;

   --  Scan the directory for files matching the given pattern.
   procedure Scan_Directory (Controller : in out Controller_Type;
                             Path       : in String;
                             Pattern    : in String;
                             List       : in out Util.Strings.Sets.Set) is null;

   --  Create a file with the given content.
   procedure Create_File (Controller : in out Controller_Type;
                          Path       : in String;
                          Content    : in String) is null;

   --  Create a random path on the target node to store some temporary content.
   function Create_Random_Path (Controller : in out Controller_Type) return String;

private

   protected type Report_Output is
      procedure Print (Kind : in Output_Type;
                       Line : in String;
                       Process : not null access
                         procedure (Kind : in Output_Type;
                                    Line : in String));
   end Report_Output;

   type Controller_Type is abstract limited new Ada.Finalization.Limited_Controlled with record
      Listener  : Listener_Access;
      Usage     : Usage_Type := (others => 0);
      Sec_Gen   : Security.Random.Generator;
      Build_Dir : UString;
   end record;

   --  Returns true if commands are not executed but collected.
   function Is_Dry_Run (Controller : in Controller_Type'Class) return Boolean;

   --  Record a command that is executed during the build step.
   --  The command is not executed but added to the list of commands.
   procedure Record_Command (Controller : in out Controller_Type'Class;
                             Command    : in String);

   --  Set the listener instance.
   procedure Set_Listener (Controller : in out Controller_Type'Class;
                           Listener   : in Listener_Access);

   function Find_Command_Path (Command : in String) return String;

   procedure Read_Input (Report  : in out Report_Output;
                         Stream  : in out Input_Buffer_Stream'Class;
                         Strip_Crlf : in Boolean := False;
                         Kind    : in Output_Type;
                         Process : not null access
                           procedure (Kind : in Output_Type;
                                      Line : in String));

end Porion.Nodes;
