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
with ADO.Sessions;
private with EL.Expressions;
private package Porion.Metrics.Cloc is

   CLOC_COMMAND    : constant String := "cloc --quiet --xml #{path}";

   type Controller_Type is limited new Porion.Metrics.Controller_Type with private;

   function Create (Session : in ADO.Sessions.Master_Session;
                    Params  : in UString) return Controller_Access;

   type Reporter_Type is limited new Porion.Metrics.Reporter_Type with null record;

   function Create return Reporter_Access;

private

   type Controller_Type is limited new Porion.Metrics.Controller_Type with record
      Command : EL.Expressions.Expression;
      Prefix  : UString;
   end record;

   type Cloc_Controller_Access is access all Controller_Type;

   overriding
   procedure Collect (Controller : in out Controller_Type;
                      Path       : in String;
                      Executor   : in out Porion.Executors.Executor_Type'Class);

   --  Produce a report with the metric values collected during a build.
   overriding
   procedure Report (Controller : in out Reporter_Type;
                     Printer    : in out PT.Printer_Type'Class;
                     Fields     : in PT.Texts.Field_Array;
                     Values     : in Value_Map);

end Porion.Metrics.Cloc;
