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
with ADO.Queries;
with PT.Texts;
with PT.Colors;
with PT.Drivers.Texts;
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

      Driver  : PT.Drivers.Texts.Printer_Type := PT.Drivers.Texts.Create (Width => 80);
      Printer : PT.Texts.Printer_Type := PT.Texts.Create (Driver);
      Black   : PT.Style_Type;
      Green   : PT.Style_Type;
      Red     : PT.Style_Type;
      Label   : PT.Texts.Field_Type;
      Info    : PT.Texts.Field_Type;
      Count   : PT.Texts.Field_Type;
      Info2   : PT.Texts.Field_Type;
      Count2  : PT.Texts.Field_Type;
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Error (-("missing project name"));
         return;
      end if;
      Context.Open;

      Driver.Create_Style (PT.Colors.White, Black);
      Driver.Create_Style (PT.Colors.Green, Green);
      Driver.Create_Style (PT.Colors.Red, Red);
      Printer.Create_Field (Label, Black, 20.0);
      Printer.Create_Field (Info, Green, 80.0);
      Printer.Create_Field (Count, Green, 10.0);
      Printer.Create_Field (Info2, Black, 60.0);
      Printer.Create_Field (Count2, Red, 10.0);

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
                     end if;
                     Ada.Strings.Unbounded.Append (Branch_Name, Branch.Name);
                  end if;
               end loop;
               return Result;
            end Count_Active_Branches;
         begin
            Context.Project_Service.Load_Project (Project_Name);

            Printer.Put (Label, -("Name:"));
            Printer.Put (Info, Project_Name);
            Printer.New_Line;

            Printer.Put (Label, -("Description:"));
            Printer.Put (Info, Context.Project_Service.Project.Get_Description);
            Printer.New_Line;

            Query.Set_Query (Porion.Queries.Query_Branch_List);
            Query.Bind_Param ("project_id", Context.Project_Service.Project.Get_Id);
            Porion.Queries.List (Branches, Context.Project_Service.DB, Query);

            Printer.Put (Label, -("Branches"));
            declare
               C1 : constant Integer := Count_Active_Branches;
               C2 : constant Integer := Integer (Branches.Length) - C1;
            begin
               Printer.Put_Int (Count, C1);
               Printer.Put_UString (Info2, Branch_Name);
               Printer.Put_Int (Count2, C2);
               Printer.Put (Black, -("disabled"));
            end;
            Printer.New_Line;

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
