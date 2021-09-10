-----------------------------------------------------------------------
--  porion-resources -- Resource data
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

package Porion.Resources is

   type Content_Array is array (Natural range <>) of access constant String;
   type Content_Access is access constant Content_Array;

   type Name_Access is access constant String;

   type Name_Array is array (Natural range <>) of Name_Access;

   type Get_Resource_Access is not null access
     function (Name : in String) return access constant String;

   type Get_Content_Handler is not null access
     function (Name : in String) return Content_Access;

end Porion.Resources;
