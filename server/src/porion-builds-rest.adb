-----------------------------------------------------------------------
--  porion-builds-beans -- Beans for module builds
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
with Ada.Directories;
with Util.Log.Loggers;
with Porion.Builds.Modules;
with Porion.Logs.Analysis;
with Porion.Projects;
with Porion.Services;
with Porion.Builds.Services;
package body Porion.Builds.Rest is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builds.Rest");

   procedure Get_Build_Log
     (Req     : in out Swagger.Servers.Request'Class;
      Reply   : in out Swagger.Servers.Response'Class;
      Stream  : in out Swagger.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type) is
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
   begin
      Stream.Start_Document;
      Stream.Start_Entity ("");
      Stream.Write_Entity ("color", "blue");
      Stream.End_Entity ("");
      Stream.End_Document;
   end Jenkins_Get_Last_Completed_Build;

   procedure Get_Project_Schields_Status
     (Req     : in out Swagger.Servers.Request'Class;
      Reply   : in out Swagger.Servers.Response'Class;
      Stream  : in out Swagger.Servers.Output_Stream'Class;
      Context : in out Porion.Services.Context_Type) is
   begin
      Stream.Start_Document;
      Stream.Start_Entity ("");
      Stream.Write_Entity ("schemaVersion", 1);
      Stream.Write_Entity ("label", "build");
      Stream.Write_Entity ("message", "passing");
      Stream.Write_Entity ("color", "green");
      Stream.End_Entity ("");
      Stream.End_Document;
   end Get_Project_Schields_Status;

end Porion.Builds.Rest;
