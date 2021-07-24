-----------------------------------------------------------------------
--  porion-builders -- Continuous integration controller
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
with Porion.Loggers;
package Porion.Builders is

   type Controller_Type is limited Interface;

   type Controller_Access is access all Controller_Type'Class;

   procedure Build (Controller : in out Controller_Type;
                    Logger     : in out Porion.Loggers.Logger_Type) is abstract;

   procedure Clean (Controller : in out Controller_Type) is abstract;

end Porion.Builders;
