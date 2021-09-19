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
with PT;
with Porion.Services;
package Porion.Reports is

   type Style_Configuration is record
      Default  : PT.Style_Type;
      Error    : PT.Style_Type;
      Info     : PT.Style_Type;
      Success  : PT.Style_Type;
      Disabled : PT.Style_Type;
   end record;

   --  Create a report about the builds.  If the service is configured with
   --  a project, the report only indicates the builds of the project.
   procedure List_Builds (Service : in out Porion.Services.Context_Type'Class;
                          Printer : in out PT.Printer_Type'Class;
                          Styles  : in Style_Configuration);

   --  Create a report about the projects.
   procedure List_Projects (Service : in out Porion.Services.Context_Type'Class;
                            Printer : in out PT.Printer_Type'Class;
                            Styles  : in Style_Configuration);

end Porion.Reports;
