-----------------------------------------------------------------------
--  porion-metrics-cloc -- Run cloc(1) and get various source code metrics
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
with Util.Strings;
with Util.Log.Loggers;
with Util.Beans.Objects;
with Util.Serialize.Mappers.Record_Mapper;
with Util.Serialize.IO.XML;
with EL.Contexts.Default;
with PT.Colors;
with Porion.Logs;
package body Porion.Metrics.Cloc is

   package UBO renames Util.Beans.Objects;

   procedure Scan (Content : in String;
                   Process : not null access
                      procedure (Language      : in String;
                                 Files_Count   : in Natural;
                                 Blank_Count   : in Natural;
                                 Comment_Count : in Natural;
                                 Code_Count    : in Natural));

   use Ada.Strings.Unbounded;

   Log   : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Metrics.Cloc");

   procedure Scan (Content : in String;
                   Process : not null access
                      procedure (Language      : in String;
                                 Files_Count   : in Natural;
                                 Blank_Count   : in Natural;
                                 Comment_Count : in Natural;
                                 Code_Count    : in Natural)) is

      type CLoc_Fields is (CLOC_LANG_NAME,
                           CLOC_FILES_COUNT,
                           CLOC_BLANK_COUNT,
                           CLOC_COMMENT_COUNT,
                           CLOC_CODE_COUNT,
                           CLOC_LANGUAGE,
                           CLOC_TOTAL_FILES,
                           CLOC_TOTAL_BLANK,
                           CLOC_TOTAL_COMMENT,
                           CLOC_TOTAL_CODE,
                           CLOC_TOTAL);

      type Cloc_Config is limited record
         Language         : UBO.Object;
         Files_Count      : Natural := 0;
         Blank_Count      : Natural := 0;
         Comment_Count    : Natural := 0;
         Code_Count       : Natural := 0;
         Total_Files      : Natural := 0;
         Total_Blank      : Natural := 0;
         Total_Comment    : Natural := 0;
         Total_Code       : Natural := 0;
      end record;
      type Cloc_Config_Access is access all Cloc_Config;

      procedure Set_Member (N     : in out Cloc_Config;
                            Field : in CLoc_Fields;
                            Value : in UBO.Object);

      procedure Set_Member (N     : in out Cloc_Config;
                            Field : in CLoc_Fields;
                            Value : in UBO.Object) is
      begin
         case Field is
            when CLOC_LANG_NAME =>
               N.Language := Value;

            when CLOC_FILES_COUNT =>
               N.Files_Count := UBO.To_Integer (Value);

            when CLOC_BLANK_COUNT =>
               N.Blank_Count := UBO.To_Integer (Value);

            when CLOC_COMMENT_COUNT =>
               N.Comment_Count := UBO.To_Integer (Value);

            when CLOC_CODE_COUNT =>
               N.Code_Count := UBO.To_Integer (Value);

            when CLOC_LANGUAGE =>
               if not UBO.Is_Empty (N.Language) then
                  Process (UBO.To_String (N.Language), N.Files_Count,
                           N.Blank_Count, N.Comment_Count, N.Code_Count);
               end if;
               N.Files_Count := 0;
               N.Blank_Count := 0;
               N.Code_Count := 0;
               N.Comment_Count := 0;
               N.Language := UBO.Null_Object;

            when CLOC_TOTAL_FILES =>
               N.Total_Files := UBO.To_Integer (Value);

            when CLOC_TOTAL_BLANK =>
               N.Total_Blank := UBO.To_Integer (Value);

            when CLOC_TOTAL_COMMENT =>
               N.Total_Comment := UBO.To_Integer (Value);

            when CLOC_TOTAL_CODE =>
               N.Total_Code := UBO.To_Integer (Value);

            when CLOC_TOTAL =>
               Process ("total", N.Total_Files,
                        N.Total_Blank, N.Total_Comment, N.Total_Code);

         end case;
      end Set_Member;

      package CLoc_Mapper is
        new Util.Serialize.Mappers.Record_Mapper (Element_Type        => Cloc_Config,
                                                  Element_Type_Access => Cloc_Config_Access,
                                                  Fields              => Cloc_Fields,
                                                  Set_Member          => Set_Member);

      Config : aliased Cloc_Config;
      Mapper : aliased CLoc_Mapper.Mapper;
      Parser : Util.Serialize.Mappers.Processing;
      Reader : Util.Serialize.IO.XML.Parser;
   begin
      Log.Info ("Scanning content {0}", Content);

      Mapper.Add_Mapping ("languages/language/@name", CLOC_LANG_NAME);
      Mapper.Add_Mapping ("languages/language/@files_count", CLOC_FILES_COUNT);
      Mapper.Add_Mapping ("languages/language/@blank", CLOC_BLANK_COUNT);
      Mapper.Add_Mapping ("languages/language/@comment", CLOC_COMMENT_COUNT);
      Mapper.Add_Mapping ("languages/language/@code", CLOC_CODE_COUNT);
      Mapper.Add_Mapping ("languages/language", CLOC_LANGUAGE);

      Mapper.Add_Mapping ("languages/total/@sum_files", CLOC_TOTAL_FILES);
      Mapper.Add_Mapping ("languages/total/@blank", CLOC_TOTAL_BLANK);
      Mapper.Add_Mapping ("languages/total/@comment", CLOC_TOTAL_COMMENT);
      Mapper.Add_Mapping ("languages/total/@code", CLOC_TOTAL_CODE);
      Mapper.Add_Mapping ("languages/total", CLOC_TOTAL);

      Cloc_Mapper.Set_Context (Parser, Config'Unchecked_Access);
      Parser.Add_Mapping ("results", Mapper'Unchecked_Access);
      Reader.Parse_String (Content, Parser);
   end Scan;

   function Create (Session : in ADO.Sessions.Master_Session;
                    Params  : in UString) return Controller_Access is
      pragma Unreferenced (Params);

      Result  : constant Cloc_Controller_Access := new Controller_Type;
      Command : constant String := Configs.Get ("command_cloc", CLOC_COMMAND);
      Ctx     : EL.Contexts.Default.Default_Context;
   begin
      Result.Kind := METRIC_CLOC;
      Result.Session := Session;
      Result.Command := EL.Expressions.Create_Expression (Command, Ctx);
      return Result.all'Access;
   end Create;

   overriding
   procedure Collect (Controller : in out Controller_Type;
                      Path       : in String;
                      Executor   : in out Porion.Executors.Executor_Type'Class) is
      procedure Process (Line : in String);
      procedure Process_Metric (Language      : in String;
                                Files_Count   : in Natural;
                                Blank_Count   : in Natural;
                                Comment_Count : in Natural;
                                Code_Count    : in Natural);

      Content : UString;

      procedure Process (Line : in String) is
      begin
         Executor.Log (Porion.Logs.LOG_EXECUTION, Line);

         Append (Content, Line);
      end Process;

      procedure Process_Metric (Language      : in String;
                                Files_Count   : in Natural;
                                Blank_Count   : in Natural;
                                Comment_Count : in Natural;
                                Code_Count    : in Natural) is
         Value   : constant Natural := Blank_Count + Comment_Count + Code_Count;
         Content : constant String
            := Util.Strings.Image (Files_Count) & ":"
               & Util.Strings.Image (Blank_Count) & ":"
               & Util.Strings.Image (Comment_Count) & ":"
               & Util.Strings.Image (Code_Count);
      begin
         Controller.Save_Metric (Language, Language, Value, Content);
      end Process_Metric;

      Config : Porion.Configs.Config_Type;
      Result : Integer;
   begin
      Config.Set ("path", ".");
      Executor.Execute (Controller.Command, Config, Process'Access, Path,
                        Strip_Crlf => True, Status => Result);
      if Result /= 0 then
         return;
      end if;

      Scan (To_String (Content), Process_Metric'Access);
   end Collect;

   function Create return Reporter_Access is
   begin
      return new Reporter_Type;
   end Create;

   --  ------------------------------
   --  Produce a report with the metric values collected during a build.
   --  ------------------------------
   overriding
   procedure Report (Controller : in out Reporter_Type;
                     Printer    : in out PT.Printer_Type'Class;
                     Fields     : in PT.Texts.Field_Array;
                     Values     : in Value_Map) is
      pragma Unreferenced (Controller);

      function "<" (Left, Right : in Label_Value_Type) return Boolean
         is (Left.Value > Right.Value);

      package Sort is
         new Value_Vectors.Generic_Sorting ("<" => "<");

      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Chart  : PT.Charts.Printer_Type := PT.Charts.Create (Printer);
      Green  : constant PT.Style_Type := Printer.Create_Style (PT.Colors.Green);
      Red    : constant PT.Style_Type := Printer.Create_Style (PT.Colors.Red);
      List   : Porion.Metrics.Value_Vector;
      Max    : Natural := 0;
   begin
      for Value of Values loop
         List.Append (Value);
         if Value.Value > Max then
            Max := Value.Value;
         end if;
      end loop;
      Sort.Sort (List);

      for Value of List loop
         Writer.Put (Fields (1), Value.Label);
         Writer.Put_Int (Fields (2), Value.Value);
         Draw_Value_Bar (Chart, Writer.Get_Box (Fields (3)),
                         Value.Value, 0, Max, Green, Red);
         Writer.New_Line;
      end loop;

   end Report;

end Porion.Metrics.Cloc;
