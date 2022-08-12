-----------------------------------------------------------------------
--  porion-projects-beans -- Beans for module projects
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
with ADO.Queries;
with AWA.Services.Contexts;
with Porion.Services;
package body Porion.Projects.Beans is

   package ASC renames AWA.Services.Contexts;
   use type Porion.Builds.Models.Build_Status_Type;

   --  ------------------------------
   --  Get the value identified by the name.
   --  ------------------------------
   overriding
   function Get_Value (From : in Project_Bean;
                       Name : in String) return Util.Beans.Objects.Object is
   begin
      if Name = "project" then
         return Util.Beans.Objects.To_Object (Value   => From.Project_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "branch" then
         return Util.Beans.Objects.To_Object (Value   => From.Branch_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "metrics" then
         return Util.Beans.Objects.To_Object (Value   => From.Metric_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "recipes" then
         return Util.Beans.Objects.To_Object (Value   => From.Recipes_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "builds" then
         return Util.Beans.Objects.To_Object (Value   => From.Builds_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "ident" then
         return UBO.To_Object (Porion.Projects.To_String (From.Ident));
      elsif Name = "build_status" then
         return Porion.Builds.Models.Build_Status_Type_Objects.to_Object (From.Build_Status);
      else
         return From.Project.Get_Value (Name);
      end if;
   end Get_Value;

   --  ------------------------------
   --  Set the value identified by the name.
   --  ------------------------------
   overriding
   procedure Set_Value (From  : in out Project_Bean;
                        Name  : in String;
                        Value : in Util.Beans.Objects.Object) is
   begin
      if Name = "ident" then
         From.Ident := Porion.Projects.Parse (UBO.To_String (Value));
      end if;
   end Set_Value;

   --  ------------------------------
   --  Load the stats.
   --  ------------------------------
   procedure Load (Bean    : in out Project_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String) is
      Ctx     : constant ASC.Service_Context_Access := ASC.Current;
      Context : Porion.Services.Context_Type;
      Query   : ADO.Queries.Context;
   begin
      Context.DB := ASC.Get_Master_Session (Ctx);

      Context.Load (Bean.Ident);
      Bean.Project := Context.Project;
      Bean.Branch := Context.Branch;
      Bean.Metric.Project := Context.Project.Get_Id;
      Bean.Metric.Cloc_Max_Count := 4;
      Bean.Metric.Load (Outcome);

      Query.Set_Query (Porion.Queries.Query_Project_Last_Build_List);
      Query.Bind_Param ("project_id", Context.Project.Get_Id);
      Porion.Queries.List (Bean.Builds, Context.DB, Query);

      if not Bean.Builds.List.Is_Empty then
         Bean.Build_Status := Porion.Builds.Models.BUILD_PASS;
         for Build of Bean.Builds.List loop
            if Build.Build_Status = Porion.Builds.Models.BUILD_FAIL then
               Bean.Build_Status := Porion.Builds.Models.BUILD_FAIL;
               exit;
            end if;
         end loop;
      else
         Bean.Build_Status := Porion.Builds.Models.BUILD_FAIL;
      end if;

      Query.Set_Query (Porion.Queries.Query_Recipe_List);
      Query.Bind_Param ("project_id", Context.Project.Get_Id);
      Porion.Queries.List (Bean.Recipes, Context.DB, Query);

   exception
      when Porion.Services.Not_Found =>
         Outcome := To_UString ("not-found");

   end Load;

   --  ------------------------------
   --  Create the Project_Bean bean instance.
   --  ------------------------------
   function Create_Project_Bean (Module : in Porion.Projects.Modules.Project_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access is
      Object  : constant Project_Bean_Access := new Project_Bean;
      Metrics : constant Porion.Dashboards.Beans.Stats.Metrics_Bean_Access := Object.Metric'Access;
   begin
      Object.Module := Module;
      Object.Project_Bean := Object.Project'Access;
      Object.Metric_Bean := Object.Metric'Access;
      Object.Recipes_Bean := Object.Recipes'Access;
      Object.Builds_Bean := Object.Builds'Access;
      Porion.Dashboards.Beans.Stats.Initialize (Metrics);
      return Object.all'Access;
   end Create_Project_Bean;

end Porion.Projects.Beans;
