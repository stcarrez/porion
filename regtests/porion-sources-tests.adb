-----------------------------------------------------------------------
--  porion-sources-tests -- Tests for sources management
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
with Porion.Sources.Git;
with Porion.Sources.Files;
with Porion.Sources.Factories;
package body Porion.Sources.Tests is

   package Caller is new Util.Test_Caller (Test, "Porion.Sources");

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite) is
   begin
      Caller.Add_Test (Suite, "Test Porion.Sources.Guess (Git)",
                       Test_Guess_Git'Access);
      Caller.Add_Test (Suite, "Test Porion.Sources.Guess (Files)",
                       Test_Guess_Files'Access);
   end Add_Tests;

   procedure Test_Guess_Git (T : in out Test) is
      Logger : Porion.Loggers.Logger_Type;
      Result : Porion.Sources.Source_Info_Type;
      Config : Porion.Configs.Config_Type;
   begin
      Porion.Sources.Factories.Guess (Path   => ".",
                                      Config => Config,
                                      Result => Result,
                                      Logger => Logger);

      T.Assert_Equals ("porion", Result.Name, "invalid project name");
      T.Assert_Equals (Porion.Sources.Git.SOURCE_KIND, Result.Kind, "invalid source kind");

      Porion.Sources.Factories.Guess (Path   => "src/model",
                                      Config => Config,
                                      Result => Result,
                                      Logger => Logger);

      T.Assert_Equals ("porion", Result.Name, "invalid project name");
      T.Assert_Equals (Porion.Sources.Git.SOURCE_KIND, Result.Kind, "invalid source kind");
   end Test_Guess_Git;

   procedure Test_Guess_Files (T : in out Test) is
      Path   : constant String := Util.Tests.Get_Path ("regtests/files/hello-1.0.tar.gz");
      Logger : Porion.Loggers.Logger_Type;
      Result : Porion.Sources.Source_Info_Type;
      Config : Porion.Configs.Config_Type;
   begin
      Porion.Sources.Factories.Guess (Path   => Path,
                                      Config => Config,
                                      Result => Result,
                                      Logger => Logger);

      T.Assert_Equals ("hello-1.0", Result.Name, "invalid project name");
      T.Assert_Equals (Porion.Sources.Files.SOURCE_KIND, Result.Kind, "invalid source kind");
   end Test_Guess_Files;

end Porion.Sources.Tests;
