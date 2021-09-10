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
with ADO.Sessions;
with Porion.Configs;
with Porion.Sources;
with Porion.XUnit.Analysis;
with Porion.XUnit.Parsers;
with Porion.Builds.Models;
with Porion.Services;
with Porion.Resources.Queries;
with Porion.Resources.Schema;
with Porion.Builds.Services;
with Porion.Projects.Services;
package body Porion.XUnit.Tests is

   use Ada.Strings.Unbounded;

   package Caller is new Util.Test_Caller (Test, "Porion.Tests");

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite) is
   begin
      Caller.Add_Test (Suite, "Test Porion.Tests.Save",
                       Test_Scanner'Access);
   end Add_Tests;

   procedure Test_Scanner (T : in out Test) is
      Results   : Analysis.Test_Results;
      Path      : constant String := "regtests/files/TEST-SQLite-Users.Tests.xml";
      Path2     : constant String := "regtests/files/TEST-Dynamo.xml";
      Service   : Porion.Projects.Services.Context_Type;
      Builder   : Porion.Builds.Services.Context_Type;
      Info      : Porion.Sources.Source_Info_Type;
      Branch    : Porion.Sources.Branch_Type;
      Build     : Porion.Builds.Models.Build_Ref;
      Session   : ADO.Sessions.Master_Session;
   begin
      Branch.Tag := To_Unbounded_String ("master");
      Branch.Build_Count := 0;
      Branch.Last_Tag := To_Unbounded_String ("123");
      Porion.Configs.Initialize ("regtests/files/porion.properties");
      Service.Open (Porion.Resources.Queries.Get_Content'Access, null);
      begin
         Service.Load_Node (Hostname => "localhost");

      exception
         when Porion.Services.Name_Used =>
            Service.Add_Node (Hostname => "localhost",
                              Login    => "porion");
      end;

      begin
         Service.Load_Project ("ada-lzma");

      exception
         when Porion.Services.Name_Used =>
            Info.Kind := Porion.Sources.SRC_GIT;
            Info.Name := To_UString ("ada-lzma");
            Info.URI := To_UString ("git://github.com/stcarrez/ada-lzma.git");
            Service.Add_Project (Info);
      end;
      Service.Add_Branch ("master", Branch, True);
      Builder.Open (Service);
      Builder.Start_Build (Branch_Name => "master",
                           Branch      => Branch);
      Porion.XUnit.Parsers.Scan (Path, Results);
      Porion.XUnit.Parsers.Scan (Path2, Results);
      --  Porion.XUnit.Parsers.Scan ("regtests/files/many", "*.xml", Results);
      Build := Builder.Get_Build;
      Session := Service.Get_Database;
      Porion.XUnit.Analysis.Save (Results => Results,
                                  Build   => Build,
                                  Session => Session);
      T.Assert (True, "Foo is ok");
   end Test_Scanner;

end Porion.XUnit.Tests;
