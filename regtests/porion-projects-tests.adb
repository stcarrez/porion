-----------------------------------------------------------------------
--  porion-projects-tests -- Tests for projects package
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
package body Porion.Projects.Tests is

   use Util.Tests;

   package Caller is new Util.Test_Caller (Test, "Porion.Projects");

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite) is
   begin
      Caller.Add_Test (Suite, "Test Porion.Projects.Parse",
                       Test_Parse'Access);
      Caller.Add_Test (Suite, "Test Porion.Projects.To_String",
                       Test_To_String'Access);
   end Add_Tests;

   --  ------------------------------
   --  Test parsing a project identification string.
   --  ------------------------------
   procedure Test_Parse (T : in out Test) is
      procedure Check (Ident, Name, Branch, Recipe, Node : in String);

      procedure Check (Ident, Name, Branch, Recipe, Node : in String) is
         Result : Ident_Type;
      begin
         Result := Parse (Ident);
         Assert_Equals (T, Name, To_String (Result.Name),
                        "bad project name");
         Assert_Equals (T, Branch, To_String (Result.Branch),
                        "bad branch name");
         Assert_Equals (T, Recipe, To_String (Result.Recipe),
                        "bad recipe name");
         Assert_Equals (T, Node, To_String (Result.Node),
                        "bad node name");
      end Check;

   begin
      Check ("project-name", "project-name", "", "", "");

      Check ("project-name@hostname", "project-name", "", "", "hostname");

      Check ("project^maintenance", "project", "maintenance", "", "");

      Check ("project^maintenance@host", "project", "maintenance", "", "host");

      Check ("prj~3", "prj", "", "3", "");

      Check ("prj~3@host", "prj", "", "3", "host");

   end Test_Parse;

   --  ------------------------------
   --  Test converting the Ident_Type back to a string.
   --  ------------------------------
   procedure Test_To_String (T : in out Test) is
      procedure Check (Ident : in String);

      procedure Check (Ident : in String) is
         Result : Ident_Type;
      begin
         Result := Parse (Ident);
         Assert_Equals (T, Ident, To_String (Result), "invalid To_String");
      end Check;

   begin
      Check ("project@host");
      Check ("prj^branch");
      Check ("prj~config");
      Check ("prj^branch@hostname");
   end Test_To_String;

end Porion.Projects.Tests;
