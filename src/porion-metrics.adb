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
with Util.Strings.Tokenizers;
with ADO.Queries;
with Porion.Metrics.Models;
package body Porion.Metrics is

   --  ------------------------------
   --  Get the identification type of this metric controller.
   --  ------------------------------
   function Get_Kind (Controller : in Controller_Type) return String is
   begin
      case Controller.Kind is
         when METRIC_SPACE =>
            return "disk";

         when METRIC_FILESIZE =>
            return "filesize";

         when METRIC_COVERAGE =>
            return "coverage";

         when METRIC_CLOC =>
            return "cloc";

      end case;
   end Get_Kind;

   --  ------------------------------
   --  Returns True if the controller knows the current build.
   --  ------------------------------
   function Has_Build (Controller : in Controller_Type) return Boolean is
   begin
      return not Controller.Build.Is_Null;
   end Has_Build;

   procedure Build (Controller : in out Controller_Type;
                    Build      : in out Porion.Builds.Models.Build_Ref;
                    Path       : in String;
                    Executor   : in out Porion.Executors.Executor_Type'Class) is
   begin
      Controller.Build := Build;
      Controller_Type'Class (Controller).Collect (Path, Executor);
   end Build;

   --  ------------------------------
   --  Save the build metric.
   --  ------------------------------
   procedure Save_Metric (Controller : in out Controller_Type;
                          Name       : in String;
                          Label      : in String;
                          Value      : in Integer;
                          Content    : in String := "") is
      Query        : ADO.Queries.Context;
      Metric       : Porion.Metrics.Models.Metric_Ref;
      Found        : Boolean;
      Build_Metric : Porion.Metrics.Models.Build_Metric_Ref;
   begin
      Query.Set_Filter ("o.name = :name");
      Query.Bind_Param ("name", Name);
      Metric.Find (Controller.Session, Query, Found);
      if not Found then
         Metric.Set_Name (Name);
         Metric.Set_Label (Label);
         Metric.Set_Metric (Controller.Kind);
         Metric.Save (Controller.Session);
      end if;

      Build_Metric.Set_Metric (Metric);
      Build_Metric.Set_Build (Controller.Build);
      Build_Metric.Set_Value (Value);
      Build_Metric.Set_Content (Content);
      Build_Metric.Save (Controller.Session);
   end Save_Metric;

   function Get_Percent (Value, Max : in Integer) return Integer
      is ((Value * 1000) / Max);

   --  ------------------------------
   --  Save a build percent metrix created from the value over the max.
   --  The metric value is 10 times the percent value (ie, 45.6% is stored as 456).
   --  ------------------------------
   procedure Save_Percent_Metric (Controller : in out Controller_Type;
                                  Name       : in String;
                                  Label      : in String;
                                  Value      : in Integer;
                                  Max        : in Integer) is
      Content : constant String := Util.Strings.Image (Value) & ":" & Util.Strings.Image (Max);
   begin
      Controller.Save_Metric (Name, Label, Get_Percent (Value, Max), Content);
   end Save_Percent_Metric;

   function Get_Stat_Info (Values : in Value_Map;
                           Name   : in String) return Stat_Info_Type is
      Result : Stat_Info_Type;
   begin
      Result.Min := Integer'Last;
      Result.Max := Integer'First;
      for Iter in Values.Iterate loop
         declare
            Item_Name  : constant String := Value_Maps.Key (Iter);
            Pos        : constant Natural := Util.Strings.Rindex (Item_Name, '.');
            Value      : Integer;
         begin
            if Pos > 0 and Item_Name (Pos + 1 .. Item_Name'Last) = Name then
               Result.Count := Result.Count + 1;
               Value := Value_Maps.Element (Iter).Value;
               if Value < Result.Min then
                  Result.Min := Value;
               end if;
               if Value > Result.Max then
                  Result.Max := Value;
               end if;
            end if;
         end;
      end loop;
      if Result.Count = 0 then
         Result.Min := 0;
         Result.Max := 0;
      end if;
      return Result;
   end Get_Stat_Info;

   Empty_Array : constant Integer_Array (1 .. 0) := (others => <>);

   function Get_Integer_Count (Content : in String) return Integer is
      Count : Natural := 1;
   begin
      if Content'Length = 0 then
         return 0;
      end if;
      for C of Content loop
         if C = ':' then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Get_Integer_Count;

   --  ------------------------------
   --  Get the value identified by the name and if found, extract the integer list
   --  defined in the value content.  Returns an empty array if there is no item.
   --  ------------------------------
   function Get_Value_Array (Values : in Value_Map;
                             Name   : in String) return Integer_Array is
      Pos : constant Value_Maps.Cursor := Values.Find (Name);
   begin
      if not Value_Maps.Has_Element (Pos) then
         return Empty_Array;
      end if;
      declare
         procedure Add_Value (Token : in String;
                              Done  :  out Boolean);

         Content : constant String := To_String (Value_Maps.Element (Pos).Content);
         Length  : constant Natural := Get_Integer_Count (Content);
         Result  : Integer_Array (1 .. Length);
         Index   : Natural := 0;

         procedure Add_Value (Token : in String;
                              Done  :  out Boolean) is
         begin
            Done := False;
            Index := Index + 1;
            Result (Index) := Integer'Value (Token);
         end Add_Value;

      begin
         Util.Strings.Tokenizers.Iterate_Tokens (Content => Content,
                                                 Pattern => ":",
                                                 Process => Add_Value'Access);
         return Result;
      end;
   end Get_Value_Array;

end Porion.Metrics;
