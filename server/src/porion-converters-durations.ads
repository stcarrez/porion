-----------------------------------------------------------------------
--  porion-converters-durations -- Duration converter
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
with Util.Beans.Objects;
with ASF.Components.Base;
with ASF.Contexts.Faces;
with ASF.Converters;

--  == Duration Converter ==
--  The `ASF.Converters.Durations` defines a converter to display a duration in millisecond,
--  second, minutes and so on.
package Porion.Converters.Durations is

   type Unit_Type is (NANOSECOND, MICROSECOND, MILLISECOND, SECOND);

   --  ------------------------------
   --  Converter
   --  ------------------------------
   --  The <b>Duration_Converter</b> translates the object value which holds an integer
   --  or a duration value into a printable size representation.
   type Duration_Converter is new ASF.Converters.Converter with record
      Unit : Unit_Type := SECOND;
   end record;
   type Duration_Converter_Access is access all Duration_Converter'Class;

   --  Convert the object value into a string.  The object value is associated
   --  with the specified component.
   --  If the string cannot be converted, the Invalid_Conversion exception should be raised.
   function To_String (Convert   : in Duration_Converter;
                       Context   : in ASF.Contexts.Faces.Faces_Context'Class;
                       Component : in ASF.Components.Base.UIComponent'Class;
                       Value     : in Util.Beans.Objects.Object) return String;

   --  Convert the date string into an object for the specified component.
   --  If the string cannot be converted, the Invalid_Conversion exception should be raised.
   function To_Object (Convert   : in Duration_Converter;
                       Context   : in ASF.Contexts.Faces.Faces_Context'Class;
                       Component : in ASF.Components.Base.UIComponent'Class;
                       Value     : in String) return Util.Beans.Objects.Object;

end Porion.Converters.Durations;
