-----------------------------------------------------------------------
--  porion-services-parsers -- Parse project configuration
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

with Porion.Builds.Services;
package Porion.Services.Parsers is

   type Parser_Type is record
      Project       : Porion.Projects.Models.Project_Ref;
      Build_Configs : Porion.Builds.Services.Build_Config_Vector;
   end record;

   procedure Parse (Service : in out Context_Type'Class;
                    Path    : in String;
                    Result  : in out Parser_Type);

end Porion.Services.Parsers;
