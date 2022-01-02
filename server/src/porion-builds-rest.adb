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
with Porion.Builds.Models;
with Porion.Builds.Services;
package body Porion.Builds.Rest is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builds.Rest");

   use type Porion.Builds.Models.Build_Status_Type;

   procedure Get_Build_Log
     (Req     : in out Swagger.Servers.Request'Class;
      Reply   : in out Swagger.Servers.Response'Class;
      Stream  : in out Swagger.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type) is
      pragma Unreferenced (Req, Reply);

      use Porion.Logs.Analysis;

      Rules  : constant String := Context.Recipe.Get_Filter_Rules;
      Ctx    : Porion.Logs.Analysis.Analyser_Type;
      Levels : Porion.Logs.Analysis.Level_Map;
      List   : Porion.Logs.Analysis.Line_Vector;
      Dir    : constant String := Builds.Services.Get_Log_Directory (Context);
      Path   : constant String := Ada.Directories.Compose (Dir, "build.log");
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
         Stream.Start_Entity ("log");
         Stream.Write_Attribute ("number", Line.Number);
         case Line.Level is
            when LOG_UNKNOWN =>
               Stream.Write_Attribute ("level", "unkown");

            when LOG_PORION =>
               Stream.Write_Attribute ("level", "porion");

            when LOG_FATAL =>
               Stream.Write_Attribute ("level", "fatal");

            when LOG_ERROR =>
               Stream.Write_Attribute ("level", "error");

            when LOG_WARNING =>
               Stream.Write_Attribute ("level", "warning");

            when LOG_CONTEXT =>
               Stream.Write_Attribute ("level", "context");

            when LOG_INFO =>
               Stream.Write_Attribute ("level", "info");

            when LOG_TRACE =>
               Stream.Write_Attribute ("level", "trace");

            when LOG_DEBUG =>
               Stream.Write_Attribute ("level", "debug");

         end case;
         Stream.Write_Entity ("content", Line.Content);
         Stream.End_Entity ("log");
      end loop;
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

   type Badge_Info is record
      Label   : UString;
      Message : UString;
      Color   : UString;
   end record;

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
         Get_Tests_Badge (Context, Badge);
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
