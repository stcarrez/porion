-----------------------------------------------------------------------
--  porion-dashboards-beans -- Beans for module dashboards
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
with ADO.Statements;
with AWA.Services.Contexts;
with Util.Dates;
package body Porion.Dashboards.Beans is

   package ASC renames AWA.Services.Contexts;
   use type ADO.Identifier;

   --  ------------------------------
   --  Get the first audit after the given date.
   --  ------------------------------
   function Get_First_Audit (Session : in ADO.Sessions.Session'Class;
                             After   : in Ada.Calendar.Time) return ADO.Identifier is
      Query    : ADO.Queries.Context;
   begin
      Query.Set_Query (Porion.Beans.Query_First_Audit_After_Date);
      Query.Bind_Param ("date", After);

      declare
         Stmt : ADO.Statements.Query_Statement := Session.Create_Statement (Query);
      begin
         Stmt.Execute;
         if not Stmt.Has_Elements or else Stmt.Is_Null (0) then
            return ADO.NO_IDENTIFIER;
         else
            return Stmt.Get_Identifier (0);
         end if;
      end;
   end Get_First_Audit;

   --  ------------------------------
   --  Find the position of the given project id within the project audit vector.
   --  ------------------------------
   function Find (List : in Project_Audit_Vectors.Vector;
                  Id  : in ADO.Identifier) return Project_Audit_Vectors.Cursor is
      Iter : Project_Audit_Vectors.Cursor := List.First;
   begin
      while Porion.Beans.Project_Audit_Vectors.Has_Element (Iter) loop
         exit when Project_Audit_Vectors.Element (Iter).Project_Id = Id;
         Project_Audit_Vectors.Next (Iter);
      end loop;
      return Iter;
   end Find;

   --  ------------------------------
   --  Get the date for the begining of the period to report.
   --  ------------------------------
   function Get_Period_Date (Period : in Report_Period_Type) return Ada.Calendar.Time is
      use type Ada.Calendar.Time;

      Now : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      case Period is
         when REPORT_DAY =>
            return Util.Dates.Get_Day_Start (Now);

         when REPORT_WEEK =>
            return Util.Dates.Get_Week_Start (Now);

         when REPORT_MONTH =>
            return Util.Dates.Get_Month_Start (Now);

         when REPORT_4WEEK =>
            return Util.Dates.Get_Week_Start (Now) - 4.0 * 7.0 * 86400.0;

      end case;
   end Get_Period_Date;

   --  ------------------------------
   --  Get the value identified by the name.
   --  ------------------------------
   overriding
   function Get_Value (From : in Project_Report_Bean;
                       Name : in String) return Util.Beans.Objects.Object is
   begin
      if Name = "config_change" then
         return UBO.To_Object (From.Config_Changes + From.Recipe_Changes);
      elsif Name = "build_count" then
         return UBO.To_Object (From.Build_Changes);
      elsif Name = "recipe_change" then
         return UBO.To_Object (From.Recipe_Changes);
      elsif Name = "source_change" then
         return UBO.To_Object (From.Source_Changes);
      else
         return Porion.Queries.Project_Info (From).Get_Value (Name);
      end if;
   end Get_Value;

   --  ------------------------------
   --  Get the value identified by the name.
   --  ------------------------------
   overriding
   function Get_Value (From : in Project_Report_List_Bean;
                       Name : in String) return UBO.Object is
   begin
      if Name = "projects" then
         return Util.Beans.Objects.To_Object (Value   => From.Projects_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      elsif Name = "period" then
         return Report_Period_Objects.To_Object (From.Period);
      else
         return Util.Beans.Objects.Null_Object;
      end if;
   end Get_Value;

   --  ------------------------------
   --  Set the value identified by the name.
   --  ------------------------------
   overriding
   procedure Set_Value (From  : in out Project_Report_List_Bean;
                        Name  : in String;
                        Value : in UBO.Object) is
   begin
      if Name = "period" then
         declare
            P : constant String := UBO.To_String (Value);
         begin
            if P = "week" then
               From.Period := REPORT_WEEK;
            elsif P = "month" then
               From.Period := REPORT_MONTH;
            elsif P = "day" then
               From.Period := REPORT_DAY;
            elsif P = "4week" then
               From.Period := REPORT_4WEEK;
            else
               From.Period := REPORT_WEEK;
            end if;
         end;
      end if;
   end Set_Value;

   function "<" (Left, Right : in Project_Report_Bean) return Boolean is
      use Ada.Strings.Unbounded;
   begin
      if Left.Source_Changes < Right.Source_Changes then
         return False;
      elsif Left.Source_Changes > Right.Source_Changes then
         return True;
      end if;

      if Left.Build_Changes < Right.Build_Changes then
         return False;
      elsif Left.Build_Changes > Right.Build_Changes then
         return True;
      end if;

      if Left.Recipe_Changes < Right.Recipe_Changes then
         return False;
      elsif Left.Recipe_Changes > Right.Recipe_Changes then
         return True;
      end if;

      if Left.Config_Changes < Right.Config_Changes then
         return False;
      elsif Left.Config_Changes > Right.Config_Changes then
         return True;
      end if;

      return Left.Name < Right.Name;
   end "<";

   package Sort_Project is
      new Project_Report_Beans.Vectors.Generic_Sorting ("<" => "<");

   --  ------------------------------
   --  Load the list of projects.
   --  ------------------------------
   procedure Load (Bean    : in out Project_Report_List_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String) is
      pragma Unreferenced (Outcome);

      Ctx      : constant ASC.Service_Context_Access := ASC.Current;
      Session  : ADO.Sessions.Session := ASC.Get_Session (Ctx);
      Query    : ADO.Queries.Context;
      Projects        : aliased Porion.Queries.Project_Info_List_Bean;
      Project_Changes : Project_Audit_Vectors.Vector;
      Recipe_Changes  : Project_Audit_Vectors.Vector;
      Build_Changes   : Project_Audit_Vectors.Vector;
      First_Audit     : ADO.Identifier;
      Date            : constant Ada.Calendar.Time := Get_Period_Date (Bean.Period);
   begin
      First_Audit := Get_First_Audit (Session, Date);

      --  Look for changes since the first audit change 1 day ago.
      if First_Audit /= ADO.NO_IDENTIFIER then
         Query.Set_Query (Porion.Beans.Query_Project_Change_Count);
         Query.Bind_Param ("last_audit", First_Audit);
         Porion.Beans.List (Project_Changes, Session, Query);

         Query.Set_Query (Porion.Beans.Query_Recipe_Change_Count);
         Query.Bind_Param ("last_audit", First_Audit);
         Porion.Beans.List (Recipe_Changes, Session, Query);

         Query.Set_Query (Porion.Beans.Query_Build_Count);
         Query.Bind_Param ("last_audit", First_Audit);
         Porion.Beans.List (Build_Changes, Session, Query);

      end if;

      Query.Set_Query (Porion.Queries.Query_Project_Summary_List);
      Porion.Queries.List (Projects, Session, Query);
      for Project of Projects.List loop
         declare
            Report : Project_Report_Bean;
            Pos    : Project_Audit_Vectors.Cursor;
         begin
            Porion.Queries.Project_Info (Report) := Project;
            Pos := Find (Project_Changes, Project.Project_Id);
            if Project_Audit_Vectors.Has_Element (Pos) then
               Report.Config_Changes := Project_Audit_Vectors.Element (Pos).Count;
               Project_Changes.Delete (Position => Pos);
            end if;

            Pos := Find (Recipe_Changes, Project.Project_Id);
            if Project_Audit_Vectors.Has_Element (Pos) then
               Report.Recipe_Changes := Project_Audit_Vectors.Element (Pos).Count;
               Recipe_Changes.Delete (Position => Pos);
            end if;

            Pos := Find (Build_Changes, Project.Project_Id);
            if Project_Audit_Vectors.Has_Element (Pos) then
               Report.Build_Changes := Project_Audit_Vectors.Element (Pos).Count;
               Report.Source_Changes := Project_Audit_Vectors.Element (Pos).Sum;
               Build_Changes.Delete (Pos);
            end if;

            Bean.Projects.List.Append (Report);
         end;
      end loop;
      Sort_Project.Sort (Bean.Projects.List);
   end Load;

   --  ------------------------------
   --  Create the project list bean instance.
   --  ------------------------------
   function Create_Project_Report_List_Bean (Module : in Modules.Dashboard_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access is
      Object : constant Project_Report_List_Bean_Access := new Project_Report_List_Bean;
   begin
      Object.Module := Module;
      Object.Projects_Bean := Object.Projects'Access;
      return Object.all'Access;
   end Create_Project_Report_List_Bean;

   --  ------------------------------
   --  Load the list of projects.
   --  ------------------------------
   procedure Load (Bean    : in out Project_List_Bean;
                   Outcome : in out Ada.Strings.Unbounded.Unbounded_String) is
      pragma Unreferenced (Outcome);

      Ctx     : constant ASC.Service_Context_Access := ASC.Current;
      Session : ADO.Sessions.Session := ASC.Get_Session (Ctx);
      Query   : ADO.Queries.Context;
   begin
      Query.Set_Query (Porion.Queries.Query_Project_Summary_List);
      Porion.Queries.List (Bean.Projects, Session, Query);
   end Load;

   --  ------------------------------
   --  Get the value identified by the name.
   --  ------------------------------
   overriding
   function Get_Value (From : in Project_List_Bean;
                       Name : in String) return UBO.Object is
   begin
      if Name = "projects" then
         return Util.Beans.Objects.To_Object (Value   => From.Projects_Bean,
                                              Storage => Util.Beans.Objects.STATIC);
      else
         return Util.Beans.Objects.Null_Object;
      end if;
   end Get_Value;

   --  ------------------------------
   --  Set the value identified by the name.
   --  ------------------------------
   overriding
   procedure Set_Value (From  : in out Project_List_Bean;
                        Name  : in String;
                        Value : in UBO.Object) is
   begin
      null;
   end Set_Value;

   --  ------------------------------
   --  Create the project list bean instance.
   --  ------------------------------
   function Create_Project_List_Bean (Module : in Modules.Dashboard_Module_Access)
      return Util.Beans.Basic.Readonly_Bean_Access is
      Object : constant Project_List_Bean_Access := new Project_List_Bean;
   begin
      Object.Module := Module;
      Object.Projects_Bean := Object.Projects'Access;
      return Object.all'Access;
   end Create_Project_List_Bean;

end Porion.Dashboards.Beans;
