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
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Indefinite_Vectors;
with Ada.Strings.Hash;
with Porion.Builds.Models;
with Porion.Executors;
with Porion.Configs;
with PT.Texts;
with Util.Beans.Objects.Enums;
private with ADO.Sessions;
private with PT.Charts;
package Porion.Metrics is

   type Metric_Type is (METRIC_SPACE,
                        METRIC_FILESIZE,
                        METRIC_COVERAGE,
                        METRIC_CLOC);

   for Metric_Type use (METRIC_SPACE    => 1,
                        METRIC_FILESIZE => 2,
                        METRIC_COVERAGE => 3,
                        METRIC_CLOC     => 4);

   package Metric_Type_Objects is
      new Util.Beans.Objects.Enums (Metric_Type);

   type Label_Value_Type (Length : Natural) is record
      Value   : Integer;
      Content : UString;
      Label   : String (1 .. Length);
   end record;

   package Value_Maps is
      new Ada.Containers.Indefinite_Hashed_Maps (Key_Type => String,
                                                 Element_Type => Label_Value_Type,
                                                 Hash  => Ada.Strings.Hash,
                                                 Equivalent_Keys => "=");

   subtype Value_Map is Value_Maps.Map;
   subtype Value_Cursor is Value_Maps.Cursor;

   package Value_Vectors is
      new Ada.Containers.Indefinite_Vectors (Index_Type => Positive,
                                             Element_Type => Label_Value_Type);

   subtype Value_Vector is Value_Vectors.Vector;

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

   type Reporter_Type is limited new Ada.Finalization.Limited_Controlled with private;
   type Reporter_Access is access all Reporter_Type'Class;

   --  Produce a report with the metric values collected during a build.
   procedure Report (Controller : in out Reporter_Type;
                     Printer    : in out PT.Printer_Type'Class;
                     Fields     : in PT.Texts.Field_Array;
                     Values     : in Value_Map) is null;

   type Stat_Info_Type is record
      Min   : Integer := 0;
      Max   : Integer := 0;
      Count : Natural := 0;
   end record;

   function Get_Stat_Info (Values : in Value_Map;
                           Name   : in String) return Stat_Info_Type;

private

   --  Save the build metric.
   procedure Save_Metric (Controller : in out Controller_Type;
                          Name       : in String;
                          Label      : in String;
                          Value      : in Integer;
                          Content    : in String := "") with
      Pre => Controller.Has_Build and Name'Length > 0;

   --  Save a build percent metrix created from the value over the max.
   --  The metric value is 10 times the percent value (ie, 45.6% is stored as 456).
   procedure Save_Percent_Metric (Controller : in out Controller_Type;
                                  Name       : in String;
                                  Label      : in String;
                                  Value      : in Integer;
                                  Max        : in Integer) with
      Pre => Controller.Has_Build and Max /= 0;

   procedure Collect (Controller : in out Controller_Type;
                      Path       : in String;
                      Executor   : in out Porion.Executors.Executor_Type'Class) is null;

   type Controller_Type is limited new Ada.Finalization.Limited_Controlled with record
      Session : ADO.Sessions.Master_Session;
      Config  : Porion.Configs.Config_Type;
      Build   : Porion.Builds.Models.Build_Ref;
      Kind    : Metric_Type;
   end record;

   type Reporter_Type is limited new Ada.Finalization.Limited_Controlled with record
      Kind    : Metric_Type;
   end record;

   function "-" (Left, Right : Integer) return PT.W_Type is
      (PT.W_Type (Integer '(Left - Right)));

   procedure Draw_Value_Bar is
      new PT.Charts.Draw_Bar (Integer);

   type Integer_Array is array (Positive range <>) of Integer;

   function Get_Integer_Count (Content : in String) return Integer;

   --  Get the value identified by the name and if found, extract the integer list
   --  defined in the value content.  Returns an empty array if there is no item.
   function Get_Value_Array (Values : in Value_Map;
                             Name   : in String) return Integer_Array;

end Porion.Metrics;
