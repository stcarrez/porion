-----------------------------------------------------------------------
--  porion-builders -- Continuous integration controller
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
with Ada.Containers.Vectors;
with Util.Strings.Vectors;
with Util.Serialize.IO;
with Porion.Loggers;
with Porion.Builds.Models;
with Porion.Executors;
package Porion.Builders is

   --  The builder priority is used when several builders are identified.
   --  It allows to make a builder more favorable and used for the build process.
   type Priority_Type is new Integer range 1 .. 255;

   type Builder_Type is (BUILDER_EMPTY,
                         BUILDER_MAKE,
                         BUILDER_GPRBUILD,
                         BUILDER_MAVEN,
                         BUILDER_CMAKE,
                         BUILDER_SCONS,
                         BUILDER_TRAVIS,
                         BUILDER_GRADLE);

   type Step_Type is (STEP_SETUP,
                      STEP_GENERATE,
                      STEP_CONFIGURE,
                      STEP_MAKE,
                      STEP_TEST,
                      STEP_PACKAGE,
                      STEP_INSTALL,
                      STEP_PUBLISH);

   type Step_Info_Type is record
      Kind : Step_Type := STEP_MAKE;
   end record;

   package Step_Info_Vectors is
     new Ada.Containers.Vectors (Index_Type   => Positive,
                                 Element_Type => Step_Info_Type);
   subtype Step_Info_Vector is Step_Info_Vectors.Vector;
   subtype Step_Info_Cursor is Step_Info_Vectors.Cursor;

   type Controller_Type is limited interface;

   type Controller_Access is access all Controller_Type'Class;

   procedure Build (Controller : in out Controller_Type;
                    Build      : in out Porion.Builds.Models.Build_Ref;
                    Path       : in String;
                    Executor   : in out Porion.Executors.Executor_Type'Class) is abstract;

   procedure Clean (Controller : in out Controller_Type) is abstract;

   type Builder_Info_Type is record
      Builder   : Builder_Type := BUILDER_EMPTY;
      Priority  : Priority_Type := Priority_Type'First;
      Steps     : Step_Info_Vector;
      Supported : Boolean := False;
   end record;

   procedure Configure (Controller : in out Controller_Type;
                        Parameters : in Util.Strings.Vectors.Vector) is null;

   type Format_Type is (TEXT, JSON);

   procedure Print (Controller : in out Controller_Type;
                    Stream     : in out Util.Serialize.IO.Output_Stream'Class) is null;

   procedure Guess (Controller : in out Controller_Type;
                    Path       : in String;
                    Result     : out Builder_Info_Type;
                    Logger     : in out Porion.Loggers.Logger_Type) is null;

end Porion.Builders;
