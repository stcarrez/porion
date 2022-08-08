-----------------------------------------------------------------------
--  porion-builders-xunit -- Builder to start the analysis of unit tests
--  Copyright (C) 2021-2022 Stephane Carrez
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
with Util.Strings.Sets;
with Util.Beans.Objects;
with Util.Log.Loggers;
with Util.Files;
with Util.Streams.Buffered;
with Porion.XUnit.Analysis;
with Porion.XUnit.Parsers;
package body Porion.Builders.XUnit is

   subtype Input_Buffer_Stream is Util.Streams.Buffered.Input_Buffer_Stream;

   Log   : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builders.XUnit");

   procedure Load (From : in Util.Beans.Objects.Object;
                   Into : in out Util.Strings.Vectors.Vector);

   overriding
   procedure Build (Controller : in out Controller_Type;
                    Build      : in out Porion.Builds.Models.Build_Ref;
                    Path       : in String;
                    Executor   : in out Porion.Executors.Executor_Type'Class) is
      Results : Porion.XUnit.Analysis.Test_Results;
      Files   : Util.Strings.Sets.Set;
   begin
      Log.Info ("XUnit scan and analyze tests in {0}", Path);

      if Controller.Includes.Is_Empty then
         Log.Error ("includes list is empty");
         return;
      end if;

      for Include of Controller.Includes loop
         if Executor.Is_Dry_Run then
            Executor.Record_Command ("xunit " & Include);
         else
            declare
               Sep  : constant Natural := Util.Strings.Rindex (Include, '/');
            begin
               if Sep > 0 then
                  Executor.Scan_Directory (Util.Files.Compose (Path, Include (Include'First .. Sep - 1)),
                                           Include (Sep + 1 .. Include'Last), Controller.Excludes, Files);
               else
                  Executor.Scan_Directory (Path, Include, Controller.Excludes, Files);
               end if;
            end;
         end if;
      end loop;

      Log.Info ("XUnit scan found{0} files", Files.Length'Image);

      if not Executor.Is_Dry_Run then
         for File of Files loop
            declare
               procedure Scan (Stream : in out Input_Buffer_Stream'Class) is
               begin
                  Porion.XUnit.Parsers.Scan (File, Stream, Results);
               end Scan;
            begin
               Executor.Read_File (File, Scan'Access);
            end;
         end loop;
         Porion.XUnit.Analysis.Save (Results => Results,
                                     Build   => Build,
                                     Session => Controller.Session);
      end if;
   end Build;

   overriding
   procedure Clean (Controller : in out Controller_Type) is
   begin
      null;
   end Clean;

   overriding
   procedure Configure (Controller : in out Controller_Type;
                        Parameters : in Util.Strings.Vectors.Vector) is
   begin
      for Param of Parameters loop
         declare
            Pos : constant Natural := Util.Strings.Index (Param, '=');
         begin
            if Pos = 0 then
               Controller.Includes.Append (Param);
            elsif Param (Param'First .. Pos) = "includes=" then
               Controller.Includes.Append (Param (Pos + 1 .. Param'Last));
            elsif Param (Param'First .. Pos) = "excludes=" then
               Controller.Excludes.Append (Param (Pos + 1 .. Param'Last));
            end if;
         end;
      end loop;
   end Configure;

   overriding
   procedure Print (Controller : in out Controller_Type;
                    Stream     : in out Util.Serialize.IO.Output_Stream'Class) is
   begin
      if not Controller.Includes.Is_Empty then
         Stream.Start_Array ("includes");
         for Include of Controller.Includes loop
            Stream.Write_Entity ("", Include);
         end loop;
         Stream.End_Array ("includes");
      end if;

      if not Controller.Excludes.Is_Empty then
         Stream.Start_Array ("excludes");
         for Exclude of Controller.Excludes loop
            Stream.Write_Entity ("", Exclude);
         end loop;
         Stream.End_Array ("excludes");
      end if;
   end Print;

   procedure Load (From : in Util.Beans.Objects.Object;
                   Into : in out Util.Strings.Vectors.Vector) is
   begin
      if Util.Beans.Objects.Is_Array (From) then
         for I in 1 .. Util.Beans.Objects.Get_Count (From) loop
            Load (Util.Beans.Objects.Get_Value (From, I), Into);
         end loop;
      elsif not Util.Beans.Objects.Is_Null (From) then
         Into.Append (Util.Beans.Objects.To_String (From));
      end if;
   end Load;

   function Create (Session : in ADO.Sessions.Master_Session;
                    Config  : in Porion.Configs.Config_Type) return Controller_Access is
      Controller : constant XUnit_Controller_Access := new Controller_Type;
   begin
      Load (Config.Get_Value ("includes"), Controller.Includes);
      Load (Config.Get_Value ("excludes"), Controller.Excludes);

      Controller.Config := Config;
      Controller.Session := Session;
      return Controller.all'Access;
   end Create;

end Porion.Builders.XUnit;
