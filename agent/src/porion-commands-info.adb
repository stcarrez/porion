-----------------------------------------------------------------------
--  porion-commands-info -- Info command
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
with Porion.Projects.Models;
with Porion.Services;
with Porion.Queries;
with Porion.Builds.Models;
with Porion.Reports;
with Porion.Executors;
with Porion.Configs;
with ADO.Queries;
with PT.Texts;
with PT.Charts;
with Porion.Builds.Services;
package body Porion.Commands.Info is

   use type Porion.Builds.Models.Build_Status_Type;

   function Get_Max_Time (Build : in Builds.Models.Build_Ref) return Millisecond_Type;

   function "-" (Left, Right : Porion.Millisecond_Type) return PT.W_Type is
      (PT.W_Type (Porion.Millisecond_Type '(Left - Right)));

   procedure Draw_Progress is
      new PT.Charts.Draw_Bar (Porion.Millisecond_Type);

   function Get_Max_Time (Build : in Builds.Models.Build_Ref) return Millisecond_Type is
      Time : constant Millisecond_Type := Build.Get_User_Time + Build.Get_Sys_Time;
   begin
      return (if Time >= Build.Get_Build_Duration then Time else Build.Get_Build_Duration);
   end Get_Max_Time;

   procedure Print_Build (Command : in out Command_Type;
                          Ident   : in Porion.Projects.Ident_Type;
                          Context : in out Context_Type) is
      pragma Unreferenced (Command);

      Printer : PT.Texts.Printer_Type := PT.Texts.Create (Context.Printer.all);
      Chart   : PT.Charts.Printer_Type := PT.Charts.Create (Context.Printer.all);
      Fields  : PT.Texts.Field_Array (1 .. 10);
      Build   : constant Builds.Models.Build_Ref := Context.Project_Service.Build;
      Bar_Box : PT.Rect_Type;
   begin
      Printer.Create_Field (Fields (1), Context.Styles.Default, 20.0);
      Printer.Create_Field (Fields (2), Context.Styles.Success, 80.0);
      Printer.Layout_Fields (Fields (1 .. 2));
      Printer.Put (Fields (1), -("Project"));
      Printer.Put_UString (Fields (2), Ident.Name);
      Printer.New_Line;

      declare
         Description : constant String := Context.Project_Service.Project.Get_Description;
      begin
         if Description'Length > 0 then
            Printer.Put (Fields (1), -("Description:"));
            Printer.Put (Fields (2), Description);
            Printer.New_Line;
         end if;
      end;

      if Build.Get_Status /= Builds.Models.BUILD_PASS then
         Printer.Set_Style (Fields (2), Context.Styles.Error);
      end if;

      Printer.Put (Fields (1), -("Build number:"));
      Printer.Put_Int (Fields (2), Ident.Build);
      Printer.New_Line;

      Printer.Put (Fields (1), -("Tag:"));
      Printer.Put_UString (Fields (2), Build.Get_Tag);
      Printer.New_Line;

      Printer.Put (Fields (1), -("Build node:"));
      Printer.Put_UString (Fields (2), Build.Get_Node.Get_Name);
      Printer.New_Line;

      Printer.Put (Fields (1), -("Started on:"));
      Printer.Put (Fields (2), Reports.Format (Build.Get_Create_Date));
      Printer.New_Line;

      if not Build.Get_Finish_Date.Is_Null then
         Printer.Create_Field (Fields (1), Context.Styles.Default, 20.0);
         Printer.Create_Field (Fields (2), Context.Styles.Success, 20.0);
         Printer.Create_Field (Fields (3), Context.Styles.Success, 60.0);
         Printer.Layout_Fields (Fields (1 .. 3));

         if Build.Get_Status /= Builds.Models.BUILD_PASS then
            Printer.Set_Style (Fields (2), Context.Styles.Error);
            Printer.Set_Style (Fields (3), Context.Styles.Error);
         end if;

         Printer.Put (Fields (1), -("Finished on:"));
         Printer.Put (Fields (2), Reports.Format (Build.Get_Finish_Date.Value));
         Printer.New_Line;

         Printer.Put (Fields (1), -("Duration:"));
         Printer.Put (Fields (2), Reports.Format (Build.Get_Build_Duration));
         Bar_Box := Printer.Get_Box (Fields (3));
         Draw_Progress (Chart, Bar_Box, Build.Get_Build_Duration,
                        Max => Get_Max_Time (Build),
                        Style1 => Context.Styles.Success,
                        Style2 => Context.Styles.Disabled);
         Printer.New_Line;

         Printer.Put (Fields (1), -("User time:"));
         Printer.Put (Fields (2), Reports.Format (Build.Get_User_Time));
         Draw_Progress (Chart, Bar_Box, Build.Get_User_Time,
                        Max => Get_Max_Time (Build),
                        Style1 => Context.Styles.Success,
                        Style2 => Context.Styles.Disabled);
         Printer.New_Line;

         Printer.Put (Fields (1), -("System time:"));
         Printer.Put (Fields (2), Reports.Format (Build.Get_Sys_Time));
         Draw_Progress (Chart, Bar_Box, Build.Get_Sys_Time,
                        Max => Get_Max_Time (Build),
                        Style1 => Context.Styles.Success,
                        Style2 => Context.Styles.Disabled);
         Printer.New_Line;

         Porion.Reports.List_Metrics (Context.Project_Service, Build, Printer, Context.Styles);

         if Build.Get_Test_Duration > 0 then
            Printer.Put (Fields (1), -("Test duration:"));
            Printer.Put (Fields (2), Reports.Format (Build.Get_Test_Duration));
            Draw_Progress (Chart, Bar_Box, Millisecond_Type (Build.Get_Test_Duration / 1_000),
                           Max => Get_Max_Time (Build),
                           Style1 => Context.Styles.Success,
                           Style2 => Context.Styles.Disabled);
            Printer.New_Line;

            Printer.Create_Field (Fields (3), Context.Styles.Default, 20.0);
            Printer.Create_Field (Fields (4), Context.Styles.Success, 0.0);
            Printer.Create_Field (Fields (5), Context.Styles.Default, 0.0);
            Printer.Create_Field (Fields (6), Context.Styles.Error, 0.0);
            Printer.Create_Field (Fields (7), Context.Styles.Default, 0.0);
            Printer.Create_Field (Fields (8), Context.Styles.Error, 0.0);
            Printer.Create_Field (Fields (9), Context.Styles.Default, 60.0);
            for I in 4 .. 8 loop
               Printer.Set_Bottom_Right_Padding (Fields (I), (1, 0));
            end loop;
            Printer.Layout_Fields (Fields (3 .. 9));

            Printer.Put (Fields (3), -("Tests run:"));
            Printer.Put_Int (Fields (4), Build.Get_Pass_Count);
            if Build.Get_Fail_Count > 0 then
               Printer.Put (Fields (5), -("Failure:"));
               Printer.Put_Int (Fields (6), Build.Get_Fail_Count);
            end if;

            if Build.Get_Timeout_Count > 0 then
               Printer.Put (Fields (7), -("Timeout:"));
               Printer.Put_Int (Fields (8), Build.Get_Timeout_Count);
            end if;
            Draw_Progress (Chart, Bar_Box, Build.Get_Sys_Time,
                           Max => Get_Max_Time (Build),
                           Style1 => Context.Styles.Success,
                           Style2 => Context.Styles.Error);
            Printer.New_Line;

            Porion.Reports.List_Tests (Context.Project_Service, Build,
                                       Printer, Context.Styles, True);
         end if;
      end if;
   end Print_Build;

   procedure Print_Project (Command : in out Command_Type;
                            Ident   : in Porion.Projects.Ident_Type;
                            Context : in out Context_Type) is
      function Count_Active_Branches return Natural;
      use type Porion.Projects.Models.Branch_Status_Type;

      Printer     : PT.Texts.Printer_Type := PT.Texts.Create (Context.Printer.all);
      Fields      : PT.Texts.Field_Array (1 .. 10);
      Last_Builds : Porion.Queries.Build_Info_Vector;
      Executor    : Porion.Executors.Executor_Type;
      Recipes     : Porion.Builds.Models.Recipe_Vector;
      Branches    : Porion.Queries.Branch_Info_Vector;
      Query       : ADO.Queries.Context;
      Branch_Name : UString;

      function Count_Active_Branches return Natural is
         Result : Natural := 0;
      begin
         for Branch of Branches loop
            if Branch.Branch_Status /= Porion.Projects.Models.BUILD_DISABLED then
               Result := Result + 1;
               if Result > 1 then
                  Ada.Strings.Unbounded.Append (Branch_Name, ", ");
               else
                  Ada.Strings.Unbounded.Append (Branch_Name, "(");
               end if;
               Ada.Strings.Unbounded.Append (Branch_Name, Branch.Name);
            end if;
         end loop;
         return Result;
      end Count_Active_Branches;

      Name : constant String := To_String (Ident.Name);
   begin
      Printer.Create_Field (Fields (1), Context.Styles.Default, 20.0);
      Printer.Create_Field (Fields (2), Context.Styles.Success, 80.0);
      Printer.Create_Field (Fields (3), Context.Styles.Default, 20.0);
      for Field of Fields (4 .. 10) loop
         Printer.Create_Field (Field, Context.Styles.Default, 0.0);
      end loop;
      Printer.Set_Bottom_Right_Padding (Fields (4), (1, 0));
      Printer.Set_Bottom_Right_Padding (Fields (5), (1, 0));
      Printer.Set_Bottom_Right_Padding (Fields (6), (1, 0));
      Printer.Set_Bottom_Right_Padding (Fields (7), (1, 0));
      Printer.Set_Bottom_Right_Padding (Fields (8), (1, 0));

      Printer.Layout_Fields (Fields (1 .. 2));
      Printer.Put (Fields (1), -("Project"));
      Printer.Put_UString (Fields (2), Ident.Name);
      Printer.New_Line;

      declare
         Description : constant String := Context.Project_Service.Project.Get_Description;
      begin
         if Description'Length > 0 then
            Printer.Put (Fields (1), -("Description:"));
            Printer.Put (Fields (2), Description);
            Printer.New_Line;
         end if;
      end;

      Query.Set_Query (Porion.Queries.Query_Branch_List);
      Query.Bind_Param ("project_id", Context.Project_Service.Project.Get_Id);
      Porion.Queries.List (Branches, Context.Project_Service.DB, Query);

      Printer.Layout_Fields (Fields (3 .. 9));
      Printer.Put (Fields (3), -("Branches"));
      declare
         C1 : constant Integer := Count_Active_Branches;
         C2 : constant Integer := Integer (Branches.Length) - C1;
      begin
         if Ada.Strings.Unbounded.Length (Branch_Name) > 0 then
            Ada.Strings.Unbounded.Append (Branch_Name, ")");
         end if;
         Printer.Set_Style (Fields (5), Context.Styles.Success);
         Printer.Put_Int (Fields (5), C1);
         Printer.Put_UString (Fields (6), Branch_Name);
         Printer.Set_Style (Fields (8), Context.Styles.Disabled);
         Printer.Put_Int (Fields (8), C2);
         Printer.Put (Fields (9), -("disabled"));
      end;
      Printer.New_Line;

      Query.Clear;
      Query.Set_Query (Porion.Queries.Query_Project_Last_Build_List);
      Query.Bind_Param ("project_id", Context.Project_Service.Project.Get_Id);
      Porion.Queries.List (Last_Builds, Context.Project_Service.DB, Query);

            --  Printer.Set_Max_Dimension (Fields (2), (3, 1));
            --  Printer.Set_Max_Dimension (Fields (4), (3, 1));
            --  Printer.Set_Max_Dimension (Fields (3), Branch_Name);

      Printer.Layout_Fields (Fields (3 .. 4));
      for Branch of Branches loop
         declare
            Branch_Name : constant String := To_String (Branch.Name);
            Build_Dir   : constant String
               := Porion.Configs.Get_Build_Directory (Name, Branch_Name);
         begin
            if Branch.Branch_Status /= Porion.Projects.Models.BUILD_DISABLED then
               Printer.Put (Fields (3), Format (-("Path ({0})"), Branch_Name));
               Printer.Put (Fields (4), Build_Dir);
               Printer.New_Line;
            end if;
         end;
      end loop;

      if not Last_Builds.Is_Empty then
         Printer.New_Line;

         Printer.Put (Fields (3), -("Last builds"));
         Printer.New_Line;
         Printer.Set_Bottom_Right_Padding (Fields (3), (2, 0));
         Printer.Set_Bottom_Right_Padding (Fields (4), (2, 0));
         Printer.Layout_Fields (Fields (3 .. 5));
         for Build of Last_Builds loop
            declare
               Branch_Name  : constant String := To_String (Build.Branch_Name);
               Build_Number : constant Integer := Build.Build_Number;
               Log_Dir      : constant String
                  := Configs.Get_Build_Log_Directory (Name,
                                                      Branch_Name,
                                                      Build_Number);
               Ident        : Porion.Projects.Ident_Type;
            begin
               Ident.Name := To_UString (Name);
               Ident.Branch := Build.Branch_Name;
               Ident.Recipe := Build.Recipe_Name;
               Ident.Node := Build.Node_Name;
               Ident.Build := Build_Number;
               if Build.Build_Status = Builds.Models.BUILD_FAIL then
                  Printer.Set_Style (Fields (4), Context.Styles.Error);
                  Printer.Set_Style (Fields (5), Context.Styles.Error);
                  Printer.Put (Fields (3), Porion.Projects.To_String (Ident) & (-(" (KO)")));
               else
                  Printer.Set_Style (Fields (4), Context.Styles.Success);
                  Printer.Set_Style (Fields (5), Context.Styles.Success);
                  Printer.Put (Fields (3), Porion.Projects.To_String (Ident));
               end if;
               Printer.Put_Int (Fields (4), Build_Number);
               Printer.Put (Fields (5), Log_Dir);
               Printer.New_Line;
            end;
         end loop;
      end if;

      declare
         List   : Porion.Queries.Project_Info_Vector;
         Query  : ADO.Queries.Context;
      begin
         Query.Set_Query (Porion.Queries.Query_Project_Dependency_List);
         Query.Bind_Param ("project_id", Context.Project_Service.Project.Get_Id);
         Porion.Queries.List (List, Context.Project_Service.DB, Query);

         if not List.Is_Empty then
            Printer.New_Line;
            Porion.Reports.List_Projects (List, Printer, Context.Styles, -("Dependencies"));
         end if;
      end;

      if Command.List_Nodes then
         declare
            List   : Porion.Queries.Node_Info_Vector;
            Query  : ADO.Queries.Context;
         begin
            Query.Set_Query (Porion.Queries.Query_Project_Node_List);
            Query.Bind_Param ("project_id", Context.Project_Service.Project.Get_Id);
            Porion.Queries.List (List, Context.Project_Service.DB, Query);

            if not List.Is_Empty then
               Printer.New_Line;
               Porion.Reports.List_Nodes (List, Printer, Context.Styles, -("Nodes"));
            end if;
         end;
      end if;

      if Command.List_Builds and not Last_Builds.Is_Empty then
         Printer.New_Line;
         Porion.Reports.List_Builds (List    => Last_Builds,
                                     Printer => Printer,
                                     Styles  => Context.Styles,
                                     Label   => -("Builds"));
      end if;

      declare
         List   : Porion.Queries.Queue_Info_Vector;
         Query  : ADO.Queries.Context;
      begin
         Query.Set_Query (Porion.Queries.Query_Project_Build_Queue_List);
         Query.Bind_Param ("project_id", Context.Project_Service.Project.Get_Id);
         Porion.Queries.List (List, Context.Project_Service.DB, Query);

         if not List.Is_Empty then
            Printer.New_Line;
            Porion.Reports.List_Queues (List, Printer, Context.Styles, -("Queues"),
                                        Hide_Project => True);
         end if;
      end;

      if Command.List_Recipes then
         Printer.Layout_Fields (Fields (3 .. 3));
         Executor.Enable_Dry_Run;
         Builds.Services.Find_Build_Configs (Context.Project_Service, True, Recipes);
         for Recipe of Recipes loop
            Porion.Builds.Services.Build (Context.Project_Service, Recipe, Executor);
            declare
               Commands : Porion.Executors.Command_Vector;
               Ident    : constant String := Projects.To_String (Context.Project_Service.Ident);
            begin
               Printer.New_Line;
               Executor.Fetch_Commands (Commands);
               Printer.Put (Fields (3), Format (-("Recipe: {0}"), Ident));
               Printer.New_Line;
               Printer.Put (Fields (3), Format (-("Filtering rules: {0}"),
                            Recipe.Get_Filter_Rules));
               Printer.New_Line;

               Porion.Reports.List_Commands (Commands, Context.Printer.all, Context.Styles);
            end;
         end loop;
      end if;
   end Print_Project;

   --  ------------------------------
   --  Report some information about a project.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Error (-("missing project name"));
         return;
      end if;

      if Command.List_All then
         Command.List_Recipes := True;
         Command.List_Nodes := True;
         Command.List_Builds := True;
      end if;

      Context.Open;

      for I in 1 .. Args.Get_Count loop
         declare
            Arg   : constant String := Args.Get_Argument (I);
            Ident : Porion.Projects.Ident_Type;
         begin
            Ident := Porion.Projects.Parse (Arg);
            Context.Project_Service.Load (Ident);

            if Ident.Build > 0 then
               Command.Print_Build (Ident, Context);
            else
               Command.Print_Project (Ident, Context);
            end if;

         exception
            when Porion.Services.Not_Found =>
               Context.Error_Not_Found (Ident);

            when Porion.Projects.Invalid_Ident =>
               Commands.Error (-("invalid project or build identifier: {0}"), Arg);

         end;
      end loop;
   end Execute;

   --  ------------------------------
   --  Setup the command before parsing the arguments and executing it.
   --  ------------------------------
   overriding
   procedure Setup (Command : in out Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Context_Type) is
   begin
      Drivers.Command_Type (Command).Setup (Config, Context);
      GC.Define_Switch (Config => Config,
                        Output => Command.List_All'Access,
                        Switch => "-a",
                        Long_Switch => "--all",
                        Help => -("Report all information"));
      GC.Define_Switch (Config => Config,
                        Output => Command.List_Recipes'Access,
                        Switch => "-r",
                        Long_Switch => "--recipes",
                        Help => -("List the recipes of the project"));
      GC.Define_Switch (Config => Config,
                        Output => Command.List_Nodes'Access,
                        Switch => "-n",
                        Long_Switch => "--nodes",
                        Help => -("List the build nodes used by the project"));
      GC.Define_Switch (Config => Config,
                        Output => Command.List_Builds'Access,
                        Switch => "-b",
                        Long_Switch => "--builds",
                        Help => -("List the builds of the project"));
   end Setup;

end Porion.Commands.Info;
