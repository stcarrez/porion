-----------------------------------------------------------------------
--  porion-reports -- Report generation
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
with Ada.Calendar;
with PT.Texts;
with Porion.Nodes;
with Porion.Queries;
with Porion.Services;
with Porion.Executors;
with Porion.Metrics;
with Porion.Builds.Models;
package Porion.Reports is

   type Style_Configuration is record
      Default  : PT.Style_Type;
      Error    : PT.Style_Type;
      Warning  : PT.Style_Type;
      Info     : PT.Style_Type;
      Success  : PT.Style_Type;
      Disabled : PT.Style_Type;
   end record;

   function Format (Date : in Ada.Calendar.Time) return String;

   --  Format a duration using SS or MM:SS format.
   function Format (Value : in Duration) return String;

   --  Format a duration expressed in milliseconds.
   function Format (Value : in Millisecond_Type) return String;

   --  Format a duration expressed in microseconds.
   function Format (Value : in Microsecond_Type) return String;

   --  Format a percent of DV on the value.
   function Format_Percent (Dv    : in Integer;
                            Value : in Integer) return String with
      Pre => Value /= 0;

   --  Get a printable name for the node status.
   function Get_Status (Status : in Porion.Nodes.Node_Status_Type) return String;

   --  Create a report about the builds.  If the service is configured with
   --  a project, the report only indicates the builds of the project.
   procedure List_Builds (Service : in out Porion.Services.Context_Type'Class;
                          Printer : in out PT.Printer_Type'Class;
                          Styles  : in Style_Configuration) with
      Pre => Service.Is_Open;

   procedure List_Builds (List    : in Porion.Queries.Build_Info_Vector;
                          Printer : in out PT.Printer_Type'Class;
                          Styles  : in Style_Configuration;
                          Label   : in String);

   --  Create a report about the projects.
   procedure List_Projects (Service : in out Porion.Services.Context_Type'Class;
                            Printer : in out PT.Printer_Type'Class;
                            Styles  : in Style_Configuration) with
      Pre => Service.Is_Open;

   procedure List_Projects (List    : in Porion.Queries.Project_Info_Vector;
                            Printer : in out PT.Printer_Type'Class;
                            Styles  : in Style_Configuration;
                            Label   : in String);

   --  Create a report with the list of commands to build the project.
   procedure List_Commands (Commands : in Porion.Executors.Command_Vector;
                            Printer  : in out PT.Printer_Type'Class;
                            Styles   : in Style_Configuration);

   --  Create a report about the build nodes.  If the service is configured with
   --  a project, the report only indicates the build nodes of the project.
   procedure List_Nodes (Service : in out Porion.Services.Context_Type'Class;
                         Printer : in out PT.Printer_Type'Class;
                         Styles  : in Style_Configuration) with
      Pre => Service.Is_Open;

   procedure List_Nodes (List    : in Porion.Queries.Node_Info_Vector;
                         Printer : in out PT.Printer_Type'Class;
                         Styles  : in Style_Configuration;
                         Label   : in String);

   --  Create a report about the build queues.  If the service is configured with
   --  a project, the report only indicates the build queued of the project.
   procedure List_Queues (Service : in out Porion.Services.Context_Type'Class;
                          Printer : in out PT.Printer_Type'Class;
                          Styles  : in Style_Configuration) with
      Pre => Service.Is_Open;

   procedure List_Queues (List    : in Porion.Queries.Queue_Info_Vector;
                          Printer : in out PT.Printer_Type'Class;
                          Styles  : in Style_Configuration;
                          Label   : in String;
                          Hide_Project : in Boolean := False);

   --  Create a report with the unit tests for the given build.
   procedure List_Tests (Service : in out Porion.Services.Context_Type'Class;
                         Build   : in Porion.Builds.Models.Build_Ref;
                         Printer : in out PT.Printer_Type'Class;
                         Styles  : in Style_Configuration;
                         Failed_Only : in Boolean) with
      Pre => Service.Is_Open;

   --  Create a report with the unit tests.
   procedure List_Tests (List     : in Porion.Queries.Test_Info_Vector;
                         Printer  : in out PT.Printer_Type'Class;
                         Styles   : in Style_Configuration);

   --  Create a report with the build metrics for the given build.
   procedure List_Metrics (Service : in out Porion.Services.Context_Type'Class;
                           Build   : in Porion.Builds.Models.Build_Ref;
                           Printer : in out PT.Printer_Type'Class;
                           Styles  : in Style_Configuration) with
      Pre => Service.Is_Open;

   --  Create a report with the build metrics.
   procedure List_Metrics (List     : in Porion.Queries.Metric_Info_Vector;
                           Printer  : in out PT.Printer_Type'Class;
                           Styles   : in Style_Configuration);

   procedure List_Metrics (List     : in Porion.Queries.Metric_Info_Vector;
                           Metric   : in Porion.Metrics.Metric_Type;
                           Printer  : in out PT.Printer_Type'Class;
                           Fields   : in PT.Texts.Field_Array;
                           Styles   : in Style_Configuration);

   --  Create a report with the build environment variables.
   procedure List_Environment (Service : in out Porion.Services.Context_Type'Class;
                               Printer : in out PT.Printer_Type'Class;
                               Styles  : in Style_Configuration) with
      Pre => Service.Is_Open;

   procedure List_Environment (List     : in Porion.Queries.Environment_Info_Vector;
                               Printer  : in out PT.Printer_Type'Class;
                               Styles   : in Style_Configuration);

end Porion.Reports;
