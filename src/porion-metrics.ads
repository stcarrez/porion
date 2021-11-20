-----------------------------------------------------------------------
--  porion-metrics -- Build metrics
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
with Ada.Finalization;
with Porion.Builds.Models;
with Porion.Executors;
with Porion.Configs;
with Util.Beans.Objects.Enums;
private with ADO.Sessions;
package Porion.Metrics is

   type Metric_Type is (METRIC_SPACE,
                        METRIC_FILESIZE,
                        METRIC_COVERAGE);

   for Metric_Type use (METRIC_SPACE    => 1,
                        METRIC_FILESIZE => 2,
                        METRIC_COVERAGE => 3);

   package Metric_Type_Objects is
      new Util.Beans.Objects.Enums (Metric_Type);

   type Controller_Type is limited new Ada.Finalization.Limited_Controlled with private;
   type Controller_Access is access all Controller_Type'Class;

   procedure Build (Controller : in out Controller_Type;
                    Build      : in out Porion.Builds.Models.Build_Ref;
                    Path       : in String;
                    Executor   : in out Porion.Executors.Executor_Type'Class) with
      Pre => not Build.Is_Null;

   --  Get the identification type of this metric controller.
   function Get_Kind (Controller : in Controller_Type) return String;

   --  Returns True if the controller knows the current build.
   function Has_Build (Controller : in Controller_Type) return Boolean;

private

   --  Save the build metric.
   procedure Save_Metric (Controller : in out Controller_Type;
                          Name       : in String;
                          Value      : in Integer) with
      Pre => Controller.Has_Build and Name'Length > 0;

   procedure Collect (Controller : in out Controller_Type;
                      Path       : in String;
                      Executor   : in out Porion.Executors.Executor_Type'Class) is null;

   type Controller_Type is limited new Ada.Finalization.Limited_Controlled with record
      Session : ADO.Sessions.Master_Session;
      Config  : Porion.Configs.Config_Type;
      Build   : Porion.Builds.Models.Build_Ref;
      Kind    : Metric_Type;
   end record;

end Porion.Metrics;
