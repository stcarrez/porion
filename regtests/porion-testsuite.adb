-----------------------------------------------------------------------
--  porion-testsuite -- Testsuite for porion
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
with Ada.Text_IO;
with Ada.Directories;

with ADO.Sessions.Sources;
with ADO.Sessions.Factory;

with Util.Log.Loggers;
with Util.Processes;
with Util.Streams.Pipes;
with Util.Streams.Buffered;

with Porion.Configs;
with Porion.Resources.Queries;
with Porion.Resources.Schema;
with Porion.Tests;
with Porion.Reports.Tests;
with Porion.Nodes.Tests;
with Porion.Projects.Tests;
with Porion.Sources.Tests;
with Porion.Tools.Tests;
with Porion.XUnit.Tests;
package body Porion.Testsuite is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Poion.Testsuite");

   Tests      : aliased Util.Tests.Test_Suite;
   Factory    : aliased ADO.Sessions.Factory.Session_Factory;
   Controller : aliased ADO.Sessions.Sources.Data_Source;

   --  ------------------------------
   --  Execute the command and get the output in a string.
   --  ------------------------------
   procedure Execute (T       : in out Test;
                      Command : in String;
                      Result  : out Ada.Strings.Unbounded.Unbounded_String;
                      Status  : in Natural := 0;
                      Source  : in String := GNAT.Source_Info.File;
                      Line    : in Natural := GNAT.Source_Info.Line) is
      P        : aliased Util.Streams.Pipes.Pipe_Stream;
      Buffer   : Util.Streams.Buffered.Input_Buffer_Stream;
   begin
      Log.Info ("Execute: {0}", Command);
      Result := To_UString ("");
      P.Open (Command, Util.Processes.READ_ALL);

      --  Write on the process input stream.
      Result := Ada.Strings.Unbounded.Null_Unbounded_String;
      Buffer.Initialize (P'Unchecked_Access, 8192);
      Buffer.Read (Result);
      P.Close;
      Ada.Text_IO.Put_Line (Ada.Strings.Unbounded.To_String (Result));
      Log.Info ("Command result: {0}", Result);
      Util.Tests.Assert_Equals (T, Status, P.Get_Exit_Status, "Command '" & Command & "' failed",
                                Source, Line);
   end Execute;

   --  ------------------------------
   --  Open and create the database.
   --  ------------------------------
   procedure Create (Service : in out Porion.Services.Context_Type;
                     Path    : in String;
                     Remove  : in Boolean) is
      Schema : constant Porion.Resources.Content_Access
        := Porion.Resources.Schema.Get_Content ("create-porion_agent-sqlite");
   begin
      Porion.Configs.Set (Porion.Configs.WORKSPACE_DIR_NAME, Path);
      if Ada.Directories.Exists (Path) and Remove then
         Ada.Directories.Delete_Tree (Path);
      end if;

      if not Ada.Directories.Exists (Path) then
         Ada.Directories.Create_Path (Path);
         Ada.Directories.Create_Path (Porion.Configs.Get_Config_Directory);
      end if;
      Service.Open (Porion.Resources.Queries.Get_Content'Access, Schema);
   end Create;

   function Suite return Util.Tests.Access_Test_Suite is
   begin
      Porion.Tests.Add_Tests (Tests'Access);
      Porion.Tools.Tests.Add_Tests (Tests'Access);
      Porion.XUnit.Tests.Add_Tests (Tests'Access);
      Porion.Sources.Tests.Add_Tests (Tests'Access);
      Porion.Nodes.Tests.Add_Tests (Tests'Access);
      Porion.Projects.Tests.Add_Tests (Tests'Access);
      Porion.Reports.Tests.Add_Tests (Tests'Access);
      return Tests'Access;
   end Suite;

   --  ------------------------------
   --  Get the writeable connection database to be used for the unit tests
   --  ------------------------------
   function Get_Master_Database return ADO.Sessions.Master_Session is
   begin
      return Factory.Get_Master_Session;
   end Get_Master_Database;

   --  ------------------------------
   --  Initialize the test database
   --  ------------------------------
   procedure Initialize (Name : in String) is
   begin
      Controller.Set_Connection (Name);
      --  Factory.Create (Controller);
   end Initialize;

end Porion.Testsuite;
