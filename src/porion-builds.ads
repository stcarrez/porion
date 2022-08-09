-----------------------------------------------------------------------
--  porion-builds -- Continuous integration controller
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
with Util.Beans.Objects.Enums;
package Porion.Builds is

   type Step_Type is (STEP_CHECKOUT, STEP_SETUP, STEP_GENERATE, STEP_CONFIGURE, STEP_MAKE,
                      STEP_TEST, STEP_PACKAGE, STEP_INSTALL, STEP_PUBLISH, STEP_METRIC);

   for Step_Type use (STEP_CHECKOUT => -1,
                      STEP_SETUP => 0,
                      STEP_GENERATE => 1,
                      STEP_CONFIGURE => 2,
                      STEP_MAKE => 3,
                      STEP_TEST => 4,
                      STEP_PACKAGE => 5,
                      STEP_INSTALL => 6,
                      STEP_PUBLISH => 7,
                      STEP_METRIC => 8);

   package Step_Type_Objects is
      new Util.Beans.Objects.Enums (Step_Type);

   type Nullable_Step_Type is record
      Is_Null : Boolean := True;
      Value   : Step_Type;
   end record;

   type Execution_Type is (EXEC_DISABLED, EXEC_NO_ERROR, EXEC_IGNORE_ERROR);
   for Execution_Type use (EXEC_DISABLED => 0, EXEC_NO_ERROR => 1, EXEC_IGNORE_ERROR => 2);
   package Execution_Type_Objects is
      new Util.Beans.Objects.Enums (Execution_Type);

   type Nullable_Execution_Type is record
      Is_Null : Boolean := True;
      Value   : Execution_Type;
   end record;

end Porion.Builds;
