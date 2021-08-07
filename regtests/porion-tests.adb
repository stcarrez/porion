-----------------------------------------------------------------------
--  porion-tests -- Tests for porion commands
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

   end Test_Add;

end Porion.Tests;
