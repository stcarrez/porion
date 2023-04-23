-----------------------------------------------------------------------
--  porion-tests -- Tests for porion commands
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
with Ada.Directories;

with Util.Test_Caller;
package body Porion.Tests is

   package Caller is new Util.Test_Caller (Test, "Porion.Commands");

   function Tool return String is
      ("bin/porion");

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite) is
   begin
      Caller.Add_Test (Suite, "Test Porion.Command.Init",
                       Test_Init'Access);
      Caller.Add_Test (Suite, "Test Porion.Command.Add",
                       Test_Add'Access);
      Caller.Add_Test (Suite, "Test Porion.Command.Add (with unit tests)",
                       Test_Add_With_Tests'Access);
      Caller.Add_Test (Suite, "Test Porion.Command.Step (with unit tests)",
                       Test_Add_Recipe_With_Tests'Access);
      Caller.Add_Test (Suite, "Test Porion.Command.Remove (recipe)",
                       Test_Remove_Recipe_With_Tests'Access);
   end Add_Tests;

   procedure Test_Init (T : in out Test) is
      Dir    : constant String := Util.Tests.Get_Test_Path ("init");
      Config : constant String := Util.Tests.Get_Test_Path ("porion.config");
      Result : Ada.Strings.Unbounded.Unbounded_String;
   begin
      if Ada.Directories.Exists (Dir) then
         Ada.Directories.Delete_Tree (Dir);
      end if;
      if Ada.Directories.Exists (Config) then
         Ada.Directories.Delete_File (Config);
      end if;
      T.Execute (Command => Tool & " -c " & Config & " init " & Dir,
                 Result  => Result,
                 Status  => 0);

      T.Assert (Ada.Directories.Exists (Dir),
                "Porion directory not created");
      T.Assert (Ada.Directories.Exists (Config),
                "Porion config not created");

   end Test_Init;

   procedure Test_Add (T : in out Test) is
      Dir    : constant String := Util.Tests.Get_Test_Path ("init");
      Config : constant String := Util.Tests.Get_Test_Path ("porion.config");
      Repo   : constant String := "https://github.com/Ada-France/aflex.git";
      Result : Ada.Strings.Unbounded.Unbounded_String;
   begin
      T.Test_Init;

      T.Execute (Command => Tool & " -c " & Config & " add " & Repo,
                 Result  => Result,
                 Status  => 0);

      T.Assert (Ada.Directories.Exists (Dir),
                "Porion directory not created");
      T.Assert (Ada.Directories.Exists (Config),
                "Porion config not created");

      T.Execute (Command => Tool & " -c " & Config & " build aflex",
                 Result  => Result,
                 Status  => 0);

      T.Execute (Command => Tool & " -c " & Config & " info aflex",
                 Result  => Result,
                 Status  => 0);
      Util.Tests.Assert_Matches (T, "aflex", Result,
                                 "Invalid project info");

      T.Execute (Command => Tool & " -c " & Config & " info --recipes aflex",
                 Result  => Result,
                 Status  => 0);
      Util.Tests.Assert_Matches (T, "aflex#master~main@localhost", Result,
                                 "Invalid project info");

      T.Execute (Command => Tool & " -c " & Config & " list --projects",
                 Result  => Result,
                 Status  => 0);

      Util.Tests.Assert_Matches (T, "aflex", Result, "Invalid project list");

   end Test_Add;

   --  ------------------------------
   --  Test registration of a project, build and scan of some fake unit tests.
   --  ------------------------------
   procedure Test_Add_With_Tests (T : in out Test) is
      Repo   : constant String := Util.Tests.Get_Path ("regtests/files/fake-test-1.0.tar.gz");
      Dir    : constant String := Util.Tests.Get_Test_Path ("init");
      Config : constant String := Util.Tests.Get_Test_Path ("porion.config");
      Result : Ada.Strings.Unbounded.Unbounded_String;
   begin
      T.Test_Init;

      T.Execute (Command => Tool & " -c " & Config & " add " & Repo,
                 Result  => Result,
                 Status  => 0);

      T.Assert (Ada.Directories.Exists (Dir),
                "Porion directory not created");
      T.Assert (Ada.Directories.Exists (Config),
                "Porion config not created");

      T.Execute (Command => Tool & " -c " & Config
                 & " step --insert 4 fake-test-1.0 xunit 'regtests/results/TEST-*.xml'",
                 Result  => Result,
                 Status  => 0);

      T.Execute (Command => Tool & " -c " & Config & " build fake-test-1.0",
                 Result  => Result,
                 Status  => 0);

      T.Execute (Command => Tool & " -c " & Config & " info fake-test-1.0",
                 Result  => Result,
                 Status  => 0);
      Util.Tests.Assert_Matches (T, "fake-test-1.0", Result,
                                 "Invalid project info");

      T.Execute (Command => Tool & " -c " & Config & " info --recipes fake-test-1.0",
                 Result  => Result,
                 Status  => 0);
      Util.Tests.Assert_Matches (T, "fake-test-1.0#main~main@localhost", Result,
                                 "Invalid project recipe");

      T.Execute (Command => Tool & " --no-color -c " & Config & " info --builds fake-test-1.0",
                 Result  => Result,
                 Status  => 0);
      Util.Tests.Assert_Matches (T, "fake-test-1.0#main~main@localhost:1", Result,
                                 "Invalid project build");
      Util.Tests.Assert_Matches
       (T, "fake-test-1.0:main~main@localhost:1               .*main[ ]+OK[ ]+46[ ]+10", Result,
        "Invalid project build tests");

      T.Execute (Command => Tool & " -c " & Config & " list --projects",
                 Result  => Result,
                 Status  => 0);

      Util.Tests.Assert_Matches (T, "fake-test-1.0", Result, "Invalid project list");
   end Test_Add_With_Tests;

   --  ------------------------------
   --  Test registration of a project, adding recipes and scan of some fake unit tests.
   --  ------------------------------
   procedure Test_Add_Recipe_With_Tests (T : in out Test) is
      Repo   : constant String := Util.Tests.Get_Path ("regtests/files/fake-test-1.0.tar.gz");
      Dir    : constant String := Util.Tests.Get_Test_Path ("init");
      Config : constant String := Util.Tests.Get_Test_Path ("porion.config");
      Result : Ada.Strings.Unbounded.Unbounded_String;
   begin
      T.Test_Init;

      T.Execute (Command => Tool & " -c " & Config & " add " & Repo,
                 Result  => Result,
                 Status  => 0);

      T.Assert (Ada.Directories.Exists (Dir),
                "Porion directory not created");
      T.Assert (Ada.Directories.Exists (Config),
                "Porion config not created");

      T.Execute (Command => Tool & " -c " & Config
                 & " step --insert 4 fake-test-1.0 xunit 'regtests/results/TEST-*.xml'",
                 Result  => Result,
                 Status  => 0);

      T.Execute (Command => Tool & " -c " & Config
                 & " add --recipe fake-test-1.0~new fake-test-1.0",
                 Result  => Result,
                 Status  => 0);
      Util.Tests.Assert_Matches (T, "New recipe added", Result,
                                 "add recipe failed");

      --  Add again with the same name, it must be refused.
      T.Execute (Command => Tool & " -c " & Config
                 & " add --recipe fake-test-1.0~new fake-test-1.0",
                 Result  => Result,
                 Status  => 1);
      Util.Tests.Assert_Matches (T, "recipe name 'new' is already used", Result,
                                 "invalid error message");

      T.Execute (Command => Tool & " -c " & Config & " list --projects",
                 Result  => Result,
                 Status  => 0);

      Util.Tests.Assert_Matches (T, "fake-test-1.0", Result, "Invalid project list");
   end Test_Add_Recipe_With_Tests;

   --  ------------------------------
   --  Test registration of a project, adding recipes, building and removing a recipe with builds.
   --  ------------------------------
   procedure Test_Remove_Recipe_With_Tests (T : in out Test) is
      Config : constant String := Util.Tests.Get_Test_Path ("porion.config");
      Result : Ada.Strings.Unbounded.Unbounded_String;
   begin
      T.Test_Add_Recipe_With_Tests;

      T.Execute (Command => Tool & " -c " & Config
                 & " remove fake-test-1.0~new",
                 Result  => Result,
                 Status  => 0);
      Util.Tests.Assert_Matches (T, "Project recipe 'fake-test-1.0~new' is removed",
                                 Result,
                                 "invalid message");

      T.Execute (Command => Tool & " -c " & Config
                 & " remove fake-test-1.0~new",
                 Result  => Result,
                 Status  => 1);
      Util.Tests.Assert_Matches (T, "project 'fake-test-1.0' has no recipe named 'new'",
                                 Result,
                                 "invalid error message");

      T.Execute (Command => Tool & " -c " & Config
                 & " remove fake-test-1.0#branch-test",
                 Result  => Result,
                 Status  => 1);
      Util.Tests.Assert_Matches (T, "project 'fake-test-1.0' has no branch named 'branch-test'",
                                 Result,
                                 "invalid error message");

      T.Execute (Command => Tool & " -c " & Config
                 & " remove fake-test-1.0#main@build-node",
                 Result  => Result,
                 Status  => 1);
      Util.Tests.Assert_Matches (T, "build node 'build-node' not found",
                                 Result,
                                 "invalid error message");

   end Test_Remove_Recipe_With_Tests;

end Porion.Tests;
