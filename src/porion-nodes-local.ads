-----------------------------------------------------------------------
--  porion-nodes-local -- Local build node management
--  Copyright (C) 2021-2022 Stephane Carrez
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
with Util.Strings.Vectors;
private with Util.Processes;
private package Porion.Nodes.Local is

   type Controller_Type is limited new Porion.Nodes.Controller_Type with private;
   type Controller_Access is access all Controller_Type'Class;

   --  Create the controller for the management of the given build node.
   function Create (Listener : in Listener_Access) return Nodes.Controller_Access;

   --  Set the environment variables when running commands in the build node.
   overriding
   procedure Set_Environment (Controller : in out Controller_Type;
                              Env        : in Util.Strings.Maps.Map);

   --  Execute the command in the working directory and for each output
   --  line produced by the command call the Process procedure.
   overriding
   procedure Execute (Controller  : in out Controller_Type;
                      Args        : in Util.Strings.Vectors.Vector;
                      Working_Dir : in String := "";
                      Process     : not null access
                           procedure (Stream : in out Input_Buffer_Stream'Class);
                      Status      : out Integer);

   --  Create the directory and optionally make sure it is cleaned.
   overriding
   procedure Create_Directory (Controller : in out Controller_Type;
                               Path       : in String;
                               Clean      : in Boolean;
                               Process    : not null access
                                 procedure (Line : in String));

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
                             List       : in out Util.Strings.Vectors.Vector);

private

   type Controller_Type is limited new Porion.Nodes.Controller_Type with record
      Env : Util.Strings.Maps.Map;
   end record;

   --  Set the environment variables before launching the process.
   procedure Set_Environment (Controller : in out Controller_Type;
                              Proc       : in out Util.Processes.Process);

end Porion.Nodes.Local;
