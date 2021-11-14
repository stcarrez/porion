-----------------------------------------------------------------------
--  porion-metrics-spaces -- Get metrics for the file system space used by the build
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
with Porion.Tools;
package body Porion.Metrics.Spaces is

   use type Ada.Directories.File_Size;

   function Create (Session : in ADO.Sessions.Master_Session;
                    Config  : in Porion.Configs.Config_Type) return Controller_Access is
      Result  : constant Spaces_Controller_Access := new Controller_Type;
      Prefix  : constant String := Config.Get ("prefix", "");
   begin
      Result.Kind := METRIC_SPACE;
      Result.Session := Session;
      if Prefix'Length > 0 then
         Result.Prefix := To_UString (Prefix & ".");
      end if;
      return Result.all'Access;
   end Create;

   overriding
   procedure Collect (Controller : in out Controller_Type;
                      Path       : in String;
                      Executor   : in out Porion.Executors.Executor_Type'Class) is
      Stats  : Porion.Tools.Tree_Stat_Type;
      Prefix : constant String := To_String (Controller.Prefix);
   begin
      Porion.Tools.Find_Stats (Path, Stats);
      Controller.Save_Metric (Prefix & "total_size", Natural (Stats.Total_Size / 1024));
      Controller.Save_Metric (Prefix & "file_count", Stats.File_Count);
      Controller.Save_Metric (Prefix & "directory_count", Stats.Dir_Count);
   end Collect;

end Porion.Metrics.Spaces;
