-----------------------------------------------------------------------
--  porion-dashboards-beans-stats -- Statistics about projects and builds
--  Copyright (C) 2021, 2022 Stephane Carrez
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
with Ada.Containers.Hashed_Sets;
with ADO.Sessions;
with ADO.Queries;
with ADO.Utils;
with AWA.Services.Contexts;
with Porion.Metrics;
with Porion.Builds.Models;
package body Porion.Dashboards.Beans.Stats is

   use type ADO.Identifier;
   use type Porion.Builds.Models.Build_Status_Type;

   package ASC renames AWA.Services.Contexts;

   package Identifier_Sets is
      new Ada.Containers.Hashed_Sets (Element_Type        => ADO.Identifier,
                                      Hash                => ADO.Utils.Hash,
                                      Equivalent_Elements => "=");

   Empty_Metric : constant Porion.Queries.Metric_Stat := (Kind => Porion.Metrics.METRIC_SPACE,
                                                          Sum_Value => 0, Max_Value => 0,
                                                          Count => 0, others => <>);

   --  ------------------------------
   --  Load the stats.
   --  ------------------------------
   procedure Load (Bean    : in out Last_Builds_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String) is
      pragma Unreferenced (Outcome);

      Ctx     : constant ASC.Service_Context_Access := ASC.Current;
      Session : ADO.Sessions.Session := ASC.Get_Session (Ctx);
      Query   : ADO.Queries.Context;
      List    : Porion.Queries.Build_Stat_List_Bean;
      Date    : constant Ada.Calendar.Time := Get_Period_Date (REPORT_WEEK);
   begin
      Query.Set_Query (Porion.Queries.Query_Stat_Builds);
      Porion.Queries.List (List, Session, Query);
      for Stat of List.List loop
         if Stat.Build_Status = Porion.Builds.Models.BUILD_PASS then
            Bean.Pass := Stat;
         elsif Stat.Build_Status = Porion.Builds.Models.BUILD_FAIL then
            Bean.Fail := Stat;
         end if;
         Bean.Total.Count := Bean.Total.Count + Stat.Count;
         Bean.Total.Pass_Count := Bean.Total.Pass_Count + Stat.Pass_Count;
         Bean.Total.Fail_Count := Bean.Total.Fail_Count + Stat.Fail_Count;
         Bean.Total.Timeout_Count := Bean.Total.Timeout_Count + Stat.Timeout_Count;
         Bean.Total.Test_Duration := Bean.Total.Test_Duration + Stat.Test_Duration;
         Bean.Total.Build_Duration := Bean.Total.Build_Duration + Stat.Build_Duration;
         Bean.Total.User_Time := Bean.Total.User_Time + Stat.User_Time;
         Bean.Total.Sys_Time := Bean.Total.Sys_Time + Stat.Sys_Time;
      end loop;

      declare
         Changes     : Project_Audit_Vectors.Vector;
         First_Audit : constant ADO.Identifier := Get_First_Audit (Session, Date);
         Projects    : Identifier_Sets.Set;
      begin
         --  Look for changes since the first audit change 1 day ago.
         if First_Audit /= ADO.NO_IDENTIFIER then
            Query.Set_Query (Porion.Beans.Query_Project_Change_Count);
            Query.Bind_Param ("last_audit", First_Audit);
            Porion.Beans.List (Changes, Session, Query);
            for Project of Changes loop
               Projects.Include (Project.Project_Id);
            end loop;

            Query.Set_Query (Porion.Beans.Query_Recipe_Change_Count);
            Query.Bind_Param ("last_audit", First_Audit);
            Porion.Beans.List (Changes, Session, Query);
            for Project of Changes loop
               Projects.Include (Project.Project_Id);
            end loop;

            Query.Set_Query (Porion.Beans.Query_Build_Count);
            Query.Bind_Param ("last_audit", First_Audit);
            Porion.Beans.List (Changes, Session, Query);
            for Project of Changes loop
               Projects.Include (Project.Project_Id);
            end loop;

         end if;
         Bean.Project_Count := Natural (Projects.Length);
      end;
   end Load;

   --  ------------------------------
   --  Get the value identified by the name.
   --  ------------------------------
   overriding
   function Get_Value (From : in Last_Builds_Bean;
                       Name : in String) return Util.Beans.Objects.Object is
   begin
      if Name = "pass" then
         return Util.Beans.Objects.To_Object (Value   => From.Pass_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "fail" then
         return Util.Beans.Objects.To_Object (Value   => From.Fail_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "project_changed" then
         return UBO.To_Object (From.Project_Count);
      else
         return From.Total.Get_Value (Name);
      end if;
   end Get_Value;

   --  ------------------------------
   --  Create the stats build bean instance.
   --  ------------------------------
   function Create_Last_Builds_Bean (Module : in Modules.Dashboard_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access is
      Object : constant Last_Builds_Bean_Access := new Last_Builds_Bean;
   begin
      Object.Module := Module;
      Object.Pass_Bean := Object.Pass'Access;
      Object.Pass := (Build_Status   => Porion.Builds.Models.BUILD_FAIL,
                      Build_Duration => 0,
                      Sys_Time       => 0,
                      User_Time      => 0,
                      others         => 0);
      Object.Fail_Bean := Object.Fail'Access;
      Object.Fail := (Build_Status   => Porion.Builds.Models.BUILD_FAIL,
                      Build_Duration => 0,
                      Sys_Time       => 0,
                      User_Time      => 0,
                      others         => 0);
      Object.Total_Bean := Object.Total'Access;
      Object.Total := (Build_Status   => Porion.Builds.Models.BUILD_FAIL,
                       Build_Duration => 0,
                       Sys_Time       => 0,
                       User_Time      => 0,
                       others         => 0);
      return Object.all'Access;
   end Create_Last_Builds_Bean;

   function "<" (Left, Right : in Porion.Queries.Metric_Stat) return Boolean
      is (Left.Sum_Value > Right.Sum_Value);

   package Sort is
      new Porion.Queries.Metric_Stat_Vectors.Generic_Sorting ("<" => "<");

   --  ------------------------------
   --  Load the stats.
   --  ------------------------------
   procedure Load (Bean    : in out Metrics_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String) is
      pragma Unreferenced (Outcome);

      Ctx     : constant ASC.Service_Context_Access := ASC.Current;
      Session : ADO.Sessions.Session := ASC.Get_Session (Ctx);
      Query   : ADO.Queries.Context;
      List    : Porion.Queries.Metric_Stat_List_Bean;
   begin
      if Bean.Project /= ADO.NO_IDENTIFIER then
         Query.Set_Query (Porion.Queries.Query_Stat_Project_Metrics);
         Query.Bind_Param ("project_id", Bean.Project);
      elsif Bean.Build /= ADO.NO_IDENTIFIER then
         Query.Set_Query (Porion.Queries.Query_Stat_Build_Metrics);
         Query.Bind_Param ("build_id", Bean.Build);
      else
         Query.Set_Query (Porion.Queries.Query_Stat_Metrics);
      end if;
      Porion.Queries.List (List, Session, Query);
      for Stat of List.List loop
         case Stat.Kind is
            when Porion.Metrics.METRIC_COVERAGE =>
               if Stat.Name = "lines" then
                  Bean.Line_Coverage := Stat;
               elsif Stat.Name = "functions" then
                  Bean.Func_Coverage := Stat;
               end if;

            when Porion.Metrics.METRIC_SPACE =>
               if Stat.Name = "before.total_size" then
                  Bean.Total_Size := Stat;
               elsif Stat.Name = "before.file_count" then
                  Bean.File_Count := Stat;
               end if;

            when Porion.Metrics.METRIC_CLOC =>
               if Stat.Name /= "total" then
                  Bean.Cloc.List.Append (Stat);
               else
                  Bean.Cloc_Total := Stat;
               end if;

            when others =>
               null;

         end case;
      end loop;
      Sort.Sort (Bean.Cloc.List);
      if Natural (Bean.Cloc.List.Length) > Bean.Cloc_Max_Count then
         declare
            Stat : Porion.Queries.Metric_Stat;
         begin
            Stat.Kind := Porion.Metrics.METRIC_CLOC;
            Stat.Name := To_UString ("others");
            Stat.Label := To_UString ("Others");
            Stat.Sum_Value := 0;
            Stat.Max_Value := 0;
            Stat.Count := 0;
            for I in Bean.Cloc_Max_Count .. Natural (Bean.Cloc.List.Length) loop
               declare
                  Item : constant Porion.Queries.Metric_Stat
                     := Bean.Cloc.List.Element (I);
               begin
                  Stat.Sum_Value := Stat.Sum_Value + Item.Sum_Value;
                  Stat.Count := Stat.Count + Item.Count;
               end;
            end loop;
            while Natural (Bean.Cloc.List.Length) >= Bean.Cloc_Max_Count loop
               Bean.Cloc.List.Delete_Last;
            end loop;
            Bean.Cloc.List.Append (Stat);
         end;
      end if;
   end Load;

   --  ------------------------------
   --  Get the value identified by the name.
   --  ------------------------------
   overriding
   function Get_Value (From : in Metrics_Bean;
                       Name : in String) return Util.Beans.Objects.Object is
   begin
      if Name = "files" then
         return Util.Beans.Objects.To_Object (Value   => From.File_Count_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "sizes" then
         return Util.Beans.Objects.To_Object (Value   => From.Total_Size_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "lines" then
         return Util.Beans.Objects.To_Object (Value   => From.Line_Coverage_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "functions" then
         return Util.Beans.Objects.To_Object (Value   => From.Func_Coverage_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "cloc" then
         return Util.Beans.Objects.To_Object (Value   => From.Cloc_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "total_cloc" then
         return Util.Beans.Objects.To_Object (Value   => From.Cloc_Total_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      else
         return From.Total_Size.Get_Value (Name);
      end if;
   end Get_Value;

   --  ------------------------------
   --  Create the stats build bean instance.
   --  ------------------------------
   procedure Initialize (Object : in Metrics_Bean_Access) is
   begin
      Object.Func_Coverage_Bean := Object.Func_Coverage'Access;
      Object.Func_Coverage := Empty_Metric;
      Object.Line_Coverage_Bean := Object.Line_Coverage'Access;
      Object.Line_Coverage := Empty_Metric;
      Object.Total_Size_Bean := Object.Total_Size'Access;
      Object.Total_Size := Empty_Metric;
      Object.File_Count_Bean := Object.File_Count'Access;
      Object.File_Count := Empty_Metric;
      Object.Cloc_Bean := Object.Cloc'Access;
      Object.Cloc_Total_Bean := Object.Cloc_Total'Access;
      Object.Cloc_Total := Empty_Metric;
   end Initialize;

   --  ------------------------------
   --  Create the stats build bean instance.
   --  ------------------------------
   function Create_Metrics_Bean (Module : in Modules.Dashboard_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access is
      pragma Unreferenced (Module);

      Object : constant Metrics_Bean_Access := new Metrics_Bean;
   begin
      Initialize (Object);
      return Object.all'Access;
   end Create_Metrics_Bean;

end Porion.Dashboards.Beans.Stats;
