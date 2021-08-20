-----------------------------------------------------------------------
--  porion-tools-tests -- Tests for tools
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

with Util.Test_Caller;
package body Porion.Tools.Tests is

   package Caller is new Util.Test_Caller (Test, "tools");

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite) is
   begin
      Caller.Add_Test (Suite, "Test porion.tools.Foo",
                       Test_Foo'Access);
   end Add_Tests;

   procedure Test_Foo (T : in out Test) is
   begin
      T.Assert (True, "Foo is ok");
   end Test_Foo;

end Porion.Tools.Tests;
