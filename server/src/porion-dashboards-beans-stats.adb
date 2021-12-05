-----------------------------------------------------------------------
--  porion-dashboards-beans-stats -- Statistics about projects and builds
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
with ADO.Sessions;
with ADO.Queries;
with AWA.Services.Contexts;
with Porion.Builds.Models;
package body Porion.Dashboards.Beans.Stats is

   use type Porion.Builds.Models.Build_Status_Type;

   package ASC renames AWA.Services.Contexts;

   --  ------------------------------
   --  Load the stats.
   --  ------------------------------
   procedure Load (Bean    : in out Last_Builds_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String) is
      Ctx     : constant ASC.Service_Context_Access := ASC.Current;
      Session : ADO.Sessions.Session := ASC.Get_Session (Ctx);
      Query   : ADO.Queries.Context;
      List    : Porion.Queries.Build_Stat_List_Bean;
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

end Porion.Dashboards.Beans.Stats;
