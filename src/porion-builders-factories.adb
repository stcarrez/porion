-----------------------------------------------------------------------
--  porion-builders-factories -- Factory for creation of the build controller
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

with Porion.Builders.XUnit;
with Porion.Builders.Metrics;
with Porion.Builders.Scripts;
package body Porion.Builders.Factories is

   function Create (Kind    : in Porion.Builds.Models.Builder_Type;
                    Session : in ADO.Sessions.Master_Session;
                    Config  : in Porion.Configs.Config_Type) return Controller_Access is
      use Porion.Builds.Models;
   begin
      case Kind is
         when BUILDER_SCRIPT =>
            return Scripts.Create (Config);

         when BUILDER_XUNIT =>
            return XUnit.Create (Session, Config);

         when BUILDER_METRIC =>
            return Metrics.Create (Session, Config);

         when others =>
            return null;

      end case;
   end Create;

end Porion.Builders.Factories;
