-----------------------------------------------------------------------
--  porion-sources -- Source management
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
with Ada.Calendar;
with Ada.Containers.Indefinite_Ordered_Maps;
with Util.Beans.Objects.Enums;
with Porion.Loggers;
package Porion.Sources is

   Not_Supported : exception;

   type Source_Control_Type is (SRC_UNKNOWN, SRC_GIT, SRC_FILE);

   --  Use a fixed enum configuration because the value is stored in database.
   for Source_Control_Type use (SRC_UNKNOWN => 0,
                                SRC_GIT => 1,
                                SRC_FILE => 2);

   package Source_Control_Type_Objects is
      new Util.Beans.Objects.Enums (Source_Control_Type);

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
      Changes    : Maps.Map;
   end record;

   type Controller_Type is limited Interface;

   type Controller_Access is access all Controller_Type'Class;

   procedure Check (Controller : in out Controller_Type;
                    Status     : out Status_Type;
                    Logger     : in out Porion.Loggers.Logger_Type) is abstract;

   procedure Checkout (Controller : in out Controller_Type;
                       Path       : in String;
                       Logger     : in out Porion.Loggers.Logger_Type) is abstract;

   procedure Changes (Controller : in out Controller_Type;
                      Result     : out Status_Type;
                      Logger     : in out Porion.Loggers.Logger_Type) is abstract;

   --  Guess some information about the sources located in the given directory.
   --  The source controller tries to find if it can manage the files at the given location
   --  and provides information on how to manage those files.
   procedure Guess (Controller : in out Controller_Type;
                    Path       : in String;
                    Result     : out Source_Info_Type;
                    Logger     : in out Porion.Loggers.Logger_Type) is abstract;

end Porion.Sources;
