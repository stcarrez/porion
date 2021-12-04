-----------------------------------------------------------------------
--  porion-reports -- Report generation
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
with Ada.Calendar.Formatting;
with Ada.Calendar.Time_Zones;
with Ada.Unchecked_Deallocation;
with Util.Strings;
with ADO.Queries;
with Porion.Projects;
with Porion.Metrics.Factories;
with Porion.XUnit.Models;
with Porion.Projects.Models;
package body Porion.Reports is

   function Get_Tag (Tag : in UString) return String;
   function Get_Image (Step : in Porion.Builds.Step_Type) return String;
   function Get_Kind (Kind : in Porion.Nodes.Node_Type) return String;

   procedure Free is
      new Ada.Unchecked_Deallocation (Object => Porion.Metrics.Reporter_Type'Class,
                                      Name   => Porion.Metrics.Reporter_Access);

   To_Digit : constant array (0 .. 9) of Character := "0123456789";

   function Format (Date : in Ada.Calendar.Time) return String is
      use Ada.Calendar;

      Result : constant String := Formatting.Image (Date, True,
                                                    Time_Zones.UTC_Time_Offset (Date));
   begin
      if Result'Length > 16 then
         --  Drop the seconds.
         return Result (Result'First .. Result'First + 15);
      else
         return Result;
      end if;
   end Format;

   --  ------------------------------
   --  Format a duration using SS or MM:SS format.
   --  ------------------------------
   function Format (Value : in Duration) return String is
      Secs    : Natural := Natural (Value);
      Mins    : Natural := Secs / 60;
      Hours   : constant Natural := Secs / 3600;
   begin
      if Secs <= 59 then
         return Util.Strings.Image (Secs);
      elsif Secs <= 3600 then
         Secs := Secs mod 60;
         return Util.Strings.Image (Mins) & ":"
            & To_Digit (Secs / 10) & To_Digit (Secs mod 10);
      else
         Secs := Secs mod 60;
         Mins := Mins mod 60;
         return Util.Strings.Image (Hours) & ":"
            & To_Digit (Mins / 10) & To_Digit (Mins mod 10)
            & To_Digit (Secs / 10) & To_Digit (Secs mod 10);
      end if;
   end Format;

   --  ------------------------------
   --  Format a duration expressed in milliseconds.
   --  ------------------------------
   function Format (Value : in Millisecond_Type) return String is
      Ms   : constant Natural := Natural (Value mod 1000);
      Ms2  : constant Natural := Ms mod 100;
      Ms3  : constant Natural := Ms2 mod 10;
      Secs : constant Natural := Natural (Value / 1000);
      Mins : Natural;
   begin
      if Ms2 = 0 then
         return Util.Strings.Image (Secs) & "." & To_Digit (Ms / 100);
      elsif Ms3 = 0 then
         return Util.Strings.Image (Secs) & "." & To_Digit (Ms / 100) & To_Digit (Ms2 / 10);
      elsif Secs < 60 then
         return Util.Strings.Image (Secs) & "." & To_Digit (Ms / 100) & To_Digit (Ms2 / 10)
                   & To_Digit (Ms3);
      else
         Mins := Secs / 60;
         return Util.Strings.Image (Mins) & ":"
                   & Util.Strings.Image (Secs mod 60)
                   & "." & To_Digit (Ms / 100);
      end if;
   end Format;

   --  ------------------------------
   --  Format a duration expressed in microseconds.
   --  ------------------------------
   function Format (Value : in Microsecond_Type) return String is
   begin
      if Value < 1000 then
         return Util.Strings.Image (Natural (Value)) & " us";
      elsif Value < 1_000_000 then
         declare
            Us  : constant Natural := Natural (Value mod 1_000);
            Us2 : constant Natural := Us mod 100;
            Us3 : constant Natural := Us2 mod 10;
         begin
            return Util.Strings.Image (Natural (Value / 1_000)) & "."
               & To_Digit (Us / 100) & To_Digit (Us2 / 10) & To_Digit (Us3) & " ms";
         end;
      else
         return Format (Millisecond_Type (Value / 1_000)) & " s";
      end if;
   end Format;

   --  ------------------------------
   --  Format a percent of DV on the value.
   --  ------------------------------
   function Format_Percent (Dv    : in Integer;
                            Value : in Integer) return String is
      Val   : Integer := (Dv * 1000) / Value;
      Div   : Natural;
      Sign  : Character;
   begin
      if Val < 0 then
         Val := -Val;
         Sign := '-';
      else
         Sign := '+';
      end if;
      Div := Val mod 10;
      return Sign & Util.Strings.Image (Val / 10) & '.' & To_Digit (Div);
   end Format_Percent;

   function Get_Tag (Tag : in UString) return String is
      Value : constant String := To_String (Tag);
   begin
      if Value'Length > 8 then
         return Value (Value'First .. Value'First + 7);
      else
         return Value;
      end if;
   end Get_Tag;

   function Get_Image (Step : in Porion.Builds.Step_Type) return String is
      use Porion.Builds;
   begin
      case Step is
         when STEP_CHECKOUT =>
            return -("checkout");

         when STEP_SETUP =>
            return -("setup");

         when STEP_GENERATE =>
            return -("generate");

         when STEP_CONFIGURE =>
            return -("configure");

         when STEP_MAKE =>
            return -("make");

         when STEP_TEST =>
            return -("test");

         when STEP_PACKAGE =>
            return -("package");

         when STEP_INSTALL =>
            return -("install");

         when STEP_PUBLISH =>
            return -("publish");

         when STEP_METRIC =>
            return -("metric");

      end case;
   end Get_Image;

   function Get_Kind (Kind : in Porion.Nodes.Node_Type) return String is
      use Porion.Nodes;
   begin
      case Kind is
         when NODE_LOCAL =>
            return -("local");

         when NODE_SSH =>
            return -("ssh");

         when NODE_DOCKER =>
            return -("docker");

         when NODE_VIRSH =>
            return -("virsh");

      end case;
   end Get_Kind;

   function Get_Status (Status : in Porion.Nodes.Node_Status_Type) return String is
      use Porion.Nodes;
   begin
      case Status is
         when NODE_DISABLED =>
            return -("disabled");

         when NODE_ENABLED =>
            return -("enabled");

         when NODE_STARTING =>
            return -("starting");

         when NODE_ONLINE =>
            return -("online");

         when NODE_STOPPING =>
            return -("stopping");

         when NODE_OFFLINE =>
            return -("offline");

         when NODE_ERROR =>
            return -("error");

      end case;
   end Get_Status;

   --  ------------------------------
   --  Create a report about the builds.  If the service is configured with
   --  a project, the report only indicates the builds of the project.
   --  ------------------------------
   procedure List_Builds (Service : in out Porion.Services.Context_Type'Class;
                          Printer : in out PT.Printer_Type'Class;
                          Styles  : in Style_Configuration) is
      List   : Porion.Queries.Build_Info_Vector;
      Query  : ADO.Queries.Context;
   begin
      if Service.Project.Is_Null then
         Query.Set_Query (Porion.Queries.Query_Build_List);
      else
         Query.Set_Query (Porion.Queries.Query_Project_Last_Build_List);
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
      end if;
      Porion.Queries.List (List, Service.DB, Query);

      List_Builds (List, Printer, Styles, -("Identifier"));
   end List_Builds;

   --  ------------------------------
   --  Create a report about the builds.  If the service is configured with
   --  a project, the report only indicates the builds of the project.
   --  ------------------------------
   procedure List_Builds (List    : in Porion.Queries.Build_Info_Vector;
                          Printer : in out PT.Printer_Type'Class;
                          Styles  : in Style_Configuration;
                          Label   : in String) is
      use Porion.Builds.Models;
      use Porion.Projects.Models;

      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Fields : PT.Texts.Field_Array (1 .. 8);
      Style1 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
      Style2 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
   begin
      Writer.Set_Justify (Style2, PT.J_RIGHT);
      Writer.Create_Field (Fields (1), Style1, 40.0);
      Writer.Create_Field (Fields (2), Style1, 0.0);
      Writer.Create_Field (Fields (3), Style2, 0.0);
      Writer.Create_Field (Fields (4), Style2, 0.0);
      Writer.Create_Field (Fields (5), Style2, 0.0);
      Writer.Create_Field (Fields (6), Style1, 0.0);
      Writer.Create_Field (Fields (7), Style2, 0.0);

      Writer.Set_Max_Dimension (Fields (2), (W => 8, H => 0));
      Writer.Set_Max_Dimension (Fields (3), (W => 8, H => 0));
      Writer.Set_Max_Dimension (Fields (4), (W => 4, H => 0));
      Writer.Set_Max_Dimension (Fields (5), (W => 4, H => 0));
      Writer.Set_Max_Dimension (Fields (6), (W => 16, H => 0));
      Writer.Set_Max_Dimension (Fields (7), (W => 10, H => 0));
      for Field of Fields (1 .. 6) loop
         Writer.Set_Bottom_Right_Padding (Field, (W => 1, H => 0));
      end loop;

      Writer.Layout_Fields (Fields);
      Writer.Put (Fields (1), Label);
      Writer.Put (Fields (2), -("Tag"));
      Writer.Put (Fields (3), -("Status"));
      Writer.Put (Fields (4), -("Pass"));
      Writer.Put (Fields (5), -("Fail"));
      Writer.Put (Fields (6), -("Date"));
      Writer.Put (Fields (7), -("Duration"));
      Writer.New_Line;

      for Build of List loop
         if Build.Project_Status /= Projects.Models.PROJECT_ACTIVE then
            Writer.Copy_Style (To => Style1, From => Styles.Disabled);
            Writer.Copy_Style (To => Style2, From => Styles.Disabled);
         elsif Build.Build_Date.Is_Null then
            Writer.Copy_Style (To => Style1, From => Styles.Disabled);
            Writer.Copy_Style (To => Style2, From => Styles.Disabled);
         elsif Build.Build_Status = Builds.Models.BUILD_PASS then
            Writer.Copy_Style (To => Style1, From => Styles.Success);
            Writer.Copy_Style (To => Style2, From => Styles.Success);
         else
            Writer.Copy_Style (To => Style1, From => Styles.Error);
            Writer.Copy_Style (To => Style2, From => Styles.Error);
         end if;
         Writer.Set_Justify (Style2, PT.J_RIGHT);

         declare
            Ident : Porion.Projects.Ident_Type;
         begin
            Ident.Name := Build.Name;
            Ident.Branch := Build.Branch_Name;
            Ident.Recipe := Build.Recipe_Name;
            Ident.Node := Build.Node_Name;
            Ident.Build := Build.Build_Number;
            Writer.Put (Fields (1), Porion.Projects.To_String (Ident));
         end;
         Writer.Put (Fields (2), Get_Tag (Build.Build_Tag));
         if Build.Build_Status = Builds.Models.BUILD_PASS then
            Writer.Put (Fields (3), -("OK"));
         else
            Writer.Put (Fields (3), -("KO"));
         end if;
         Writer.Put_Int (Fields (4), Build.Pass_Count);
         Writer.Put_Int (Fields (5), Build.Fail_Count);
         Writer.Put (Fields (6), Format (Build.Build_Date.Value));
         if Build.Build_Duration > 0 then
            Writer.Put (Fields (7), Format (Build.Build_Duration));
         end if;
         Writer.New_Line;
      end loop;
   end List_Builds;

   --  ------------------------------
   --  Create a report about the projects.
   --  ------------------------------
   procedure List_Projects (Service : in out Porion.Services.Context_Type'Class;
                            Printer : in out PT.Printer_Type'Class;
                            Styles  : in Style_Configuration) is
      List   : Porion.Queries.Project_Info_Vector;
      Query  : ADO.Queries.Context;
   begin
      Query.Set_Query (Porion.Queries.Query_Project_List);
      Porion.Queries.List (List, Service.DB, Query);

      List_Projects (List, Printer, Styles, -("Identifier"));
   end List_Projects;

   --  ------------------------------
   --  Create a report about the projects.
   --  ------------------------------
   procedure List_Projects (List    : in Porion.Queries.Project_Info_Vector;
                            Printer : in out PT.Printer_Type'Class;
                            Styles  : in Style_Configuration;
                            Label   : in String) is
      use Porion.Builds.Models;
      use Porion.Projects.Models;

      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Fields : PT.Texts.Field_Array (1 .. 8);
      Style1 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
      Style2 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
   begin
      Writer.Set_Justify (Style2, PT.J_RIGHT);
      Writer.Create_Field (Fields (1), Style1, 30.0);
      Writer.Create_Field (Fields (2), Style1, 0.0);
      Writer.Create_Field (Fields (3), Style1, 0.0);
      Writer.Create_Field (Fields (4), Style2, 0.0);
      Writer.Create_Field (Fields (5), Style2, 0.0);
      Writer.Create_Field (Fields (6), Style2, 0.0);
      Writer.Create_Field (Fields (7), Style1, 0.0);

      Writer.Set_Max_Dimension (Fields (2), (8, 1));
      Writer.Set_Max_Dimension (Fields (3), (6, 1));
      Writer.Set_Max_Dimension (Fields (4), (8, 1));
      Writer.Set_Max_Dimension (Fields (5), (6, 1));
      Writer.Set_Max_Dimension (Fields (6), (6, 1));
      Writer.Set_Max_Dimension (Fields (7), (16, 1));
      for I in 1 .. 6 loop
         Writer.Set_Bottom_Right_Padding (Fields (I), (1, 0));
      end loop;

      Writer.Layout_Fields (Fields);
      Writer.Put (Fields (1), Label);
      Writer.Put (Fields (2), -("Tag"));
      Writer.Put (Fields (3), -("Build"));
      Writer.Put (Fields (4), -("Status"));
      Writer.Put (Fields (5), -("Pass"));
      Writer.Put (Fields (6), -("Fail"));
      Writer.Put (Fields (7), -("Date"));
      Writer.New_Line;

      for Project of List loop
         if Project.Project_Status /= Projects.Models.PROJECT_ACTIVE then
            Writer.Copy_Style (To => Style1, From => Styles.Disabled);
            Writer.Copy_Style (To => Style2, From => Styles.Disabled);
         elsif Project.Build_Date.Is_Null then
            Writer.Copy_Style (To => Style1, From => Styles.Disabled);
            Writer.Copy_Style (To => Style2, From => Styles.Disabled);
         elsif Project.Build_Status = Builds.Models.BUILD_PASS then
            Writer.Copy_Style (To => Style1, From => Styles.Success);
            Writer.Copy_Style (To => Style2, From => Styles.Success);
         else
            Writer.Copy_Style (To => Style1, From => Styles.Error);
            Writer.Copy_Style (To => Style2, From => Styles.Error);
         end if;

         Writer.Set_Justify (Style2, PT.J_RIGHT);
         declare
            Ident : Porion.Projects.Ident_Type;
         begin
            Ident.Name := Project.Name;
            Ident.Branch := Project.Branch_Name;
            Writer.Put (Fields (1), Porion.Projects.To_String (Ident));
         end;
         Writer.Put (Fields (2), Get_Tag (Project.Branch_Tag));
         if not Project.Build_Date.Is_Null then
            Writer.Put_Int (Fields (3), Project.Build_Number);
            if Project.Build_Status = Builds.Models.BUILD_PASS then
               Writer.Put (Fields (4), -("OK"));
            else
               Writer.Put (Fields (4), -("KO"));
            end if;
            Writer.Put_Int (Fields (5), Project.Pass_Count);
            Writer.Put_Int (Fields (6), Project.Fail_Count);
            Writer.Put (Fields (7), Format (Project.Build_Date.Value));
         end if;
         Writer.New_Line;
      end loop;
   end List_Projects;

   --  ------------------------------
   --  Create a report with the list of commands to build the project.
   --  ------------------------------
   procedure List_Commands (Commands : in Porion.Executors.Command_Vector;
                            Printer  : in out PT.Printer_Type'Class;
                            Styles   : in Style_Configuration) is
      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Fields : PT.Texts.Field_Array (1 .. 3);
      Style1 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
      Style2 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
      Step   : Natural := 0;
   begin
      Writer.Set_Justify (Style2, PT.J_RIGHT);
      Writer.Create_Field (Fields (1), Style1, 0.0);
      Writer.Create_Field (Fields (2), Style1, 0.0);
      Writer.Create_Field (Fields (3), Style1, 0.0);

      Writer.Set_Bottom_Right_Padding (Fields (1), (W => 1, H => 0));
      Writer.Set_Bottom_Right_Padding (Fields (2), (W => 1, H => 0));

      for Cmd of Commands loop
         Writer.Will_Put (Fields (1), Util.Strings.Image (Step) & ".");
         Writer.Will_Put (Fields (2), Get_Image (Cmd.Step));
      end loop;

      Writer.Layout_Fields (Fields);
      Writer.Put (Fields (1), -("No"));
      Writer.Put (Fields (2), -("Step"));
      Writer.Put (Fields (3), -("Command"));
      Writer.New_Line;

      for Cmd of Commands loop
         Step := Step + 1;
         Writer.Put (Fields (1), Util.Strings.Image (Step) & ".");
         Writer.Put (Fields (2), Get_Image (Cmd.Step));
         Writer.Put (Fields (3), Cmd.Command);
         Writer.New_Line;
      end loop;
   end List_Commands;

   --  ------------------------------
   --  Create a report about the build nodes.  If the service is configured with
   --  a project, the report only indicates the build nodes of the project.
   --  ------------------------------
   procedure List_Nodes (Service : in out Porion.Services.Context_Type'Class;
                         Printer : in out PT.Printer_Type'Class;
                         Styles  : in Style_Configuration) is
      List   : Porion.Queries.Node_Info_Vector;
      Query  : ADO.Queries.Context;
   begin
      if Service.Project.Is_Null then
         Query.Set_Query (Porion.Queries.Query_Node_List);
      else
         Query.Set_Query (Porion.Queries.Query_Project_Node_List);
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
      end if;
      Porion.Queries.List (List, Service.DB, Query);

      List_Nodes (List, Printer, Styles, -("Kind"));
   end List_Nodes;

   procedure List_Nodes (List    : in Porion.Queries.Node_Info_Vector;
                         Printer : in out PT.Printer_Type'Class;
                         Styles  : in Style_Configuration;
                         Label   : in String) is
      use Porion.Nodes;

      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Fields : PT.Texts.Field_Array (1 .. 9);
      Style1 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
      Style2 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
   begin
      Writer.Set_Justify (Style2, PT.J_RIGHT);
      Writer.Create_Field (Fields (1), Style1, 0.0);
      Writer.Create_Field (Fields (2), Style1, 0.0);
      Writer.Create_Field (Fields (3), Style1, 0.0);
      Writer.Create_Field (Fields (4), Style1, 0.0);
      Writer.Create_Field (Fields (5), Style1, 10.0);
      Writer.Create_Field (Fields (6), Style2, 10.0);
      Writer.Create_Field (Fields (7), Style1, 10.0);
      Writer.Create_Field (Fields (8), Style1, 10.0);
      Writer.Create_Field (Fields (9), Style1, 20.0);

      Writer.Set_Max_Dimension (Fields (1), (8, 1));
      Writer.Set_Max_Dimension (Fields (2), (8, 1));
      Writer.Set_Max_Dimension (Fields (3), (7, 1));
      Writer.Set_Max_Dimension (Fields (4), (7, 1));
      Writer.Set_Max_Dimension (Fields (5), (7, 1));
      Writer.Set_Max_Dimension (Fields (6), (7, 1));
      Writer.Set_Bottom_Right_Padding (Fields (1), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (2), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (3), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (4), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (6), (1, 0));

      Writer.Layout_Fields (Fields);
      Writer.Put (Fields (1), Label);
      Writer.Put (Fields (2), -("Status"));
      Writer.Put (Fields (3), -("Recipes"));
      Writer.Put (Fields (4), -("Builds"));
      Writer.Put (Fields (5), -("OS"));
      Writer.Put (Fields (6), -("CPU"));
      Writer.Put (Fields (7), -("Hostname"));
      Writer.Put (Fields (8), -("Login"));
      Writer.Put (Fields (9), -("Directory"));
      Writer.New_Line;

      for Node of List loop
         if Node.Status = Nodes.NODE_DISABLED then
            Writer.Copy_Style (To => Style1, From => Styles.Disabled);
            Writer.Copy_Style (To => Style2, From => Styles.Disabled);
         elsif Node.Status = Nodes.NODE_ERROR then
            Writer.Copy_Style (To => Style1, From => Styles.Error);
            Writer.Copy_Style (To => Style2, From => Styles.Error);
         elsif Node.Status = Nodes.NODE_ONLINE then
            Writer.Copy_Style (To => Style1, From => Styles.Success);
            Writer.Copy_Style (To => Style2, From => Styles.Success);
         else
            Writer.Copy_Style (To => Style1, From => Styles.Default);
            Writer.Copy_Style (To => Style2, From => Styles.Default);
         end if;

         Writer.Set_Justify (Style2, PT.J_RIGHT);
         Writer.Put (Fields (1), Get_Kind (Node.Kind));
         Writer.Put (Fields (2), Get_Status (Node.Status));
         Writer.Put_Int (Fields (3), Node.Recipe_Count);
         Writer.Put_Int (Fields (4), Node.Build_Count);
         if Ada.Strings.Unbounded.Length (Node.Os_Version) > 0 then
            Writer.Put (Fields (5), To_String (Node.OS_Name)
                        & " " & To_String (Node.OS_Version));
         else
            Writer.Put_UString (Fields (5), Node.OS_Name);
         end if;
         Writer.Put_UString (Fields (6), Node.Cpu_Type);
         Writer.Put_UString (Fields (7), Node.Name);
         Writer.Put_UString (Fields (8), Node.Login);
         Writer.Put_UString (Fields (9), Node.Repository_Dir);
         Writer.New_Line;
      end loop;
   end List_Nodes;

   --  ------------------------------
   --  Create a report about the build queues.  If the service is configured with
   --  a project, the report only indicates the build queued of the project.
   --  ------------------------------
   procedure List_Queues (Service : in out Porion.Services.Context_Type'Class;
                          Printer : in out PT.Printer_Type'Class;
                          Styles  : in Style_Configuration) is
      List   : Porion.Queries.Queue_Info_Vector;
      Query  : ADO.Queries.Context;
   begin
      if Service.Project.Is_Null then
         Query.Set_Query (Porion.Queries.Query_Build_Queue_List);
      else
         Query.Set_Query (Porion.Queries.Query_Project_Build_Queue_List);
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
      end if;
      Porion.Queries.List (List, Service.DB, Query);

      List_Queues (List, Printer, Styles, -("Create date"));
   end List_Queues;

   procedure List_Queues (List    : in Porion.Queries.Queue_Info_Vector;
                          Printer : in out PT.Printer_Type'Class;
                          Styles  : in Style_Configuration;
                          Label   : in String;
                          Hide_Project : in Boolean := False) is
      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Fields : PT.Texts.Field_Array (1 .. 7);
      Style1 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
   begin
      Writer.Create_Field (Fields (1), Style1, 20.0);
      Writer.Create_Field (Fields (2), Style1, 0.0);
      if Hide_Project then
         Writer.Create_Field (Fields (3), Style1, 1.0);
         Writer.Set_Max_Dimension (Fields (3), (0, 0));
      else
         Writer.Create_Field (Fields (3), Style1, 10.0);
      end if;
      Writer.Create_Field (Fields (4), Style1, 10.0);
      Writer.Create_Field (Fields (5), Style1, 10.0);
      Writer.Create_Field (Fields (6), Style1, 10.0);
      Writer.Create_Field (Fields (7), Style1, 10.0);

      Writer.Set_Max_Dimension (Fields (2), (8, 1));

      Writer.Set_Bottom_Right_Padding (Fields (1), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (2), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (3), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (4), (1, 0));

      Writer.Layout_Fields (Fields);
      Writer.Put (Fields (1), Label);
      Writer.Put (Fields (2), -("Order"));
      if not Hide_Project then
         Writer.Put (Fields (3), -("Project"));
      end if;
      Writer.Put (Fields (4), -("Branch"));
      Writer.Put (Fields (5), -("Tag"));
      Writer.Put (Fields (6), -("Recipe"));
      Writer.Put (Fields (7), -("Hostname"));
      Writer.New_Line;

      for Queue of List loop
         if Queue.Building then
            Writer.Copy_Style (To => Style1, From => Styles.Success);
         else
            Writer.Copy_Style (To => Style1, From => Styles.Default);
         end if;
         Writer.Put (Fields (1), Format (Queue.Creation_Date));
         Writer.Put_Int (Fields (2), Queue.Order);
         if not Hide_Project then
            Writer.Put_UString (Fields (3), Queue.Project_Name);
         end if;
         Writer.Put_UString (Fields (4), Queue.Branch_Name);
         Writer.Put (Fields (5), Get_Tag (Queue.Branch_Tag));
         Writer.Put_UString (Fields (6), Queue.Recipe_Name);
         Writer.Put_UString (Fields (7), Queue.Node_Name);
         Writer.New_Line;
      end loop;
   end List_Queues;

   --  ------------------------------
   --  Create a report with the unit tests for the given build.
   --  ------------------------------
   procedure List_Tests (Service : in out Porion.Services.Context_Type'Class;
                         Build   : in Porion.Builds.Models.Build_Ref;
                         Printer : in out PT.Printer_Type'Class;
                         Styles  : in Style_Configuration;
                         Failed_Only : in Boolean) is
      List   : Porion.Queries.Test_Info_Vector;
      Query  : ADO.Queries.Context;
   begin
      Query.Bind_Param ("build_id", Build.Get_Id);
      Query.Set_Query (Porion.Queries.Query_Build_Test_List);
      if Failed_Only then
         Query.Set_Join ("AND run.status != 0");
      end if;
      Porion.Queries.List (List, Service.DB, Query);

      List_Tests (List, Printer, Styles);
   end List_Tests;

   --  ------------------------------
   --  Create a report with the unit tests.
   --  ------------------------------
   procedure List_Tests (List     : in Porion.Queries.Test_Info_Vector;
                         Printer  : in out PT.Printer_Type'Class;
                         Styles   : in Style_Configuration) is
      use type Porion.XUnit.Models.Test_Status_Type;

      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Fields : PT.Texts.Field_Array (1 .. 4);
      Style1 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
   begin
      Writer.Create_Field (Fields (1), Style1, 30.0);
      Writer.Create_Field (Fields (2), Style1, 50.0);
      Writer.Create_Field (Fields (3), Style1, 10.0);
      Writer.Create_Field (Fields (4), Style1, 10.0);

      Writer.Set_Bottom_Right_Padding (Fields (1), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (2), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (3), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (4), (1, 0));

      Writer.Layout_Fields (Fields);
      Writer.Put (Fields (1), -("Group"));
      Writer.Put (Fields (2), -("Test"));
      Writer.Put (Fields (3), -("Duration"));
      Writer.Put (Fields (4), -("Rate"));
      Writer.New_Line;

      for Test of List loop
         if Test.Test_Status = Porion.XUnit.Models.TEST_FAIL then
            Writer.Copy_Style (To => Style1, From => Styles.Error);
         else
            Writer.Copy_Style (To => Style1, From => Styles.Default);
         end if;
         Writer.Put_UString (Fields (1), Test.Group_Name);
         Writer.Put_UString (Fields (2), Test.Test_Name);
         Writer.Set_Justify (Style1, PT.J_RIGHT);
         Writer.Put (Fields (3), Format (Test.Test_Duration));
         Writer.New_Line;
      end loop;
   end List_Tests;

   --  ------------------------------
   --  Create a report with the build metrics for the given build.
   --  ------------------------------
   procedure List_Metrics (Service : in out Porion.Services.Context_Type'Class;
                           Build   : in Porion.Builds.Models.Build_Ref;
                           Printer : in out PT.Printer_Type'Class;
                           Styles  : in Style_Configuration) is
      List   : Porion.Queries.Metric_Info_Vector;
      Query  : ADO.Queries.Context;
   begin
      Query.Bind_Param ("build_id", Build.Get_Id);
      Query.Set_Query (Porion.Queries.Query_Build_Metrics);
      Porion.Queries.List (List, Service.DB, Query);

      List_Metrics (List, Printer, Styles);
   end List_Metrics;

   --  ------------------------------
   --  Create a report with the build metrics.
   --  ------------------------------
   procedure List_Metrics (List     : in Porion.Queries.Metric_Info_Vector;
                           Printer  : in out PT.Printer_Type'Class;
                           Styles   : in Style_Configuration) is
      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Fields : PT.Texts.Field_Array (1 .. 4);
      Style1 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
   begin
      Writer.Create_Field (Fields (1), Style1, 30.0);
      Writer.Create_Field (Fields (2), Style1, 20.0);
      Writer.Create_Field (Fields (3), Style1, 25.0);
      Writer.Create_Field (Fields (4), Style1, 25.0);

      for Metric in Porion.Metrics.Metric_Type'Range loop
         List_Metrics (List, Metric, Printer, Fields, Styles);
      end loop;
   end List_Metrics;

   procedure List_Metrics (List     : in Porion.Queries.Metric_Info_Vector;
                           Metric   : in Porion.Metrics.Metric_Type;
                           Printer  : in out PT.Printer_Type'Class;
                           Fields   : in PT.Texts.Field_Array;
                           Styles   : in Style_Configuration) is
      pragma Unreferenced (Styles);

      use type Porion.Metrics.Metric_Type;
      use type Porion.Metrics.Reporter_Access;

      Values     : Porion.Metrics.Value_Map;
      Controller : Porion.Metrics.Reporter_Access := Porion.Metrics.Factories.Create (Metric);
   begin
      if Controller = null then
         return;
      end if;

      for Value of List loop
         if Value.Kind = Metric then
            Values.Include (Key => To_String (Value.Name),
                            New_Item => (Length  => Length (Value.Label),
                                         Value   => Value.Value,
                                         Content => Value.Content,
                                         Label   => To_String (Value.Label)));
         end if;
      end loop;

      if not Values.Is_Empty then
         Controller.Report (Printer, Fields, Values);
      end if;

      Free (Controller);
   end List_Metrics;

   --  ------------------------------
   --  Create a report with the build environment variables.
   --  ------------------------------
   procedure List_Environment (Service : in out Porion.Services.Context_Type'Class;
                               Printer : in out PT.Printer_Type'Class;
                               Styles  : in Style_Configuration) is
      List   : Porion.Queries.Environment_Info_Vector;
      Query  : ADO.Queries.Context;
   begin
      Query.Set_Query (Porion.Queries.Query_Environment_List);
      Porion.Queries.List (List, Service.DB, Query);

      List_Environment (List, Printer, Styles);
   end List_Environment;

   procedure List_Environment (List     : in Porion.Queries.Environment_Info_Vector;
                               Printer  : in out PT.Printer_Type'Class;
                               Styles   : in Style_Configuration) is
      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Fields : PT.Texts.Field_Array (1 .. 2);
      Style1 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
   begin
      Writer.Create_Field (Fields (1), Style1, 30.0);
      Writer.Create_Field (Fields (2), Style1, 70.0);

      Writer.Set_Bottom_Right_Padding (Fields (1), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (2), (1, 0));

      Writer.Layout_Fields (Fields);
      Writer.Put (Fields (1), -("Ident"));
      Writer.Put (Fields (2), -("Environment"));
      Writer.New_Line;

      for Env of List loop
         declare
            use Ada.Strings.Unbounded;

            Ident : Porion.Projects.Ident_Type;
         begin
            Ident.Name := Env.Project_Name;
            Ident.Branch := Env.Branch_Name;
            Ident.Recipe := Env.Recipe_Name;
            Ident.Node := Env.Node_Name;

            Writer.Put (Fields (1), Porion.Projects.To_String (Ident));
            Writer.Put_UString (Fields (2), Env.Name & "=" & Env.Value);
            Writer.New_Line;
         end;
      end loop;
   end List_Environment;

end Porion.Reports;
