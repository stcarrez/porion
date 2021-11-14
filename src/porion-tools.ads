-----------------------------------------------------------------------
--  porion-tools -- Toolbox for porion
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
with Util.Properties;
with EL.Expressions;
with Util.Strings.Vectors;
package Porion.Tools is

   subtype File_Size is Ada.Directories.File_Size;

   type Tree_Stat_Type is record
      File_Count : Natural := 0;
      Dir_Count  : Natural := 0;
      Total_Size : File_Size := 0;
   end record;

   --  Find statistics about the directory tree.
   procedure Find_Stats (Path  : in String;
                         Stats : in out Tree_Stat_Type);

   --  Return a string formed by a concatenation of strings in the vector.
   function To_String (Args : in Util.Strings.Vectors.Vector) return String;

   procedure Execute (Command     : in EL.Expressions.Expression;
                      Parameters  : in Util.Properties.Manager;
                      Process     : not null access procedure (Line : in String);
                      Working_Dir : in String := "";
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer);

end Porion.Tools;
