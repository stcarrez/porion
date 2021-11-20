-----------------------------------------------------------------------
--  porion-logs-analysis -- Log analysis
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

with Ada.Containers.Indefinite_Vectors;
private with GNAT.Regpat;
package Porion.Logs.Analysis is

   type Level_Type is (LOG_UNKNOWN,
                       LOG_PORION,
                       LOG_FATAL,
                       LOG_ERROR,
                       LOG_WARNING,
                       LOG_CONTEXT,
                       LOG_INFO,
                       LOG_TRACE,
                       LOG_DEBUG);

   type Level_Map is array (Level_Type) of Boolean;

   type Line_Info_Type is record
      Level : Level_Type := LOG_FATAL;
      Drop  : Boolean := True;
   end record;

   type Line_Type (Length : Natural) is record
      Number  : Natural := 0;
      Context : Boolean := False;
      Level   : Level_Type := LOG_INFO;
      Content : String (1 .. Length);
   end record;

   package Line_Vectors is new
      Ada.Containers.Indefinite_Vectors (Index_Type   => Positive,
                                         Element_Type => Line_Type);

   subtype Line_Vector is Line_Vectors.Vector;
   subtype Line_Cursor is Line_Vectors.Cursor;

   type Analyser_Type is limited private;

   --  Analyze the log line according to the current context and the log rules.
   procedure Analyse (Context : in out Analyser_Type;
                      Line    : in String;
                      Result  : out Line_Info_Type);

   --  Read the log file and apply the analysis rules to collect the interesting content.
   procedure Read (Context : in out Analyser_Type;
                   Path    : in String;
                   Result  : in out Line_Vector);

   --  Configure the levels which are accepted by the Read procedure.
   procedure Set_Filter (Context : in out Analyser_Type;
                         Levels  : in Level_Map);

   --  Set the filtering rules that must be applied when analysing the logs.
   procedure Set_Rules (Context : in out Analyser_Type;
                        Rules   : in String);

private

   type Rule_Matcher (Size : GNAT.Regpat.Program_Size) is record
      Pattern : GNAT.Regpat.Pattern_Matcher (Size);
      Kind    : Line_Info_Type;
   end record;

   package Match_Vectors is
      new Ada.Containers.Indefinite_Vectors (Index_Type   => Positive,
                                             Element_Type => Rule_Matcher,
                                             "="          => "=");

   subtype Match_Vector is Match_Vectors.Vector;

   type Analyser_Type is limited record
      Count  : Natural := 0;
      Rules  : Match_Vector;
      Levels : Level_Map := (others => True);
   end record;

end Porion.Logs.Analysis;
