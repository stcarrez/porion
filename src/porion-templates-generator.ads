-----------------------------------------------------------------------
--  porion-templates-generator -- build recipe generator from a template
--  Copyright (C) 2023 Stephane Carrez
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

with Porion.Builds.Services;
with Porion.Services;
package Porion.Templates.Generator is

   subtype Build_Config_Vector is Porion.Builds.Services.Build_Config_Vector;
   subtype Build_Config_Cursor is Porion.Builds.Services.Build_Config_Cursor;

   procedure Generate (Service    : in out Porion.Services.Context_Type;
                       Template   : in Template_Ref;
                       List       : in out Build_Config_Vector) with
      Pre => Service.Is_Open and then Service.Has_Project and then Service.Has_Branch;

end Porion.Templates.Generator;
