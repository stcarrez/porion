-----------------------------------------------------------------------
--  porion-logs -- Log build execution
--  Copyright (C) 2021 - 2026 Stephane Carrez
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
package body Porion.Logs is

   --  ------------------------------
   --  Returns true if this logger is opened and we can write on it.
   --  ------------------------------
   function Is_Opened (Logger : in Logger_Type) return Boolean is
   begin
      return Ada.Text_IO.Is_Open (Logger.File);
   end Is_Opened;

   --  ------------------------------
   --  Create and open the logger to write on the given path.
   --  ------------------------------
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

   --  ------------------------------
   --  Close the logger file.
   --  ------------------------------
   procedure Close (Logger : in out Logger_Type) is
   begin
      if Ada.Text_IO.Is_Open (Logger.File) then
         Ada.Text_IO.Close (Logger.File);
      end if;
   end Close;

   --  ------------------------------
   --  Write the line on the logger with the source to identify the producer.
   --  ------------------------------
   procedure Write (Logger : in out Logger_Type;
                    Source : in Source_Type;
                    Line   : in String) is
   begin
      if Ada.Text_IO.Is_Open (Logger.File) then
         case Source is
            when LOG_INFO =>
               Ada.Text_IO.Put (Logger.File, "porion:inf: ");

            when LOG_COMMAND =>
               Ada.Text_IO.Put (Logger.File, "porion:cmd: ");

            when LOG_ENVIRONMENT =>
               Ada.Text_IO.Put (Logger.File, "porion:env: ");

            when LOG_RESULT =>
               Ada.Text_IO.Put (Logger.File, "porion:oki: ");

            when LOG_FAILURE =>
               Ada.Text_IO.Put (Logger.File, "porion:nok: ");

            when LOG_STEP_INFO =>
               Ada.Text_IO.Put (Logger.File, "porion:step: ");

            when LOG_EXECUTION =>
               null;

            when LOG_EXECUTION_ERROR =>
               Ada.Text_IO.Put (Logger.File, "porion:error: ");

         end case;
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

end Porion.Logs;
