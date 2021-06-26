-----------------------------------------------------------------------
--  porion -- Continuous integration controller
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
with Intl;
with Ada.Strings.Unbounded;
package Porion is

   function "-" (Message : in String) return String is (Intl."-" (Message));

   subtype UString is Ada.Strings.Unbounded.Unbounded_String;

   function To_UString (Value : in String) return UString
     renames Ada.Strings.Unbounded.To_Unbounded_String;

   function To_String (Value : in UString) return String
     renames Ada.Strings.Unbounded.To_String;

   function "=" (Left, Right : in UString) return Boolean
     renames Ada.Strings.Unbounded."=";

private

   --  Configure the logs.
   procedure Configure_Logs (Debug   : in Boolean;
                             Dump    : in Boolean;
                             Verbose : in Boolean);
end Porion;
