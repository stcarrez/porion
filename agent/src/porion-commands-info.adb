-----------------------------------------------------------------------
--  porion-commands-info -- Info command
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
with Porion.Projects.Services;
with Porion.Projects.Models;
with Porion.Services;
with Porion.Queries;
with Porion.Builds.Models;
with Porion.Reports;
with Porion.Executors;
with Porion.Configs;
with ADO.Queries;
with PT.Texts;
with Porion.Builds.Services;
package body Porion.Commands.Info is

   --  ------------------------------
   --  Report some information about a project.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);

      Printer : PT.Texts.Printer_Type := PT.Texts.Create (Context.Printer.all);
      Fields  : PT.Texts.Field_Array (1 .. 10);
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Error (-("missing project name"));
         return;
      end if;
      Context.Open;

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

      for I in 1 .. Args.Get_Count loop
         declare
            use type Porion.Projects.Models.Branch_Status_Type;

            function Count_Active_Branches return Natural;

            Project_Name : constant String := Args.Get_Argument (I);
            Branches     : Porion.Queries.Branch_Info_Vector;
            Query        : ADO.Queries.Context;
            Branch_Name  : UString;

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

            Last_Builds : Porion.Builds.Models.Last_Build_Vector;
            Executor    : Porion.Executors.Executor_Type;
            Recipes     : Porion.Builds.Models.Recipe_Vector;
         begin
            Context.Project_Service.Load_Project (Project_Name);

            Printer.Layout_Fields (Fields (1 .. 2));
            Printer.Put (Fields (1), -("Project"));
            Printer.Put (Fields (2), Project_Name);
            Printer.New_Line;

            Printer.Put (Fields (1), -("Description:"));
            Printer.Put (Fields (2), Context.Project_Service.Project.Get_Description);
            Printer.New_Line;

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

            --  Printer.Set_Max_Dimension (Fields (2), (3, 1));
            --  Printer.Set_Max_Dimension (Fields (4), (3, 1));
            -- Printer.Set_Max_Dimension (Fields (3), Branch_Name);

            Printer.Layout_Fields (Fields (3 .. 4));
            for Branch of Branches loop
               declare
                  Branch_Name : constant String := To_String (Branch.Name);
                  Build_Dir   : constant String
                    := Porion.Configs.Get_Build_Directory (Project_Name, Branch_Name);
                  Log_Dir : constant String
                    := Porion.Configs.Get_Build_Log_Directory (Project_NAme, Branch_Name, 3);
               begin
                  if Branch.Branch_Status /= Porion.Projects.Models.BUILD_DISABLED then
                     Printer.Put (Fields (3), Format (-("Path ({0})"), Branch_Name));
                     Printer.Put (Fields (4), Build_Dir);
                     Printer.New_Line;

                     Printer.Put (Fields (3), Format (-("Logs ({0})"), Branch_Name));
                     Printer.Put (Fields (4), Log_Dir);
                     Printer.New_Line;

                  end if;
               end;
            end loop;

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

            Query.Clear;
            Query.Set_Join ("INNER JOIN porion_branch AS b ON o.branch_id = b.id");
            Query.Set_Filter ("b.project_id = :project_id");
            Query.Bind_Param ("project_id", Context.Project_Service.Project.Get_Id);
            Porion.Builds.Models.List (Last_Builds, Context.Project_Service.DB, Query);
            declare
               List   : Porion.Queries.Build_Info_Vector;
               Query  : ADO.Queries.Context;
            begin
               Query.Set_Query (Porion.Queries.Query_Project_Last_Build_List);
               Query.Bind_Param ("project_id", Context.Project_Service.Project.Get_Id);
               Porion.Queries.List (List, Context.Project_Service.DB, Query);

               if not List.Is_Empty then
                  Printer.New_Line;
                  Porion.Reports.List_Builds (List    => List,
                                              Printer => Printer,
                                              Styles  => Context.Styles,
                                              Label   => -("Builds"));
               end if;
            end;

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

            Printer.Layout_Fields (Fields (3 .. 3));
            Executor.Enable_Dry_Run;
            Builds.Services.Find_Build_Configs (Context.Project_Service, True, Recipes);
            for Recipe of Recipes loop
               Porion.Builds.Services.Build (Context.Project_Service, Recipe, Executor);
               declare
                  Commands    : Porion.Executors.Command_Vector;
                  Branch_Name : constant String := Context.Project_Service.Branch.Get_Name;
                  Hostname    : constant String := Context.Project_Service.Build_Node.Get_Name;
               begin
                  Printer.New_Line;
                  Executor.Fetch_Commands (Commands);
                  Printer.Put (Fields (3), Format ("Recipe: {0}@{1}", Branch_Name, Hostname));
                  Printer.New_Line;
                  Porion.Reports.List_Commands (Commands, Context.Printer.all, Context.Styles);
               end;
            end loop;

         exception
            when Porion.Services.Not_Found =>
               Porion.Commands.Error (-("project '{0}' not found"),
                                         Project_Name);

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
   end Setup;

end Porion.Commands.Info;
