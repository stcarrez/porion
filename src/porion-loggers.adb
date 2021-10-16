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
with Ada.Directories;

with Util.Files;
package body Porion.Loggers is

   --  Create and open the logger to write on the given path.
   procedure Create (Logger : in out Logger_Type;
                     Path   : in String) is
   begin
      if Ada.Text_IO.Is_Open (Logger.File) then
         Ada.Text_IO.Close (Logger.File);
      end if;
      Ada.Text_IO.Create (File => Logger.File,
                          Mode => Ada.Text_IO.Out_File,
                          Name => Path);
   end Create;

   procedure Create (Logger : in out Logger_Type;
                     Dir    : in String;
                     Name   : in String) is
   begin
      if not Ada.Directories.Exists (Dir) then
         Ada.Directories.Create_Path (Dir);
      end if;
      if Ada.Text_IO.Is_Open (Logger.File) then
         Ada.Text_IO.Close (Logger.File);
      end if;
      Logger.Create (Util.Files.Compose (Dir, Name));
   end Create;

   --  Write the line on the logger.
   procedure Write (Logger : in out Logger_Type;
                    Line   : in String) is
   begin
      if Ada.Text_IO.Is_Open (Logger.File) then
         Ada.Text_IO.Put_Line (Logger.File, Line);
      end if;
   end Write;

   overriding
   procedure Finalize (Logger : in out Logger_Type) is
   begin
      if Ada.Text_IO.Is_Open (Logger.File) then
         Ada.Text_IO.Close (Logger.File);
      end if;
   end Finalize;

end Porion.Loggers;
