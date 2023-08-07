-----------------------------------------------------------------------
--  porion-reports-tests -- Tests for reports
--  Copyright (C) 2022 Stephane Carrez
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

package body Porion.Reports.Tests is

   package Caller is new Util.Test_Caller (Test, "Porion.Reports");

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite) is
   begin
      Caller.Add_Test (Suite, "Test Porion.Reports.Format",
                       Test_Format'Access);
   end Add_Tests;

   procedure Test_Format (T : in out Test) is
   begin
      T.Assert_Equals ("0.123", Format (Millisecond_Type (123)), "invalid format");
      T.Assert_Equals ("1.234", Format (Millisecond_Type (1234)), "invalid format");
      T.Assert_Equals ("12.345", Format (Millisecond_Type (12345)), "invalid format");
      T.Assert_Equals ("2:03", Format (Millisecond_Type (123450)), "invalid format");
      T.Assert_Equals ("20:34", Format (Millisecond_Type (1234560)), "invalid format");
   end Test_Format;

end Porion.Reports.Tests;
