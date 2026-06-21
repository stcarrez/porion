-----------------------------------------------------------------------
--  porion-metrics-factories -- Factories for metric controllers
--  Copyright (C) 2021, 2026 Stephane Carrez
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

with Porion.Metrics.DiskUsage;
with Porion.Metrics.Filesize;
with Porion.Metrics.Coverage;
with Porion.Metrics.Cloc;
package body Porion.Metrics.Factories is

   function Create (Metric  : in String;
                    Session : in ADO.Sessions.Master_Session;
                    Params  : in UString) return Controller_Access is
   begin
      if Metric = "disk" then
         return DiskUsage.Create (Session, Params);

      elsif Metric = "filesize" then
         return Filesize.Create (Session, Params);

      elsif Metric = "coverage" then
         return Coverage.Create (Session, Params);

      elsif Metric = "cloc" then
         return Cloc.Create (Session, Params);

      else
         return null;
      end if;
   end Create;

   function Create (Metric  : in Metric_Type) return Reporter_Access is
   begin
      case Metric is
         when METRIC_SPACE =>
            return DiskUsage.Create;

         when METRIC_CLOC =>
            return Cloc.Create;

         when METRIC_COVERAGE =>
            return Coverage.Create;

         when others =>
            return null;

      end case;
   end Create;

end Porion.Metrics.Factories;
