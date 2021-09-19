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
with PT.Texts;
with ADO.Queries;
with Porion.Queries;
with Porion.Builds.Models;
with Porion.Projects.Models;
package body Porion.Reports is

   function Format (Date : in Ada.Calendar.Time) return String is
      use Ada.Calendar;

      Result : String := Formatting.Image (Date, True,
                                           Time_Zones.UTC_Time_Offset (Date));
   begin
      if Result'Length > 16 then
         return Result (Result'First .. Result'First + 15);
      else
         return Result;
      end if;
   end Format;

   --  ------------------------------
   --  Create a report about the builds.  If the service is configured with
   --  a project, the report only indicates the builds of the project.
   --  ------------------------------
   procedure List_Builds (Service : in out Porion.Services.Context_Type'Class;
                          Printer : in out PT.Printer_Type'Class;
                          Styles  : in Style_Configuration) is
      use Porion.Builds.Models;
      use Porion.Projects.Models;

      function Get_Tag (Info : in Porion.Queries.Build_Info) return String is
         Tag : constant String := To_String (Info.Build_Tag);
      begin
         if Tag'Length > 8 then
            return Tag (Tag'First .. Tag'First + 7);
         else
            return Tag;
         end if;
      end Get_Tag;

      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      List   : Porion.Queries.Build_Info_Vector;
      Query  : ADO.Queries.Context;
      Fields : PT.Texts.Field_Array (1 .. 8);
      Style1 : PT.Style_Type := Writer.Create_Style (Styles.Default);
      Style2 : PT.Style_Type := Writer.Create_Style (Styles.Default);
   begin
      if Service.Project.Is_Null then
         Query.Set_Query (Porion.Queries.Query_Build_List);
      else
         Query.Set_Query (Porion.Queries.Query_Project_Last_Build_List);
         Query.Bind_Param ("project_id", Service.Project.Get_Id);
      end if;
      Porion.Queries.List (List, Service.DB, Query);

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
      Writer.Put (Fields (1), -("Name"));
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
         Writer.Put (Fields (3), Get_Tag (Build));
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

end Porion.Reports;
