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
with Porion.Configs;
with Util.Strings.Vectors;
with EL.Expressions;
package Porion.Builders.Scripts is

   type Controller_Type is limited new Porion.Builders.Controller_Type with private;

   overriding
   procedure Build (Controller : in out Controller_Type;
                    Logger     : in out Porion.Loggers.Logger_Type);

   overriding
   procedure Clean (Controller : in out Controller_Type);

   function Create (Config : in Porion.Configs.Config_Type) return Controller_Access;

private

   type Controller_Type is limited new Porion.Builders.Controller_Type with record
      Config             : Porion.Configs.Config_Type;
      Configure_Command  : EL.Expressions.Expression;
      Build_Command      : EL.Expressions.Expression;
      Steps              : Util.Strings.Vectors.Vector;
   end record;

   type Script_Controller_Access is access all Controller_Type'Class;

end Porion.Builders.Scripts;
