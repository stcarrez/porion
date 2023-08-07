-----------------------------------------------------------------------
--  porion-sources -- Source management
--  Copyright (C) 2021, 2023 Stephane Carrez
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
with Ada.Calendar;
with Ada.Containers.Indefinite_Ordered_Maps;
with Porion.Executors;
with Porion.Configs;
package Porion.Sources is

   Not_Supported : exception;

   type Source_Info_Type is record
      Kind : Source_Control_Type := SRC_UNKNOWN;
      Name : UString;
      URI  : UString;
   end record;

   type Branch_Type is record
      Tag         : UString;
      Build_Count : Natural := 0;
      Last_Tag    : UString;
      Last_Build  : Natural := 0;
      Last_Date   : Ada.Calendar.Time;
   end record;

   package Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type        => String,
      Element_Type    => Branch_Type);

   type Status_Type is record
      Check_Date : Ada.Calendar.Time;
      Head       : UString;
      Changes    : Maps.Map;
   end record;

   type Checkout_Type is record
      Path         : UString;
      Previous_Tag : UString;
      Change_Count : Natural := 0;
   end record;

   --  Check for changes in the project by using the executor.
   --  The source control parameters are configured in Config.
   procedure Check (Kind      : in Source_Control_Type;
                    Config    : in Porion.Configs.Config_Type;
                    Status    : out Status_Type;
                    Executor  : in out Porion.Executors.Executor_Type'Class) with
      Pre => Executor.Is_Configured;

   --  Checkout the source of the project by using the executor.
   --  The checkout parameters are configured in Config and the
   --  files are extracted in the Path directory (possibly on a remote host).
   --  Return in Result the relative path within Path of the source locations.
   procedure Checkout (Kind     : in Source_Control_Type;
                       Config   : in Porion.Configs.Config_Type;
                       Path     : in String;
                       Result   : out UString;
                       Executor : in out Porion.Executors.Executor_Type'Class) with
      Pre => Executor.Is_Configured and Path'Length > 0;

   --  Checkout the source of the project by using the executor.
   --  The checkout parameters are configured in Config and the extraction
   --  is controlled by the Extraction record which contains the Path directory
   --  (possibly on a remote host).  After extraction, the operation computes
   --  the number of changes made since the previous build.
   procedure Checkout (Kind       : in Source_Control_Type;
                       Config     : in Porion.Configs.Config_Type;
                       Extraction : in out Checkout_Type;
                       Executor   : in out Porion.Executors.Executor_Type'Class) with
      Pre => Executor.Is_Configured and Length (Extraction.Path) > 0;

   --  Guess some information about the sources located in the given directory.
   --  The source controller tries to find if it can manage the files at the given location
   --  and provides information on how to manage those files.
   procedure Guess (Path       : in String;
                    Config     : in Porion.Configs.Config_Type;
                    Result     : out Source_Info_Type;
                    Executor   : in out Porion.Executors.Executor_Type'Class) with
      Pre => Path'Length > 0;

private

   type Controller_Type is limited interface;

   type Controller_Access is access all Controller_Type'Class;

   procedure Check (Controller : in out Controller_Type;
                    Status     : out Status_Type;
                    Executor   : in out Porion.Executors.Executor_Type'Class) is abstract;

   procedure Checkout (Controller : in out Controller_Type;
                       Path       : in String;
                       Result     : out UString;
                       Executor   : in out Porion.Executors.Executor_Type'Class) is abstract;

   procedure Changes (Controller : in out Controller_Type;
                      Path       : in String;
                      Extraction : in out Checkout_Type;
                      Executor   : in out Porion.Executors.Executor_Type'Class) is abstract;

   --  Guess some information about the sources located in the given directory.
   --  The source controller tries to find if it can manage the files at the given location
   --  and provides information on how to manage those files.
   procedure Guess (Controller : in out Controller_Type;
                    Path       : in String;
                    Result     : out Source_Info_Type;
                    Executor   : in out Porion.Executors.Executor_Type'Class) is abstract;

end Porion.Sources;
