-----------------------------------------------------------------------
--  porion-xunit-parsers -- Parse xunit like XML results
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
with Ada.Streams.Stream_IO;

with Util.Beans.Objects;
with Util.Streams.Files;
with Util.Serialize.Mappers.Record_Mapper;
with Util.Serialize.IO.XML;
with Util.Log.Loggers;
with Util.Files;

with Porion.XUnit.Models;
package body Porion.XUnit.Parsers is

   use Util.Beans.Objects;

   subtype Test_Status_Type is Porion.XUnit.Models.Test_Status_Type;

   type XUnit_Fields is (TESTSUITE_NAME,
                         TESTSUITE_TIME,
                         TESTSUITE_END,
                         TESTCASE_NAME,
                         TESTCASE_CLASSNAME,
                         TESTCASE_TIME,
                         TESTCASE_OUTPUT,
                         TESTCASE_FAILURE,
                         TESTCASE_FILE,
                         TESTCASE_FEATURE,
                         TESTCASE_ASSERTIONS,
                         TESTCASE_ERROR_TYPE,
                         TESTCASE_ERROR,
                         TESTCASE);

   type XUnit_Config is limited record
      Suite_Name       : Util.Beans.Objects.Object;
      Suite_Time       : Util.Beans.Objects.Object;
      Name             : Util.Beans.Objects.Object;
      Classname        : Util.Beans.Objects.Object;
      Duration         : Microsecond_Type;
      Output           : Util.Beans.Objects.Object;
      Failure          : Util.Beans.Objects.Object;
      File             : Util.Beans.Objects.Object;
      Feature          : Util.Beans.Objects.Object;
      Assertions       : Util.Beans.Objects.Object;
      Error_Type       : Util.Beans.Objects.Object;
      Error            : Util.Beans.Objects.Object;
      Group            : Group_Path;
      Override_Context : Boolean := True;
   end record;
   type XUnit_Config_Access is access all XUnit_Config;

   function Get_Status (Config : in XUnit_Config) return Test_Status_Type;
   function To_Duration (Value : in Util.Beans.Objects.Object) return Microsecond_Type;

   Log   : aliased constant Util.Log.Loggers.Logger
     := Util.Log.Loggers.Create ("Porion.XUnit.Parsers");

   function To_Duration (Value : in Util.Beans.Objects.Object) return Microsecond_Type is
   begin
      if Is_Null (Value) then
         return 0;
      else
         declare
            S   : constant String := To_String (Value);
            Dot : constant Natural := Util.Strings.Index (S, '.');
            V1  : Microsecond_Type;
            V2  : Microsecond_Type;
            L   : Natural;
         begin
            if Dot > 0 then
               V1 := Microsecond_Type'Value (S (S'First .. Dot - 1));
               L := S'Last - Dot;
               if L >= 6 then
                  V2 := Microsecond_Type'Value (S (Dot + 1 .. Dot + 6));
               elsif L > 0 then
                  V2 := Microsecond_Type'Value (S (Dot + 1 .. S'Last));
                  while L < 6 loop
                     V2 := V2 * 10;
                     L := L + 1;
                  end loop;
               else
                  V2 := 0;
               end if;
            else
               V1 := Microsecond_Type'Value (S);
               V2 := 0;
            end if;
            return V1 * 1000_000 + V2;
         end;
      end if;

   exception
      when Constraint_Error =>
         return 0;
   end To_Duration;

   function Get_Status (Config : in XUnit_Config) return Test_Status_Type is
   begin
      if not Is_Null (Config.Failure) then
         return XUnit.Models.TEST_FAIL;
      else
         return XUnit.Models.TEST_PASS;
      end if;
   end Get_Status;

   procedure Scan (Path    : in String;
                   Stream  : in out Util.Streams.Buffered.Input_Buffer_Stream'Class;
                   Results : in out Analysis.Test_Results) is
      procedure Set_Member (N     : in out XUnit_Config;
                            Field : in XUnit_Fields;
                            Value : in Util.Beans.Objects.Object);

      procedure Set_Member (N     : in out XUnit_Config;
                            Field : in XUnit_Fields;
                            Value : in Util.Beans.Objects.Object) is
      begin
         case Field is
            when TESTSUITE_NAME =>
               N.Suite_Name := Value;
               N.Group.Append (To_String (Value));

            when TESTSUITE_END =>
               N.Group.Delete_Last;

            when TESTSUITE_TIME =>
               N.Suite_Time := Value;

            when TESTCASE_CLASSNAME =>
               N.Classname := Value;

            when TESTCASE_NAME =>
               N.Name := Value;

            when TESTCASE_TIME =>
               N.Duration := To_Duration (Value);

            when TESTCASE_OUTPUT =>
               N.Output := Value;

            when TESTCASE_FAILURE =>
               N.Failure := Value;

            when TESTCASE_FILE =>
               N.Output := Value;

            when TESTCASE_FEATURE =>
               N.Feature := Value;

            when TESTCASE_ERROR =>
               N.Error := Value;

            when TESTCASE_ERROR_Type =>
               N.Error_Type := Value;

            when TESTCASE_ASSERTIONS =>
               N.Assertions := Value;

            when TESTCASE =>
               Analysis.Add_Test (Results  => Results,
                                  Group    => N.Group,
                                  Name     => To_String (N.Name),
                                  Duration => N.Duration,
                                  Status   => Get_Status (N));
               N.Output := Null_Object;
               N.Failure := Null_Object;
               N.Error := Null_Object;
               N.Assertions := Null_Object;
               N.Duration := 0;
               N.Feature := Null_Object;

         end case;
      end Set_Member;

      package XUnit_Mapper is
        new Util.Serialize.Mappers.Record_Mapper (Element_Type        => XUnit_Config,
                                                  Element_Type_Access => XUnit_Config_Access,
                                                  Fields              => XUnit_Fields,
                                                  Set_Member          => Set_Member);

      Config : aliased XUnit_Config;
      Mapper : aliased XUnit_Mapper.Mapper;
      Parser : Util.Serialize.Mappers.Processing;
      Reader : Util.Serialize.IO.XML.Parser;
   begin
      Log.Info ("Scanning file {0}", Path);

      Mapper.Add_Mapping ("**/testsuite/@name", TESTSUITE_NAME);
      Mapper.Add_Mapping ("**/testsuite/@time", TESTSUITE_TIME);
      Mapper.Add_Mapping ("**/testsuite", TESTSUITE_END);

      Mapper.Add_Mapping ("**/testcase/@classname", TESTCASE_CLASSNAME);
      Mapper.Add_Mapping ("**/testcase/@name", TESTCASE_NAME);
      Mapper.Add_Mapping ("**/testcase/@time", TESTCASE_TIME);
      Mapper.Add_Mapping ("**/testcase/system-out", TESTCASE_OUTPUT);
      Mapper.Add_Mapping ("**/testcase/failure/@type", TESTCASE_FAILURE);
      Mapper.Add_Mapping ("**/testcase", TESTCASE);

      --  phpunit
      Mapper.Add_Mapping ("**/testcase/@class", TESTCASE_CLASSNAME);
      Mapper.Add_Mapping ("**/testcase/@file", TESTCASE_FILE);
      Mapper.Add_Mapping ("**/testcase/@assertions", TESTCASE_ASSERTIONS);
      Mapper.Add_Mapping ("**/testcase/@feature", TESTCASE_FEATURE);
      Mapper.Add_Mapping ("**/testcase/error/@type", TESTCASE_ERROR_TYPE);
      Mapper.Add_Mapping ("**/testcase/error", TESTCASE_ERROR);

      Mapper.Add_Mapping ("@name", TESTSUITE_NAME);
      Mapper.Add_Mapping ("@time", TESTSUITE_TIME);
      --  Mapper.Dump (Log);

      XUnit_Mapper.Set_Context (Parser, Config'Unchecked_Access);
      Parser.Add_Mapping ("testsuite", Mapper'Unchecked_Access);
      Parser.Add_Mapping ("testsuites", Mapper'Unchecked_Access);
      Reader.Set_Logger (Log'Access);
      Reader.Parse (Stream, Parser);
   end Scan;

   procedure Scan (Path    : in String;
                   Results : in out Analysis.Test_Results) is
      Stream     : aliased Util.Streams.Files.File_Stream;
      Buffer     : Util.Streams.Buffered.Input_Buffer_Stream;
   begin
      Buffer.Initialize (Input  => Stream'Unchecked_Access,
                         Size   => 1024);
      Stream.Open (Mode => Ada.Streams.Stream_IO.In_File, Name => Path);
      Scan (Path, Buffer, Results);
   end Scan;

   procedure Scan (Path    : in String;
                   Pattern : in String;
                   Exclude : in Util.Strings.Vectors.Vector;
                   Results : in out Analysis.Test_Results) is
      use Ada.Directories;

      Sep     : constant Natural := Util.Strings.Index (Pattern, '/');
   begin
      if Sep > 0 then
         declare
            Name : constant String := Pattern (Pattern'First .. Sep - 1);
            Child : constant String := Util.Files.Compose (Path, Name);
         begin
            Scan (Child, Pattern (Sep + 1 .. Pattern'Last), Exclude, Results);
            return;
         end;
      else
         declare
            Filter  : constant Filter_Type := (Ordinary_File => True,
                                               Directory     => True,
                                               others        => False);
            Search  : Search_Type;
            Ent     : Ada.Directories.Directory_Entry_Type;
         begin
            Start_Search (Search, Directory => Path,
                          Pattern => Pattern, Filter => Filter);
            while More_Entries (Search) loop
               Get_Next_Entry (Search, Ent);
               declare
                  Full_Path : constant String := Ada.Directories.Full_Name (Ent);
               begin
                  Scan (Full_Path, Results);
               end;
            end loop;
         end;
      end if;
   end Scan;

end Porion.XUnit.Parsers;
