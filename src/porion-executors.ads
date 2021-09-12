-----------------------------------------------------------------------
--  porion-executors -- Execute commands for builders or source controllers
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
with Ada.Finalization;
with EL.Expressions;
with Util.Properties;
with Util.Strings.Vectors;
with Porion.Loggers;
with Porion.Builds;
package Porion.Executors is

   type Executor_Type is limited new Ada.Finalization.Limited_Controlled with private;

   --  Returns true if commands are not executed but collected.
   function Is_Dry_Run (Executor : in Executor_Type) return Boolean;

   --  Enable the dry run execution mode.
   procedure Enable_Dry_Run (Executor : in out Executor_Type);

   --  Get the execution status.
   function Get_Status (Executor : in Executor_Type) return Integer;

   --  Set the execution status.
   procedure Set_Status (Executor : in out Executor_Type;
                         Status   : in Integer);

   --  Set the current execution step when building a project.
   procedure Set_Step (Executor : in out Executor_Type;
                       Step     : in Porion.Builds.Step_Type);

   procedure Execute (Executor    : in out Executor_Type;
                      Command     : in EL.Expressions.Expression;
                      Parameters  : in Util.Properties.Manager;
                      Process     : not null access procedure (Line : in String);
                      Working_Dir : in String := "";
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer);

   procedure Execute (Executor    : in out Executor_Type;
                      Command     : in EL.Expressions.Expression;
                      Parameters  : in Util.Properties.Manager;
                      Working_Dir : in String := "";
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer);

   procedure Execute (Executor    : in out Executor_Type;
                      Command     : in String;
                      Process     : not null access procedure (Line : in String);
                      Working_Dir : in String := "";
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer);

   procedure Create_Logger (Executor : in out Executor_Type;
                            Dir      : in String;
                            Name     : in String);

   --  Write the line on the logger.
   procedure Log (Executor : in out Executor_Type;
                  Line     : in String);

   --  Get the commands that were collected during execution and clear the current list.
   procedure Fetch_Commands (Executor : in out Executor_Type;
                             Commands : out Util.Strings.Vectors.Vector);

private

   type Executor_Type is limited new Ada.Finalization.Limited_Controlled with record
      Dry_Run  : Boolean := False;
      Commands : Util.Strings.Vectors.Vector;
      Status   : Integer := 0;
      Step     : Porion.Builds.Step_Type;
      Logger   : Porion.Loggers.Logger_Type;
   end record;

end Porion.Executors;
