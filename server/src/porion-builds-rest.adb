-----------------------------------------------------------------------
--  porion-builds-beans -- Beans for module builds
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
with Ada.Directories;
with ADO.Queries;
with Util.Strings;
with Util.Log.Loggers;
with AWA.Services.Contexts;
with Porion.Logs.Analysis;
with Porion.Projects;
with Porion.Queries;
with Porion.Metrics;
with Porion.Nodes.Services;
with Porion.Builds.Models;
with Porion.Builds.Services;
package body Porion.Builds.Rest is

   package ASC renames AWA.Services.Contexts;

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builds.Rest");

   use type Porion.Builds.Models.Build_Status_Type;
   use type ADO.Identifier;

   type Badge_Info is record
      Label   : UString;
      Message : UString;
      Color   : UString;
   end record;

   procedure Get_Build_Badge (Context : in out Porion.Services.Context_Type;
                              Badge   : in out Badge_Info);

   procedure Get_Tests_Badge (Context : in out Porion.Services.Context_Type;
                              Badge   : in out Badge_Info);

   procedure Get_Coverage_Badge (Context : in out Porion.Services.Context_Type;
                                 Badge   : in out Badge_Info);

   procedure Get_Build_Log
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type) is
      pragma Unreferenced (Req, Reply);

      use Porion.Logs.Analysis;
      procedure Finish_Log_Stats;

      Rules  : constant String := Context.Recipe.Get_Filter_Rules;
      Ctx    : Porion.Logs.Analysis.Analyser_Type;
      Levels : Porion.Logs.Analysis.Level_Map;
      List   : Porion.Logs.Analysis.Line_Vector;
      Dir    : constant String := Builds.Services.Get_Log_Directory (Context);
      Path   : constant String := Ada.Directories.Compose (Dir, "build.log");
      Step   : ADO.Identifier := ADO.NO_IDENTIFIER;
      Has_Log     : Boolean := False;
      Trace_Count : Natural := 0;
      Debug_Count : Natural := 0;
      Info_Count  : Natural := 0;
      Warn_Count  : Natural := 0;
      Error_Count : Natural := 0;
      Fatal_Count : Natural := 0;
      Unknown_Count : Natural := 0;
      Context_Count : Natural := 0;

      procedure Finish_Log_Stats is
      begin
         Stream.End_Array ("logs");
         Stream.Start_Entity ("counts");
         Stream.Write_Attribute ("trace", Trace_Count);
         Stream.Write_Attribute ("debug", Debug_Count);
         Stream.Write_Attribute ("info", Info_Count);
         Stream.Write_Attribute ("warning", Warn_Count);
         Stream.Write_Attribute ("error", Error_Count);
         Stream.Write_Attribute ("fatal", Fatal_Count);
         Stream.Write_Attribute ("unkown", Unknown_Count);
         Stream.Write_Attribute ("context", Context_Count);
         Stream.End_Entity ("counts");
         Stream.End_Entity ("log_step");
      end Finish_Log_Stats;
   begin
      if not Porion.Projects.Has_Build (Context.Ident) then
         raise Porion.Services.Not_Found;
      end if;

      Levels := (others => True);
      Porion.Logs.Analysis.Set_Rules (Ctx, Rules);
      Porion.Logs.Analysis.Set_Filter (Ctx, Levels);
      Porion.Logs.Analysis.Read (Ctx, Path, List);
      Stream.Start_Array ("");
      for Line of List loop
         if Step /= Line.Step or else not Has_Log then
            if Has_Log then
               Finish_Log_Stats;
            else
               Has_Log := True;
            end if;
            Trace_Count := 0;
            Debug_Count := 0;
            Info_Count := 0;
            Warn_Count := 0;
            Error_Count := 0;
            Fatal_Count := 0;
            Unknown_Count := 0;
            Context_Count := 0;
            Stream.Start_Entity ("log_step");
            Stream.Write_Long_Entity ("step", Long_Long_Integer (Line.Step));
            Stream.Start_Array ("logs");
            Step := Line.Step;
         end if;
         Stream.Start_Entity ("log");
         Stream.Write_Attribute ("number", Line.Number);
         case Line.Level is
            when LOG_UNKNOWN =>
               Stream.Write_Attribute ("level", "unknown");
               Unknown_Count := Unknown_Count + 1;

            when LOG_PORION =>
               Stream.Write_Attribute ("level", "porion");

            when LOG_FATAL =>
               Stream.Write_Attribute ("level", "fatal");
               Fatal_Count := Fatal_Count + 1;

            when LOG_ERROR =>
               Stream.Write_Attribute ("level", "error");
               Error_Count := Error_Count + 1;

            when LOG_WARNING =>
               Stream.Write_Attribute ("level", "warning");
               Warn_Count := Warn_Count + 1;

            when LOG_CONTEXT =>
               Stream.Write_Attribute ("level", "context");
               Context_Count := Context_Count + 1;

            when LOG_INFO =>
               Stream.Write_Attribute ("level", "info");
               Info_Count := Info_Count + 1;

            when LOG_TRACE =>
               Stream.Write_Attribute ("level", "trace");
               Trace_Count := Trace_Count + 1;

            when LOG_DEBUG =>
               Stream.Write_Attribute ("level", "debug");
               Debug_Count := Debug_Count + 1;

         end case;
         Stream.Write_Entity ("content", Line.Content);
         Stream.End_Entity ("log");
      end loop;
      if Has_Log then
         Finish_Log_Stats;
      end if;
      Stream.End_Array ("");

   exception
      when E : others =>
         Log.Error ("Exception", E, True);
         raise;

   end Get_Build_Log;

   procedure Get_Build_Tests
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type) is
      pragma Unreferenced (Reply);

      Query     : ADO.Queries.Context;
      List      : Porion.Queries.Test_Info_Vector;
      Current_Group : ADO.Identifier := ADO.NO_IDENTIFIER;
   begin
      if not Porion.Projects.Has_Build (Context.Ident) then
         raise Porion.Services.Not_Found;
      end if;

      Query.Set_Query (Porion.Queries.Query_Build_Test_List);
      Query.Bind_Param ("build_id", Context.Build.Get_Id);
      Porion.Queries.List (List, Context.DB, Query);
      Stream.Start_Document;
      Stream.Start_Array ("");
      for Test_Info of List loop
         if Current_Group /= Test_Info.Id then
            if Current_Group /= ADO.NO_IDENTIFIER then
               Stream.End_Array ("tests");
               Stream.End_Entity ("group");
            end if;
            Current_Group := Test_Info.Id;
            Stream.Start_Entity ("group");
            Stream.Write_Attribute ("name", Test_Info.Group_Name);
            Stream.Start_Array ("tests");
         end if;
         Stream.Start_Entity ("test");
         Stream.Write_Attribute ("name", Test_Info.Test_Name);
         Stream.Write_Attribute ("total_pass", Test_Info.Test_Pass_Count);
         Stream.Write_Attribute ("total_fail", Test_Info.Test_Fail_Count);
         Stream.Write_Attribute ("total_timeout", Test_Info.Test_Timeout_Count);
         Stream.Write_Attribute ("status", Test_Info.Test_Status'Image);
         Stream.Write_Attribute ("duration", Natural (Test_Info.Test_Duration));
         Stream.End_Entity ("test");
      end loop;
      if Current_Group /= ADO.NO_IDENTIFIER then
         Stream.End_Array ("tests");
         Stream.End_Entity ("group");
      end if;
      Stream.End_Array ("");
      Stream.End_Document;
   end Get_Build_Tests;

   procedure Jenkins_Get_Last_Completed_Build
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type) is
      pragma Unreferenced (Req, Reply, Context);
   begin
      Stream.Start_Document;
      Stream.Start_Entity ("");
      Stream.Write_Entity ("color", "blue");
      Stream.End_Entity ("");
      Stream.End_Document;
   end Jenkins_Get_Last_Completed_Build;

   procedure Get_Build_Badge (Context : in out Porion.Services.Context_Type;
                              Badge   : in out Badge_Info) is
      Query     : ADO.Queries.Context;
      List      : Porion.Queries.Build_Stat_List_Bean;
      Has_Fail  : Boolean := False;
      Has_Pass  : Boolean := False;
      Has_Error : Boolean := False;
   begin
      Badge.Label := To_UString ("build");
      Query.Set_Query (Porion.Queries.Query_Stat_Project_Builds);
      Query.Bind_Param ("project_id", Context.Project.Get_Id);
      Porion.Queries.List (List, Context.DB, Query);
      for Stat of List.List loop
         if Stat.Build_Status = Porion.Builds.Models.BUILD_RUNNING then
            Badge.Message := To_UString ("building");
            Badge.Color := To_UString ("yellow");
            return;
         end if;
         if Stat.Build_Status = Porion.Builds.Models.BUILD_FAIL then
            Has_Fail := True;
         else
            Has_Pass := True;
         end if;
         if Stat.Fail_Count > 0 or Stat.Timeout_Count > 0 then
            Has_Error := True;
         end if;
      end loop;

      if Has_Pass and not Has_Fail and not Has_Error then
         Badge.Message := To_UString ("passing");
         Badge.Color := To_UString ("green");
      elsif Has_Pass and Has_Error then
         Badge.Message := To_UString ("unstable");
         Badge.Color := To_UString ("orange");
      elsif Has_Fail then
         Badge.Message := To_UString ("failed");
         Badge.Color := To_UString ("red");
      else
         Badge.Message := To_UString ("none");
         Badge.Color := To_UString ("blue");
      end if;
   end Get_Build_Badge;

   procedure Get_Tests_Badge (Context : in out Porion.Services.Context_Type;
                              Badge   : in out Badge_Info) is
      Query       : ADO.Queries.Context;
      List        : Porion.Queries.Build_Stat_List_Bean;
      Total_Count : Natural := 0;
      Pass_Count  : Natural := 0;
      Fail_Count  : Natural := 0;
   begin
      Badge.Label := To_UString ("build");
      Query.Set_Query (Porion.Queries.Query_Stat_Project_Builds);
      Query.Bind_Param ("project_id", Context.Project.Get_Id);
      Porion.Queries.List (List, Context.DB, Query);
      for Stat of List.List loop
         Total_Count := Total_Count + Stat.Count;
         Pass_Count := Pass_Count + Stat.Pass_Count;
         Fail_Count := Fail_Count + Stat.Fail_Count;
         Fail_Count := Fail_Count + Stat.Timeout_Count;
      end loop;
      Badge.Label := To_UString ("tests");
      if Pass_Count > 0 and Fail_Count = 0 then
         Badge.Message := To_UString (Util.Strings.Image (Pass_Count) & " passed");
         Badge.Color := To_UString ("green");
      elsif Pass_Count > 0 and Fail_Count > 0 then
         Badge.Message := To_UString (Util.Strings.Image (Pass_Count) & " passed, "
                                      & Util.Strings.Image (Fail_Count) & " failed");
         Badge.Color := To_UString ("orange");
      elsif Fail_Count > 0 then
         Badge.Message := To_UString (Util.Strings.Image (Fail_Count) & " failed");
         Badge.Color := To_UString ("red");
      else
         Badge.Message := To_UString ("no test");
         Badge.Color := To_UString ("red");
      end if;
   end Get_Tests_Badge;

   procedure Get_Coverage_Badge (Context : in out Porion.Services.Context_Type;
                                 Badge   : in out Badge_Info) is
      Query       : ADO.Queries.Context;
      List        : Porion.Queries.Metric_Stat_List_Bean;
      Coverage    : Natural := 0;
      Metric      : constant Natural
         := Porion.Metrics.Metric_Type'Enum_Rep (Porion.Metrics.METRIC_COVERAGE);
   begin
      Badge.Label := To_UString ("coverage");
      Query.Set_Query (Porion.Queries.Query_Stat_Project_With_Metric);
      Query.Bind_Param ("project_id", Context.Project.Get_Id);
      Query.Bind_Param ("metric", Metric);
      Porion.Queries.List (List, Context.DB, Query);
      for Stat of List.List loop
         case Stat.Kind is
            when Porion.Metrics.METRIC_COVERAGE =>
               if Stat.Name = "lines" then
                  if Stat.Count > 0 then
                     Coverage := Natural (Stat.Sum_Value / Stat.Count);
                  end if;
               end if;

            when others =>
               null;

         end case;
      end loop;
      if Coverage > 0 then
         Badge.Message := To_UString (Util.Strings.Image (Coverage / 10));
         if Coverage > 900 then
            Badge.Color := To_UString ("green");
         elsif Coverage > 800 then
            Badge.Color := To_UString ("yellow");
         elsif Coverage > 700 then
            Badge.Color := To_UString ("orange");
         else
            Badge.Color := To_UString ("red");
         end if;
      else
         Badge.Message := To_UString ("none");
         Badge.Color := To_UString ("blue");
      end if;
   end Get_Coverage_Badge;

   procedure Get_Project_Schields_Status
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type) is
      pragma Unreferenced (Reply);

      Mode  : constant String := Req.Get_Path_Parameter (2);
      Badge : Badge_Info;
   begin
      if Mode = "build.json" then
         Get_Build_Badge (Context, Badge);
      elsif Mode = "tests.json" then
         Get_Tests_Badge (Context, Badge);
      elsif Mode = "coverage.json" then
         Get_Coverage_Badge (Context, Badge);
      else
         raise Porion.Services.Not_Found;
      end if;

      if Length (Badge.Label) = 0 or Length (Badge.Message) = 0 then
         raise Porion.Services.Not_Found;
      end if;

      Stream.Start_Document;
      Stream.Start_Entity ("");
      Stream.Write_Entity ("schemaVersion", 1);
      Stream.Write_Entity ("label", Badge.Label);
      Stream.Write_Entity ("message", Badge.Message);
      Stream.Write_Entity ("color", Badge.Color);
      Stream.End_Entity ("");
      Stream.End_Document;
   end Get_Project_Schields_Status;

   procedure Get_Project_Tests_Builds
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type) is
      pragma Unreferenced (Req, Reply);

      Query   : ADO.Queries.Context;
      List    : Porion.Queries.Build_Test_Info_Vector;
   begin
      Query.Bind_Param ("project_id", Context.Project.Get_Id);
      Query.Set_Query (Porion.Queries.Query_Stat_Tests);
      Porion.Queries.List (List, Context.DB, Query);

      Stream.Start_Document;
      Stream.Start_Entity ("");
      Stream.Write_Long_Entity ("project_id", Long_Long_Integer (Context.Project.Get_Id));
      Stream.Start_Array ("tests");
      for Test_Info of List loop
         Stream.Start_Entity ("test");
         Stream.Write_Long_Entity ("build_id", Long_Long_Integer (Test_Info.Build_Id));
         Stream.Write_Entity ("build_number", Test_Info.Build_Number);
         Stream.Write_Entity ("build_date", Test_Info.Build_Date);
         Stream.Write_Entity ("build_status", Test_Info.Build_Status'Image);
         Stream.Write_Entity ("pass_count", Test_Info.Pass_Count);
         Stream.Write_Entity ("fail_count", Test_Info.Fail_Count);
         Stream.Write_Entity ("timeout_count", Test_Info.Timeout_Count);
         Stream.Write_Entity ("test_duration", Test_Info.Test_Duration);
         Stream.End_Entity ("test");
      end loop;
      Stream.End_Array ("tests");
      Stream.End_Entity ("");
      Stream.End_Document;
   end Get_Project_Tests_Builds;

   procedure Get_Project_Tests
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type) is
      pragma Unreferenced (Req, Reply);

      Query         : ADO.Queries.Context;
      List          : Porion.Queries.Test_Info_Vector;
      Current_Group : ADO.Identifier := ADO.NO_IDENTIFIER;
   begin
      Query.Bind_Param ("project_id", Context.Project.Get_Id);
      Query.Set_Query (Porion.Queries.Query_Project_Test_List);
      Porion.Queries.List (List, Context.DB, Query);

      Stream.Start_Document;
      Stream.Start_Array ("");
      for Test_Info of List loop
         if Current_Group /= Test_Info.Id then
            if Current_Group /= ADO.NO_IDENTIFIER then
               Stream.End_Array ("tests");
               Stream.End_Entity ("group");
            end if;
            Current_Group := Test_Info.Id;
            Stream.Start_Entity ("group");
            Stream.Write_Attribute ("name", Test_Info.Group_Name);
            Stream.Start_Array ("tests");
         end if;
         Stream.Start_Entity ("test");
         Stream.Write_Attribute ("name", Test_Info.Test_Name);
         Stream.Write_Attribute ("total_pass", Test_Info.Test_Pass_Count);
         Stream.Write_Attribute ("total_fail", Test_Info.Test_Fail_Count);
         Stream.Write_Attribute ("total_timeout", Test_Info.Test_Timeout_Count);
         Stream.Write_Attribute ("total_skipped", Test_Info.Test_Skip_Count);
         if Test_Info.Last_Pass_Build > 0 then
            Stream.Write_Attribute ("last_pass_build", Test_Info.Last_Pass_Build);
         else
            Stream.Write_Null_Attribute ("last_pass_build");
         end if;
         if Test_Info.Last_Fail_Build > 0 then
            Stream.Write_Attribute ("last_fail_build", Test_Info.Last_Fail_Build);
         else
            Stream.Write_Null_Attribute ("last_fail_build");
         end if;
         if Test_Info.Last_Timeout_Build > 0 then
            Stream.Write_Attribute ("last_timeout_build", Test_Info.Last_Timeout_Build);
         else
            Stream.Write_Null_Attribute ("last_timeout_build");
         end if;
         if Test_Info.Last_Skip_Build > 0 then
            Stream.Write_Attribute ("last_skip_build", Test_Info.Last_Skip_Build);
         else
            Stream.Write_Null_Attribute ("last_skip_build");
         end if;
         Stream.Write_Attribute ("status", Test_Info.Test_Status'Image);
         Stream.Write_Attribute ("duration", Natural (Test_Info.Test_Duration));
         Stream.End_Entity ("test");
      end loop;
      if Current_Group /= ADO.NO_IDENTIFIER then
         Stream.End_Array ("tests");
         Stream.End_Entity ("group");
      end if;
      Stream.End_Array ("");
      Stream.End_Document;
   end Get_Project_Tests;

   procedure Get_Project_Coverage
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type) is
      pragma Unreferenced (Req, Reply);

      Query   : ADO.Queries.Context;
      List    : Porion.Queries.Build_Metric_Info_Vector;
      Current : Integer := -1;
   begin
      Query.Bind_Param ("project_id", Context.Project.Get_Id);
      Query.Bind_Param ("metric",
                        Integer (Metrics.Metric_Type'Enum_Rep (Metrics.METRIC_COVERAGE)));
      Query.Set_Query (Porion.Queries.Query_Report_Build_Metrics);
      Porion.Queries.List (List, Context.DB, Query);

      Stream.Start_Document;
      Stream.Start_Entity ("");
      Stream.Write_Long_Entity ("project_id", Long_Long_Integer (Context.Project.Get_Id));
      Stream.Start_Array ("metrics");
      for Metric_Info of List loop
         if Metric_Info.Build_Number /= Current then
            if Current > 0 then
               Stream.End_Entity ("coverage");
            end if;
            Current := Metric_Info.Build_Number;
            Stream.Start_Entity ("coverage");
            Stream.Write_Long_Entity ("build_id", Long_Long_Integer (Metric_Info.Build_Id));
            Stream.Write_Entity ("build_number", Current);
            Stream.Write_Entity ("build_date", Metric_Info.Build_Date);
            Stream.Write_Entity ("build_status", Metric_Info.Build_Status'Image);
         end if;
         if Metric_Info.Metric = "lines" then
            Stream.Write_Entity ("lines", Metric_Info.Value);
         elsif Metric_Info.Metric = "functions" then
            Stream.Write_Entity ("functions", Metric_Info.Value);
         end if;
      end loop;
      if Current > 0 then
         Stream.End_Entity ("coverage");
      end if;
      Stream.End_Array ("metrics");
      Stream.End_Entity ("");
      Stream.End_Document;
   end Get_Project_Coverage;

   procedure Get_Node_Usage
     (Req     : in out OpenAPI.Servers.Request'Class;
      Reply   : in out OpenAPI.Servers.Response'Class;
      Stream  : in out OpenAPI.Servers.Output_Stream'Class) is
      API_Ctx   : OpenAPI.Servers.Context_Type;
      Ctx       : constant ASC.Service_Context_Access := ASC.Current;
      Prj_Ctx   : Porion.Services.Context_Type;
      Query     : ADO.Queries.Context;
      List      : Porion.Queries.Node_Stat_Vector;
      Node_Name : constant String := Req.Get_Path_Parameter (1);
   begin
      API_Ctx.Initialize (Req, Reply, Stream);
      Prj_Ctx.DB := ASC.Get_Master_Session (Ctx);
      Porion.Nodes.Services.Load_Node (Prj_Ctx, Node_Name);

      Query.Bind_Param ("node_id", Prj_Ctx.Build_Node.Get_Id);
      Query.Set_Query (Porion.Queries.Query_Stat_Nodes);
      Porion.Queries.List (List, Prj_Ctx.DB, Query);

      Stream.Start_Document;
      Stream.Start_Array ("");
      for Node_Info of List loop
         Stream.Start_Entity ("node");
         Stream.Write_Entity ("date", Node_Info.Day);
         Stream.Write_Entity ("build_status", Node_Info.Build_Status'Image);
         Stream.Write_Entity ("count", Node_Info.Count);
         Stream.Write_Entity ("test_duration", Node_Info.Test_Duration);
         Stream.Write_Long_Entity ("build_duration", Long_Long_Integer (Node_Info.Build_Duration));
         Stream.Write_Long_Entity ("sys_time", Long_Long_Integer (Node_Info.Sys_Time));
         Stream.Write_Long_Entity ("user_time", Long_Long_Integer (Node_Info.User_Time));
         Stream.End_Entity ("node");
      end loop;
      Stream.End_Array ("");
      Stream.End_Document;

   exception
      when Porion.Services.Not_Found =>
         API_Ctx.Set_Error (404, "node not found");
   end Get_Node_Usage;

end Porion.Builds.Rest;
