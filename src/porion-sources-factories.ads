-----------------------------------------------------------------------
--  porion-sources-factories -- Factory for creation of the source controller
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
with Porion.Configs;
package Porion.Sources.Factories is

   --  Create a source controller of the given kind.
   function Create (Kind   : in Source_Control_Type;
                    Config : in Porion.Configs.Config_Type) return Controller_Access;

   --  Guess some information about the sources located in the given directory.
   --  The source controller tries to find if it can manage the files at the given location
   --  and provides information on how to manage those files.
   procedure Guess (Path       : in String;
                    Config     : in Porion.Configs.Config_Type;
                    Result     : out Source_Info_Type;
                    Logger     : in out Porion.Loggers.Logger_Type);

end Porion.Sources.Factories;
