-----------------------------------------------------------------------
--  porion-sources -- Continuous integration controller
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
with Ada.Strings.Hash;
with Ada.Calendar;
with Ada.Containers.Indefinite_Ordered_Maps;
with Util.Strings.Maps;
with Porion.Loggers;
package Porion.Sources is

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

end Porion.Sources;
