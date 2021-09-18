-----------------------------------------------------------------------
--  porion-commands-list -- List command
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
with ANSI;
with Ada.Calendar.Formatting;
with Ada.Calendar.Time_Zones;
with Ada.Text_IO;
with Util.Strings;
with Util.Dates.ISO8601;
with ADO.Queries;
with ADO.Statements;
with Porion.Queries;
with Porion.Builds.Models;
with Porion.Projects.Models;
package body Porion.Commands.List is

   procedure List (Command : in out Command_Type;
                   Context : in out Context_Type;
                   Query   : in ADO.Queries.Context;
                   Prefix  : in String);

   procedure List_Projects (Command : in out Command_Type;
                            Context : in out Context_Type);

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

   --  Report the list of projects, nodes or builds.
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name, Args);

      Query       : ADO.Queries.Context;
   begin
      Context.Open;

      if not Command.List_Projects and not Command.List_Nodes and not Command.List_Builds then
         Command.List_Projects := True;
      end if;

      if Command.List_Projects then
         Query.Set_Query (Porion.Queries.Query_Project_List);
         List_Projects (Command, Context);
      end if;

      if Command.List_Nodes then
         Query.Set_Query (Porion.Projects.Models.Query_Command_Node_List);
         List (Command, Context, Query, "command_node_list_");
      end if;

      if Command.List_Builds then
         Query.Set_Query (Porion.Queries.Query_Command_Build_List);
         List (Command, Context, Query, "command_build_list_");
      end if;
   end Execute;

   procedure List_Projects (Command : in out Command_Type;
                            Context : in out Context_Type) is
      use Porion.Builds.Models;
      use Porion.Projects.Models;

      function Get_Tag (Info : in Porion.Queries.Project_Info) return String is
         Tag : constant String := To_String (Info.Branch_Tag);
      begin
         if Tag'Length > 8 then
            return Tag (Tag'First .. Tag'First + 7);
         else
            return Tag;
         end if;
      end Get_Tag;

      List  : Porion.Queries.Project_Info_Vector;
      Query : ADO.Queries.Context;
   begin
      Query.Set_Query (Porion.Queries.Query_Project_List);
      Porion.Queries.List (List, Context.Project_Service.DB, Query);

      Context.Console.Start_Title;
      Context.Console.Print_Title (1, "Name", 20);
      Context.Console.Print_Title (2, "Branch", 20);
      Context.Console.Print_Title (3, "Tag", 8);
      Context.Console.Print_Title (4, "Status", 7);
      Context.Console.Print_Title (5, " Pass", 6);
      Context.Console.Print_Title (6, " Fail", 6);
      Context.Console.Print_Title (7, "Date", 18);
      Context.Console.End_Title;

      for Project of List loop
         Context.Console.Start_Row;
         if Project.Project_Status /= Projects.Models.PROJECT_ACTIVE then
            Ada.Text_IO.Put (ANSI.Foreground (ANSI.Blue));
         elsif Project.Build_Date.Is_Null then
            Ada.Text_IO.Put (ANSI.Foreground (ANSI.Blue));
         elsif Project.Build_Status = Builds.Models.BUILD_PASS then
            Ada.Text_IO.Put (ANSI.Foreground (ANSI.Green));
         else
            Ada.Text_IO.Put (ANSI.Foreground (ANSI.Red));
         end if;
         Context.Console.Print_Field (1, To_String (Project.Name));
         Context.Console.Print_Field (2, To_String (Project.Branch_Name));
         Context.Console.Print_Field (3, Get_Tag (Project), Consoles.J_LEFT);
         if not Project.Build_Date.Is_Null then
            if Project.Build_Status = Builds.Models.BUILD_PASS then
               Context.Console.Print_Field (4, "OK", Consoles.J_RIGHT);
            else
               Context.Console.Print_Field (4, "KO", Consoles.J_RIGHT);
            end if;
            Context.Console.Print_Field (5, Util.Strings.Image (Project.Pass_Count), Consoles.J_RIGHT);
            Context.Console.Print_Field (6, Util.Strings.Image (Project.Fail_Count), Consoles.J_RIGHT);
            Context.Console.Print_Field (7, Format (Project.Build_Date.Value), Consoles.J_RIGHT);
         end if;
         Ada.Text_IO.Put (ANSI.Reset);
         Context.Console.End_Row;
      end loop;
   end List_Projects;

   procedure List (Command : in out Command_Type;
                   Context : in out Context_Type;
                   Query   : in ADO.Queries.Context;
                   Prefix  : in String) is
      function Get_Label (Name : in String) return String;

      function Get_Label (Name : in String) return String is
         Result : constant String := Command.Bundle.Get (Prefix & Name, Name);
      begin
         if Util.Strings.Index (Result, ':') > 0 then
            return Result;
         else
            return Result & ":10";
         end if;
      end Get_Label;

      Statement   : ADO.Statements.Query_Statement;
      Print_Names : Boolean := True;
   begin
      Statement := Context.Project_Service.Create_Query (Query);
      Statement.Execute;
      while Statement.Has_Elements loop
         if Print_Names then
            Context.Console.Start_Title;
            for I in 1 .. Statement.Get_Column_Count loop
               declare
                  Info : constant String := Get_Label (Statement.Get_Column_Name (I - 1));
                  Pos  : constant Natural := Util.Strings.Index (Info, ':');
               begin
                  Context.Console.Print_Title (Field_Number (I),
                                               Info (Info'First .. Pos - 1),
                                               Natural'Value (Info (Pos + 1 .. Info'Last)));
               end;
            end loop;
            Context.Console.End_Title;
            Print_Names := False;
         end if;
         Context.Console.Start_Row;
         for I in 1 .. Statement.Get_Column_Count loop
            if not Statement.Is_Null (I - 1) then
               Context.Console.Print_Field (Field_Number (I),
                                            Statement.Get_String (I - 1));
            end if;
         end loop;
         Context.Console.End_Row;
         Statement.Next;
      end loop;
   end List;

   --  Setup the command before parsing the arguments and executing it.
   overriding
   procedure Setup (Command : in out Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Context_Type) is
   begin
      Drivers.Command_Type (Command).Setup (Config, Context);
      GC.Define_Switch (Config => Config,
                        Output => Command.List_Projects'Access,
                        Switch => "-p",
                        Long_Switch => "--projects",
                        Help => -("List the projects"));
      GC.Define_Switch (Config => Config,
                        Output => Command.List_Nodes'Access,
                        Switch => "-n",
                        Long_Switch => "--nodes",
                        Help => -("List the build nodes"));
      GC.Define_Switch (Config => Config,
                        Output => Command.List_Builds'Access,
                        Switch => "-b",
                        Long_Switch => "--builds",
                        Help => -("List the builds"));
   end Setup;

end Porion.Commands.List;
