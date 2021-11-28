-----------------------------------------------------------------------
--  porion-metrics-spaces -- Get metrics for the file system space used by the build
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
with Ada.Directories;
with Util.Strings;
with PT.Colors;
with Porion.Tools;
with Porion.Reports;
package body Porion.Metrics.DiskUsage is

   use Ada.Strings.Unbounded;
   use type Ada.Directories.File_Size;

   function Create (Session : in ADO.Sessions.Master_Session;
                    Params  : in UString) return Controller_Access is
      Result  : constant Spaces_Controller_Access := new Controller_Type;
   begin
      Result.Kind := METRIC_SPACE;
      Result.Session := Session;
      if Length (Params) > 0 then
         Result.Prefix := Params & ".";
      end if;
      return Result.all'Access;
   end Create;

   overriding
   procedure Collect (Controller : in out Controller_Type;
                      Path       : in String;
                      Executor   : in out Porion.Executors.Executor_Type'Class) is
      Stats  : Porion.Tools.Tree_Stat_Type;
      Prefix : constant String := To_String (Controller.Prefix);
   begin
      Porion.Tools.Find_Stats (Path, Stats);
      Controller.Save_Metric (Prefix & "total_size", "Total size (Kb)",
                              Natural (Stats.Total_Size / 1024));
      Controller.Save_Metric (Prefix & "file_count", "File count", Stats.File_Count);
      Controller.Save_Metric (Prefix & "directory_count", "Directory count", Stats.Dir_Count);
   end Collect;

   function Create return Reporter_Access is
   begin
      return new Reporter_Type;
   end Create;

   function Format (Value : in Integer;
                    Unit  : in String;
                    Dv    : in Integer) return String is
      Img : constant String := Util.Strings.Image (Value);
   begin
      if Value = 0 or Dv = 0 then
         return Img & Unit;
      end if;
      return Img & Unit & " (" & Reports.Format_Percent (Dv, Value) & "%)";
   end Format;

   --  ------------------------------
   --  Produce a report with the metric values collected during a build.
   --  ------------------------------
   overriding
   procedure Report (Controller : in out Reporter_Type;
                     Printer    : in out PT.Printer_Type'Class;
                     Fields     : in PT.Texts.Field_Array;
                     Values     : in Value_Map) is
      pragma Unreferenced (Controller);

      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Chart  : PT.Charts.Printer_Type := PT.Charts.Create (Printer);
      Total  : constant Stat_Info_Type := Get_Stat_Info (Values, "total_size");
      Files  : constant Stat_Info_Type := Get_Stat_Info (Values, "file_count");
      Dirs   : constant Stat_Info_Type := Get_Stat_Info (Values, "directory_count");
      Green  : constant PT.Style_Type := Printer.Create_Style (PT.Colors.Green);
      Red    : constant PT.Style_Type := Printer.Create_Style (PT.Colors.Red);
   begin
      Writer.Put (Fields (1), -("Disk space used"));
      Writer.Put (Fields (2), Format (Total.Max, "K", Total.Max - Total.Min));
      Draw_Value_Bar (Chart, Writer.Get_Box (Fields (3)),
                      Total.Min, 0, Total.Max, Green, Red);
      Writer.New_Line;

      Writer.Put (Fields (1), -("Files"));
      Writer.Put (Fields (2), Format (Files.Max, "", Files.Max - Files.Min));
      Draw_Value_Bar (Chart, Writer.Get_Box (Fields (3)),
                      Files.Min, 0, Files.Max, Green, Red);
      Writer.New_Line;

      Writer.Put (Fields (1), -("Directories"));
      Writer.Put (Fields (2), Format (Dirs.Max, "", Dirs.Max - Dirs.Min));
      Draw_Value_Bar (Chart, Writer.Get_Box (Fields (3)),
                      Dirs.Min, 0, Dirs.Max, Green, Red);
      Writer.New_Line;

   end Report;

end Porion.Metrics.DiskUsage;
