-----------------------------------------------------------------------
--  porion-executors -- Execute commands for builders or source controllers
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
with Ada.Containers.Indefinite_Vectors;
with EL.Expressions;
with Util.Properties;
with Util.Strings.Vectors;
with Util.Strings.Sets;
with Util.Streams.Buffered;
with ADO;
with Porion.Logs;
with Porion.Builds.Environments;
with Porion.Nodes;
with Porion.Services;
package Porion.Executors is

   subtype Input_Buffer_Stream is Util.Streams.Buffered.Input_Buffer_Stream;
   subtype Output_Type is Porion.Nodes.Output_Type;
   use all type Porion.Nodes.Output_Type;

   type Command_Type (Len : Positive) is record
      Step    : Porion.Builds.Step_Type;
      Mode    : Porion.Builds.Execution_Type;
      Command : String (1 .. Len);
   end record;

   package Command_Vectors is
     new Ada.Containers.Indefinite_Vectors (Index_Type   => Positive,
                                            Element_Type => Command_Type);

   subtype Command_Vector is Command_Vectors.Vector;
   subtype Command_Cursor is Command_Vectors.Cursor;

   type Executor_Type is limited new Ada.Finalization.Limited_Controlled
     and Porion.Nodes.Listener_Type with private;

   --  Returns true if commands are not executed but collected.
   overriding
   function Is_Dry_Run (Executor : in Executor_Type) return Boolean;

   --  Returns true if this executor is configured and can be used.
   function Is_Configured (Executor : in Executor_Type) return Boolean;

   --  Returns true if this executor runs locally.
   function Is_Local (Executor : in Executor_Type) return Boolean;

   --  Enable the dry run execution mode.
   procedure Enable_Dry_Run (Executor : in out Executor_Type);

   --  Enable writing command output to stdout.
   procedure Enable_Log (Executor : in out Executor_Type);

   --  Get the execution status.
   function Get_Status (Executor : in Executor_Type) return Integer;

   --  Get the usage when running the executor on build nodes.
   function Get_Usage (Executor : in Executor_Type) return Nodes.Usage_Type;

   --  Set the execution status.
   procedure Set_Status (Executor : in out Executor_Type;
                         Status   : in Integer);

   --  Set the current execution step when building a project.
   procedure Set_Step (Executor : in out Executor_Type;
                       Step     : in Porion.Builds.Step_Type;
                       Mode     : in Porion.Builds.Execution_Type;
                       Ident    : in ADO.Identifier);

   --  Prepare the executor to build the recipe configured on the service.
   procedure Prepare_Build (Executor : in out Executor_Type;
                            Service  : in out Porion.Services.Context_Type) with
     Pre => Service.Is_Open and Service.Has_Recipe;

   --  Prepare the executor to execute the given step number.
   procedure Prepare_Step (Executor : in out Executor_Type;
                           Step     : in Positive);

   --  Create the directory and optionally make sure it is cleaned.
   procedure Create_Directory (Executor : in out Executor_Type;
                               Path     : in String;
                               Clean    : in Boolean);

   --  Export the file described by `Source_Path` to build in the directory
   --  defined by `Build_Path`.  Update `Exported_Path` to indicate the path
   --  of the exported file as seen from the build node.  If the build node
   --  is local, the operation does nothing.  If the build node is remote,
   --  it must be copied so that it is accessed from the build node.
   procedure Export_File (Executor      : in out Executor_Type;
                          Source_Path   : in String;
                          Build_Path    : in String;
                          Exported_Path : out UString);

   procedure Execute (Executor    : in out Executor_Type;
                      Command     : in EL.Expressions.Expression;
                      Parameters  : in Util.Properties.Manager;
                      Process     : not null access
                        procedure (Kind : in Output_Type;
                                   Line : in String);
                      Working_Dir : in String := "";
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer) with
      Pre => Executor.Is_Configured;

   procedure Execute (Executor    : in out Executor_Type;
                      Command     : in EL.Expressions.Expression;
                      Parameters  : in Util.Properties.Manager;
                      Working_Dir : in String := "";
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer) with
      Pre => Executor.Is_Configured;

   --  Read the file with the controller and execute the `Process` procedure with the
   --  input buffer stream that gives access to the file content.
   procedure Read_File (Executor    : in out Executor_Type;
                        Path       : in String;
                        Process    : not null access
                           procedure (Stream : in out Input_Buffer_Stream'Class)) with
      Pre => Executor.Is_Configured;

   --  Scan the directory for files matching the given pattern.
   procedure Scan_Directory (Executor    : in out Executor_Type;
                             Path       : in String;
                             Pattern    : in String;
                             Excludes   : in Util.Strings.Vectors.Vector;
                             List       : in out Util.Strings.Sets.Set) with
      Pre => Executor.Is_Configured;

   procedure Create_Logger (Executor : in out Executor_Type;
                            Dir      : in String;
                            Name     : in String);

   --  Create a specific logger to record the next command in a separate file.
   procedure Command_Logger (Executor : in out Executor_Type;
                             Name     : in String) with
      Pre => Executor.Is_Configured;

   --  Write the line on the logger.
   procedure Log (Executor : in out Executor_Type;
                  Source   : in Porion.Logs.Source_Type;
                  Line     : in String);

   --  Clear and reset the executor.
   procedure Clear (Executor : in out Executor_Type);

   --  Get the commands that were collected during execution and clear the current list.
   procedure Fetch_Commands (Executor : in out Executor_Type;
                             Commands : out Command_Vector);

   procedure Execute (Executor    : in out Executor_Type;
                      Command     : in String;
                      Process     : not null access
                        procedure (Kind : in Output_Type;
                                   Line : in String);
                      Working_Dir : in String := "";
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer) with
      Pre => Executor.Is_Configured;

   --  Record a command that is executed during the build step.
   --  The command is not executed but added to the list of commands.
   overriding
   procedure Record_Command (Executor : in out Executor_Type;
                             Command  : in String);

private

   type Executor_Type is limited new Ada.Finalization.Limited_Controlled
     and Porion.Nodes.Listener_Type with record
      Listener   : Nodes.Listener_Access;
      Dry_Run    : Boolean := False;
      Output_Log : Boolean := False;
      Status     : Integer := 0;
      Step       : Porion.Builds.Step_Type := Porion.Builds.STEP_CHECKOUT;
      Mode       : Porion.Builds.Execution_Type := Porion.Builds.EXEC_NO_ERROR;
      Commands   : Command_Vector;
      Logger     : Porion.Logs.Logger_Type;
      Controller : Porion.Nodes.Controller_Access;
      Local      : Porion.Nodes.Controller_Access;
      Log_Dir    : UString;
      Cmd_Logger : Porion.Logs.Logger_Type;
      Use_Cmd_Logger : Boolean := False;
      Env        : Porion.Builds.Environments.Environment_Type;
   end record;

end Porion.Executors;
