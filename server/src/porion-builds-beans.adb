-----------------------------------------------------------------------
--  porion-builds-beans -- Beans for module builds
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
with ADO.Queries;
with AWA.Services.Contexts;
with Porion.Services;
package body Porion.Builds.Beans is

   package ASC renames AWA.Services.Contexts;

   --  ------------------------------
   --  Get the value identified by the name.
   --  ------------------------------
   overriding
   function Get_Value (From : in Build_Bean;
                       Name : in String) return Util.Beans.Objects.Object is
   begin
      if Name = "project" then
         return Util.Beans.Objects.To_Object (Value   => From.Project_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "branch" then
         return Util.Beans.Objects.To_Object (Value   => From.Branch_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "node" then
         return Util.Beans.Objects.To_Object (Value   => From.Node_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "recipe" then
         return Util.Beans.Objects.To_Object (Value   => From.Recipe_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "metrics" then
         return Util.Beans.Objects.To_Object (Value   => From.Metrics_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "build_steps" then
         return Util.Beans.Objects.To_Object (Value   => From.Build_Steps_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "ident" then
         return UBO.To_Object (Porion.Projects.To_String (From.Ident));
      else
         return From.Build.Get_Value (Name);
      end if;
   end Get_Value;

   --  ------------------------------
   --  Set the value identified by the name.
   --  ------------------------------
   overriding
   procedure Set_Value (From  : in out Build_Bean;
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
   procedure Load (Bean    : in out Build_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String) is
      Ctx     : constant ASC.Service_Context_Access := ASC.Current;
      Context : Porion.Services.Context_Type;
      Query   : ADO.Queries.Context;
   begin
      Context.DB := ASC.Get_Master_Session (Ctx);

      if not Porion.Projects.Has_Build (Bean.Ident) then
         Outcome := To_UString ("not-found");
         return;
      end if;

      Context.Load (Bean.Ident);
      Bean.Build := Context.Build;
      Bean.Recipe := Context.Recipe;
      Bean.Project := Context.Project;
      Bean.Node := Context.Build_Node;
      Bean.Branch := Context.Branch;
      Bean.Metrics.Build := Context.Build.Get_Id;
      Bean.Metrics.Load (Outcome);

      Query.Set_Query (Porion.Queries.Query_Build_Recipe_List);
      Query.Bind_Param ("build_id", Context.Build.Get_Id);
      Porion.Queries.List (Bean.Build_Steps, Context.DB, Query);

      --  Query.Set_Query (Porion.Queries.Query_Stat_Metrics);
      --  Porion.Queries.List (List, Session, Query);
   exception
      when Porion.Services.Not_Found =>
         Outcome := To_UString ("not-found");

   end Load;

   --  ------------------------------
   --  Create the Build_Bean bean instance.
   --  ------------------------------
   function Create_Build_Bean (Module : in Porion.Builds.Modules.Build_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access is
      Object  : constant Build_Bean_Access := new Build_Bean;
      Metrics : constant Porion.Dashboards.Beans.Stats.Metrics_Bean_Access
         := Object.Metrics'Access;
   begin
      Object.Module := Module;
      Object.Build_Bean := Object.Build'Access;
      Object.Recipe_Bean := Object.Recipe'Access;
      Object.Project_Bean := Object.Project'Access;
      Object.Branch_Bean := Object.Branch'Access;
      Object.Node_Bean := Object.Node'Access;
      Object.Metrics_Bean := Metrics.all'Access;
      Object.Build_Steps_Bean := Object.Build_Steps'Access;
      Porion.Dashboards.Beans.Stats.Initialize (Metrics);
      return Object.all'Access;
   end Create_Build_Bean;

end Porion.Builds.Beans;
