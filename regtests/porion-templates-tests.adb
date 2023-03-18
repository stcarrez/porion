-----------------------------------------------------------------------
--  porion-templates-tests -- Unit tests for porion templates
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

with Util.Assertions;
with Util.Test_Caller;

with Porion.Configs;
with Porion.Executors;
with Porion.Templates.Parser;
package body Porion.Templates.Tests is

   package Caller is new Util.Test_Caller (Test, "Porion.Templates");

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite) is
   begin
      Caller.Add_Test (Suite, "Test Porion.Templates.Parser.Load",
                       Test_Parse_Template'Access);
      Caller.Add_Test (Suite, "Test Porion.Templates.Parser.Load (Error)",
                       Test_Parse_Error'Access);
   end Add_Tests;

   --  Test parsing several valid templates.
   procedure Test_Parse_Template (T : in out Test) is
      Path     : constant String := Util.Tests.Get_Path ("regtests/files/templates");
      Repository : Porion.Templates.Repository_Type;
   begin
      Parser.Load (Path & "/gnu.porion", Repository);
      Parser.Load (Path & "/local.porion", Repository);
      Parser.Load (Path & "/ado.porion", Repository);
      Parser.Load (Path & "/awa.porion", Repository);
   end Test_Parse_Template;

   --  Test parsing several valid templates.
   procedure Test_Parse_Error (T : in out Test) is
      Path     : constant String := Util.Tests.Get_Path ("regtests/files/bad-templates");
      Repository : Porion.Templates.Repository_Type;
   begin
      Parser.Load (Path & "/bad-rule-1.porion", Repository);
   end Test_Parse_Error;

end Porion.Templates.Tests;
