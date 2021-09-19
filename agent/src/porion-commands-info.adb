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
with ADO.Queries;
with PT.Texts;
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
         begin
            Context.Project_Service.Load_Project (Project_Name);

            Printer.Layout_Fields (Fields (1 .. 2));
            Printer.Put (Fields (1), -("Name:"));
            Printer.Put (Fields (2), Project_Name);
            Printer.New_Line;

            Printer.Put (Fields (1), -("Description:"));
            Printer.Put (Fields (2), Context.Project_Service.Project.Get_Description);
            Printer.New_Line;

            Query.Set_Query (Porion.Queries.Query_Branch_List);
            Query.Bind_Param ("project_id", Context.Project_Service.Project.Get_Id);
            Porion.Queries.List (Branches, Context.Project_Service.DB, Query);

            --  Printer.Set_Max_Dimension (Fields (2), 3);
            --  Printer.Set_Max_Dimension (Fields (4), 3);
            --  Printer.Set_Max_Dimension (Fields (3), Branch_Name);

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
            Query.Set_Join ("INNER JOIN porion_branch AS b ON o.branch_id = b.id");
            Query.Set_Filter ("b.project_id = :project_id");
            Query.Bind_Param ("project_id", Context.Project_Service.Project.Get_Id);
            Porion.Builds.Models.List (Last_Builds, Context.Project_Service.DB, Query);

            Porion.Reports.List_Builds (Service => Context.Project_Service,
                                        Printer => Printer,
                                        Styles  => Context.Styles);

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
