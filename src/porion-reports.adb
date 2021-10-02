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
with Util.Strings;
with PT.Texts;
with ADO.Queries;
with Porion.Nodes;
with Porion.Builds.Models;
with Porion.Projects.Models;
package body Porion.Reports is

   function Get_Tag (Tag : in UString) return String;
   function Format (Date : in Ada.Calendar.Time) return String;
   function Get_Image (Step : in Porion.Builds.Step_Type) return String;
   function Get_Kind (Kind : in Porion.Nodes.Node_Type) return String;
   function Get_Status (Status : in Porion.Nodes.Node_Status_Type) return String;

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

      List_Builds (List, Printer, Styles, -("Name"));
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
      Writer.Create_Field (Fields (1), Style1, 20.0);
      Writer.Create_Field (Fields (2), Style1, 20.0);
      Writer.Create_Field (Fields (3), Style1, 10.0);
      Writer.Create_Field (Fields (4), Style2, 10.0);
      Writer.Create_Field (Fields (5), Style2, 0.0);
      Writer.Create_Field (Fields (6), Style2, 0.0);
      Writer.Create_Field (Fields (7), Style1, 30.0);

      Writer.Set_Max_Dimension (Fields (5), (W => 4, H => 0));
      Writer.Set_Max_Dimension (Fields (6), (W => 4, H => 0));
      for Field of Fields (2 .. 6) loop
         Writer.Set_Bottom_Right_Padding (Field, (W => 1, H => 0));
      end loop;

      Writer.Layout_Fields (Fields);
      Writer.Put (Fields (1), Label);
      Writer.Put (Fields (2), -("Branch"));
      Writer.Put (Fields (3), -("Tag"));
      Writer.Put (Fields (4), -("Status"));
      Writer.Put (Fields (5), -("Pass"));
      Writer.Put (Fields (6), -("Fail"));
      Writer.Put (Fields (7), -("Date"));
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
         Writer.Put_UString (Fields (1), Build.Name);
         Writer.Put_UString (Fields (2), Build.Branch_Name);
         Writer.Put (Fields (3), Get_Tag (Build.Build_Tag));
         if Build.Build_Status = Builds.Models.BUILD_PASS then
            Writer.Put (Fields (4), -("OK"));
         else
            Writer.Put (Fields (4), -("KO"));
         end if;
         Writer.Put_Int (Fields (5), Build.Pass_Count);
         Writer.Put_Int (Fields (6), Build.Fail_Count);
         Writer.Put (Fields (7), Format (Build.Build_Date.Value));
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

      List_Projects (List, Printer, Styles, -("Name"));
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
      Writer.Create_Field (Fields (1), Style1, 20.0);
      Writer.Create_Field (Fields (2), Style1, 20.0);
      Writer.Create_Field (Fields (3), Style1, 10.0);
      Writer.Create_Field (Fields (4), Style2, 10.0);
      Writer.Create_Field (Fields (5), Style2, 0.0);
      Writer.Create_Field (Fields (6), Style2, 0.0);
      Writer.Create_Field (Fields (7), Style1, 30.0);

      Writer.Set_Max_Dimension (Fields (5), (6, 1));
      Writer.Set_Max_Dimension (Fields (6), (6, 1));
      Writer.Set_Bottom_Right_Padding (Fields (5), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (6), (1, 0));

      Writer.Layout_Fields (Fields);
      Writer.Put (Fields (1), Label);
      Writer.Put (Fields (2), -("Branch"));
      Writer.Put (Fields (3), -("Tag"));
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
         Writer.Put_UString (Fields (1), Project.Name);
         Writer.Put_UString (Fields (2), Project.Branch_Name);
         Writer.Put (Fields (3), Get_Tag (Project.Branch_Tag));
         if not Project.Build_Date.Is_Null then
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
      Query.Set_Query (Porion.Queries.Query_Node_List);
      Porion.Queries.List (List, Service.DB, Query);

      List_Nodes (List, Printer, Styles, -("Name"));
   end List_Nodes;

   procedure List_Nodes (List    : in Porion.Queries.Node_Info_Vector;
                         Printer : in out PT.Printer_Type'Class;
                         Styles  : in Style_Configuration;
                         Label   : in String) is
      use Porion.Nodes;

      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Fields : PT.Texts.Field_Array (1 .. 7);
      Style1 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
      Style2 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
   begin
      Writer.Set_Justify (Style2, PT.J_RIGHT);
      Writer.Create_Field (Fields (1), Style1, 10.0);
      Writer.Create_Field (Fields (2), Style1, 20.0);
      Writer.Create_Field (Fields (3), Style1, 10.0);
      Writer.Create_Field (Fields (4), Style1, 20.0);
      Writer.Create_Field (Fields (5), Style2, 10.0);
      Writer.Create_Field (Fields (6), Style1, 0.0);
      Writer.Create_Field (Fields (7), Style1, 0.0);

      Writer.Set_Max_Dimension (Fields (6), (6, 1));
      Writer.Set_Max_Dimension (Fields (7), (6, 1));
      Writer.Set_Bottom_Right_Padding (Fields (5), (1, 0));
      Writer.Set_Bottom_Right_Padding (Fields (7), (1, 0));

      Writer.Layout_Fields (Fields);
      Writer.Put (Fields (1), -("Kind"));
      Writer.Put (Fields (2), -("Hostname"));
      Writer.Put (Fields (3), -("Login"));
      Writer.Put (Fields (4), -("Directory"));
      Writer.Put (Fields (5), -("Status"));
      Writer.Put (Fields (6), -("Configs"));
      Writer.Put (Fields (7), -("Builds"));
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
         Writer.Put_UString (Fields (2), Node.Name);
         Writer.Put_UString (Fields (3), Node.Login);
         Writer.Put_UString (Fields (4), Node.Repository_Dir);
         Writer.Put (Fields (5), Get_Status (Node.Status));
         Writer.Put_Int (Fields (6), Node.Config_Count);
         Writer.Put_Int (Fields (7), Node.Build_Count);
         Writer.New_Line;
      end loop;
   end List_Nodes;

end Porion.Reports;
