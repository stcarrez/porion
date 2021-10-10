-----------------------------------------------------------------------
--  porion-testsuite -- Testsuite for porion
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
with GNAT.Source_Info;
with Ada.Strings.Unbounded;

with Util.Tests;

with ADO.Sessions;
with Porion.Services;
package Porion.Testsuite is

   type Test is new Util.Tests.Test with null record;

   --  Execute the command and get the output in a string.
   procedure Execute (T       : in out Test;
                      Command : in String;
                      Result  : out Ada.Strings.Unbounded.Unbounded_String;
                      Status  : in Natural := 0;
                      Source  : in String := GNAT.Source_Info.File;
                      Line    : in Natural := GNAT.Source_Info.Line);

   --  Open and create the database.
   procedure Create (Service : in out Porion.Services.Context_Type;
                     Path    : in String;
                     Remove  : in Boolean);

   function Suite return Util.Tests.Access_Test_Suite;

   --  Get the writeable connection database to be used for the unit tests
   function Get_Master_Database return ADO.Sessions.Master_Session;

   --  Initialize the test database
   procedure Initialize (Name : in String);

end Porion.Testsuite;
