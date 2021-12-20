-----------------------------------------------------------------------
--  asf-converters-durations -- Duration converter
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
with Ada.Exceptions;
with Ada.Strings.Unbounded;

with Util.Locales;
with Util.Strings;
with Util.Properties.Bundles;

with ASF.Locales;
with ASF.Utils;
with ASF.Applications.Main;
with Porion.Reports;
package body ASF.Converters.Durations is

   ONE_KB  : constant Long_Long_Integer := 1_024;
   ONE_MB  : constant Long_Long_Integer := ONE_KB * 1_024;
   ONE_GB  : constant Long_Long_Integer := ONE_MB * 1_024;

   UNIT_NS : aliased constant String := "duration_ns_unit";
   UNIT_US : aliased constant String := "duration_us_unit";
   UNIT_MS : aliased constant String := "duration_ms_unit";

   --  ------------------------------
   --  Convert the object value into a string.  The object value is associated
   --  with the specified component.
   --  If the string cannot be converted, the Invalid_Conversion exception should be raised.
   --  ------------------------------
   function To_String (Convert   : in Duration_Converter;
                       Context   : in ASF.Contexts.Faces.Faces_Context'Class;
                       Component : in ASF.Components.Base.UIComponent'Class;
                       Value     : in Util.Beans.Objects.Object) return String is
      pragma Unreferenced (Convert);

      Bundle  : ASF.Locales.Bundle;
      Locale  : constant Util.Locales.Locale := Context.Get_Locale;
   begin
      begin
         ASF.Applications.Main.Load_Bundle (Context.Get_Application.all,
                                            Name   => "durations",
                                            Locale => Util.Locales.To_String (Locale),
                                            Bundle => Bundle);

      exception
         when E : Util.Properties.Bundles.NO_BUNDLE =>
            Component.Log_Error ("Cannot localize sizes: {0}",
                                 Ada.Exceptions.Exception_Message (E));
      end;

      --  Convert the value as an integer here so that we can raise
      --  the Invalid_Conversion exception.
      declare
         Long_Value : constant Long_Long_Integer := Util.Beans.Objects.To_Long_Long_Integer (Value);
         Val        : Integer;
         Result     : Ada.Strings.Unbounded.Unbounded_String;
         Unit       : Util.Strings.Name_Access;
      begin
         if Convert.Unit = MICROSECOND then
            return Porion.Reports.Format (Porion.Microsecond_Type (Long_Value));
         elsif Convert.Unit = MILLISECOND then
            return Porion.Reports.Format (Porion.Millisecond_Type (Long_Value));
         else
            return Porion.Reports.Format (Duration (Long_Value));
         end if;
      end;

   exception
      when E : others =>
         raise ASF.Converters.Invalid_Conversion with Ada.Exceptions.Exception_Message (E);
   end To_String;

   --  ------------------------------
   --  Convert the date string into an object for the specified component.
   --  If the string cannot be converted, the Invalid_Conversion exception should be raised.
   --  ------------------------------
   function To_Object (Convert   : in Duration_Converter;
                       Context   : in ASF.Contexts.Faces.Faces_Context'Class;
                       Component : in ASF.Components.Base.UIComponent'Class;
                       Value     : in String) return Util.Beans.Objects.Object is
      pragma Unreferenced (Convert, Context, Value);
   begin
      Component.Log_Error ("Conversion of string to a size is not implemented");
      raise ASF.Converters.Invalid_Conversion with "Not implemented";
      return Util.Beans.Objects.Null_Object;
   end To_Object;

end ASF.Converters.Durations;
