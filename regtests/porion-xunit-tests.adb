-----------------------------------------------------------------------
--  porion-xunit-tests -- Tests for tools
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
with Porion.Configs;
with Porion.Sources;
with Porion.XUnit.Analysis;
with Porion.XUnit.Parsers;
with Porion.Builds.Models;
with Porion.Services;
with Porion.Executors;
with Porion.Nodes.Services;
with Porion.Builds.Services;
with Porion.Projects.Services;
with Porion.Testsuite;
package body Porion.XUnit.Tests is

   use Ada.Strings.Unbounded;

   package Caller is new Util.Test_Caller (Test, "Porion.Tests");

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite) is
   begin
      Caller.Add_Test (Suite, "Test Porion.Tests.Save",
                       Test_Scanner'Access);
   end Add_Tests;

   procedure Test_Scanner (T : in out Test) is
      Dir       : constant String := Util.Tests.Get_Test_Path ("xunit");
      Results   : Analysis.Test_Results;
      Path      : constant String := "regtests/files/TEST-SQLite-Users.Tests.xml";
      Path2     : constant String := "regtests/files/TEST-Dynamo.xml";
      Path3     : constant String := "regtests/files/TEST-AKT.Tools.xml";
      Service   : Porion.Services.Context_Type;
      Builder   : Porion.Builds.Services.Context_Type;
      Info      : Porion.Sources.Source_Info_Type;
      Branch    : Porion.Sources.Branch_Type;
      Executor  : Porion.Executors.Executor_Type;
      Recipe    : Porion.Builds.Models.Recipe_Ref;
   begin
      Branch.Tag := To_Unbounded_String ("master");
      Branch.Build_Count := 0;
      Branch.Last_Tag := To_Unbounded_String ("123");
      Porion.Configs.Initialize ("regtests/files/porion.properties");
      Porion.Testsuite.Create (Service, Dir, True);
      Porion.Testsuite.Add_Build_Node (Service, "localhost");
      begin
         Service.Load_Project ("ada-lzma");

      exception
         when Porion.Services.Not_Found =>
            Info.Kind := Porion.Sources.SRC_GIT;
            Info.Name := To_UString ("ada-lzma");
            Info.URI := To_UString ("git://github.com/stcarrez/ada-lzma.git");
            Projects.Services.Add_Project (Service, Info);
      end;
      Projects.Services.Add_Branch (Service, "master", Branch, True);
      Builder.Open (Service);
      Recipe.Set_Branch (Service.Branch);
      Recipe.Set_Project (Service.Project);
      Recipe.Save (Service.DB);
      Builds.Services.Start_Build (Service  => Service,
                                   Recipe   => Recipe,
                                   Executor => Executor);
      Porion.XUnit.Parsers.Scan (Path, Results);
      Porion.XUnit.Parsers.Scan (Path2, Results);
      Porion.XUnit.Parsers.Scan (Path3, Results);
      --  Porion.XUnit.Parsers.Scan ("regtests/files/many", "*.xml", Results);
      Porion.XUnit.Analysis.Save (Results => Results,
                                  Build   => Service.Build,
                                  Session => Service.DB);
      T.Assert (True, "Foo is ok");
   end Test_Scanner;

end Porion.XUnit.Tests;
