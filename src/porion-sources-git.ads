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
with Porion.Configs;
private with EL.Expressions;
package Porion.Sources.Git is

   GIT_TEST_COMMAND     : constant String := "git ls-remote -h -- #{repository_url}";
   GIT_CHECKOUT_COMMAND : constant String := "git -C #{build_dir} clone #{repository_url}";

   type Controller_Type is limited new Porion.Sources.Controller_Type with private;

   overriding
   procedure Check (Controller : in out Controller_Type;
                    Status     : out Status_Type);

   overriding
   procedure Checkout (Controller : in out Controller_Type;
                       Path       : in String);

   overriding
   procedure Changes (Controller : in out Controller_Type;
                      Result     : out Status_Type);

   function Create (Config : in Porion.Configs.Config_Type) return Controller_Access;

private

   type Controller_Type is limited new Porion.Sources.Controller_Type with record
      Config           : Porion.Configs.Config_Type;
      Check_Command    : EL.Expressions.Expression;
      Checkout_Command : EL.Expressions.Expression;
   end record;

   type Git_Controller_Access is access all Controller_Type'Class;

end Porion.Sources.Git;
