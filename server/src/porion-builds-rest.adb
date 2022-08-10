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
with Porion.Logs.Analysis;
with Porion.Projects;
with Porion.Queries;
with Porion.Metrics;
with Porion.Builds.Models;
with Porion.Builds.Services;
package body Porion.Builds.Rest is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builds.Rest");

   use type Porion.Builds.Models.Build_Status_Type;

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
     (Req     : in out Swagger.Servers.Request'Class;
      Reply   : in out Swagger.Servers.Response'Class;
      Stream  : in out Swagger.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type) is
      pragma Unreferenced (Req, Reply);

      use Porion.Logs.Analysis;
      use type ADO.Identifier;

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

   procedure Jenkins_Get_Last_Completed_Build
     (Req     : in out Swagger.Servers.Request'Class;
      Reply   : in out Swagger.Servers.Response'Class;
      Stream  : in out Swagger.Servers.Output_Stream'Class;
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
     (Req     : in out Swagger.Servers.Request'Class;
      Reply   : in out Swagger.Servers.Response'Class;
      Stream  : in out Swagger.Servers.Output_Stream'Class;
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

end Porion.Builds.Rest;
