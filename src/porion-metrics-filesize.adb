-----------------------------------------------------------------------
--  porion-metrics-filesize -- Metric to track the size of a file
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
with Util.Files;
package body Porion.Metrics.Filesize is

   use Ada.Strings.Unbounded;
   use type Ada.Directories.File_Size;

   function Create (Session : in ADO.Sessions.Master_Session;
                    Params  : in UString) return Controller_Access is
      Result : constant Filesize_Controller_Access := new Controller_Type;
      Sep    : constant Natural := Index (Params, " ");
      Len    : constant Natural := Length (Params);
   begin
      Result.Kind := METRIC_FILESIZE;
      Result.Session := Session;
      if Sep > 0 and Sep < Len then
         Result.Label := Unbounded_Slice (Params, 1, Sep - 1);
         Result.Path := Unbounded_Slice (Params, Sep + 1, Len);
      else
         Result.Path := Params;
         Result.Label := To_UString ("filesize");
      end if;
      return Result.all'Access;
   end Create;

   overriding
   procedure Collect (Controller : in out Controller_Type;
                      Path       : in String;
                      Executor   : in out Porion.Executors.Executor_Type'Class) is
      File_Path : constant String := Util.Files.Compose (Path, To_String (Controller.Path));
      Size      : Ada.Directories.File_Size;
   begin
      if Ada.Directories.Exists (File_Path) then
         Size := Ada.Directories.Size (File_Path);
         Controller.Save_Metric (To_String (Controller.Label), Natural (Size / 1024));
      end if;
   end Collect;

end Porion.Metrics.Filesize;
