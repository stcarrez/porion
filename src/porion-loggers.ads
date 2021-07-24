-----------------------------------------------------------------------
--  porion-loggers -- Log build execution
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
private with Ada.Finalization;
private with Ada.Text_IO;
package Porion.Loggers is

   type Logger_Type is tagged limited private;

   --  Create an open the logger to write on the given path.
   procedure Create (Logger : in out Logger_Type;
                     Path   : in String);

   --  Write the line on the logger.
   procedure Write (Logger : in out Logger_Type;
                    Line   : in String);

private

   type Logger_Type is new Ada.Finalization.Limited_Controlled with record
      File : Ada.Text_IO.File_Type;
   end record;

   overriding
   procedure Finalize (Logger : in out Logger_Type);

end Porion.Loggers;
