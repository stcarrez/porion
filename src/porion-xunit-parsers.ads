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
with Util.Strings.Vectors;
with Util.Streams.Buffered;
with Porion.XUnit.Analysis;
package Porion.XUnit.Parsers is

   procedure Scan (Path    : in String;
                   Stream  : in out Util.Streams.Buffered.Input_Buffer_Stream'Class;
                   Results : in out Analysis.Test_Results);

   procedure Scan (Path    : in String;
                   Results : in out Porion.XUnit.Analysis.Test_Results);

   procedure Scan (Path    : in String;
                   Pattern : in String;
                   Exclude : in Util.Strings.Vectors.Vector;
                   Results : in out Porion.XUnit.Analysis.Test_Results);

end Porion.XUnit.Parsers;
