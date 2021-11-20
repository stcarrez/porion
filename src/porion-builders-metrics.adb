-----------------------------------------------------------------------
--  porion-builders-metrics -- Run a metrics controller to collect data on the build
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
with Porion.Metrics.Factories;
package body Porion.Builders.Metrics is

   use Ada.Strings.Unbounded;
   use type Porion.Metrics.Controller_Access;

   overriding
   procedure Build (Controller : in out Controller_Type;
                    Build      : in out Porion.Builds.Models.Build_Ref;
                    Path       : in String;
                    Executor   : in out Porion.Executors.Executor_Type'Class) is
   begin
      if Controller.Metric /= null then
         if Executor.Is_Dry_Run then
            Executor.Record_Command ("metric " & Controller.Metric.Get_Kind
                                     & " " & To_String (Controller.Params));
         else
            Controller.Metric.Build (Build, Path, Executor);
         end if;
      end if;
   end Build;

   overriding
   procedure Configure (Controller : in out Controller_Type;
                        Parameters : in Util.Strings.Vectors.Vector) is
      Index  : Natural := 0;
   begin
      if Parameters.Is_Empty then
         return;
      end if;

      Controller.Params := Null_Unbounded_String;
      for Arg of Parameters loop
         Index := Index + 1;
         if Index > 1 then
            if Index > 2 then
               Append (Controller.Params, " ");
            end if;
            Append (Controller.Params, Arg);
         end if;
      end loop;
      Controller.Metric := Porion.Metrics.Factories.Create (Parameters.First_Element,
                                                            Controller.Session,
                                                            Controller.Params);
   end Configure;

   overriding
   procedure Print (Controller : in out Controller_Type;
                    Stream     : in out Util.Serialize.IO.Output_Stream'Class) is
   begin
      Stream.Start_Entity ("");
      if Controller.Metric /= null then
         Stream.Write_Entity ("metric", Controller.Metric.Get_Kind);
         Stream.Write_Entity ("params", Controller.Params);
      end if;
      Stream.End_Entity ("");
   end Print;

   function Create (Session : in ADO.Sessions.Master_Session;
                    Config  : in Porion.Configs.Config_Type) return Controller_Access is
      Controller : constant Metric_Controller_Access := new Controller_Type;
      Kind       : constant String := Config.Get ("metric");
      Params     : constant UString := Config.Get ("params");
   begin
      Controller.Metric := Porion.Metrics.Factories.Create (Kind, Session, Params);
      Controller.Session := Session;
      Controller.Params := Params;
      return Controller.all'Access;
   end Create;

end Porion.Builders.Metrics;
