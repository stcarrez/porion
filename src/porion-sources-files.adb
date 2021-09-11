-----------------------------------------------------------------------
--  porion-sources-files -- Source management with plain files
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
with Interfaces.C.Strings;
with Util.Log.Loggers;
with Util.Strings;
with EL.Contexts.Default;
package body Porion.Sources.Files is

   use Ada.Directories;

   Log   : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Sources.Files");

   function Realpath (Path : in String) return String;
   function Make_Project_Name (Path : in String;
                               Kind : in File_Type) return String;

   function Realpath (Path : in String) return String is
      use Interfaces;

      function Sys_Realpath (S : C.Strings.chars_ptr;
                             R : C.Strings.chars_ptr) return C.Strings.chars_ptr with
        Import => True, Convention => C, Link_Name => "realpath";
      P : C.Strings.chars_ptr := C.Strings.New_String (Path);
      R : C.Strings.chars_ptr;
   begin
      R := Sys_Realpath (P, C.Strings.Null_Ptr);
      C.Strings.Free (P);
      declare
         Result : constant String := C.Strings.Value (R);
      begin
         C.Strings.Free (R);
         return Result;
      end;
   end Realpath;

   --  ------------------------------
   --  Guess the file type for the given file based on the file name extension.
   --  ------------------------------
   function Get_File_Type (Path : in String) return File_Type is
      Sep : Natural := Path'Last + 1;
   begin
      for Pos in reverse Path'Range loop
         exit when Path (Pos) = '/' or Path (Pos) = '\';
         if Path (Pos) = '.' then
            Sep := Pos;
         end if;
      end loop;
      if Sep >= Path'Last then
         return UNKNOWN;
      end if;

      --  Repeat the extension test to handle some '.' in the name (ex: gcc-10.1.2.tar).
      while Sep < Path'Last loop
         if Path (Sep .. Path'Last) = ".tar.gz" then
            return TAR_GZ;
         end if;
         if Path (Sep .. Path'Last) = ".tar.xz" then
            return TAR_XZ;
         end if;
         if Path (Sep .. Path'Last) = ".tar.bz2" then
            return TAR_BZ2;
         end if;
         if Path (Sep .. Path'Last) = ".tar" then
            return TAR;
         end if;
         if Path (Sep .. Path'Last) = ".zip" then
            return ZIP;
         end if;

         --  Move to the next '.'.
         Sep := Sep + 1;
         while Sep < Path'Last and then Path (Sep) /= '.' loop
            Sep := Sep + 1;
         end loop;
      end loop;
      return UNKNOWN;
   end Get_File_Type;

   function Make_Project_Name (Path : in String;
                               Kind : in File_Type) return String is
      First : Natural := Util.Strings.Rindex (Path, '/');
      Last  : Natural;
   begin
      if First > 0 then
         First := First + 1;
      else
         First := Path'First;
      end if;

      Last := Util.Strings.Rindex (Path, '.');
      if Last = 0 then
         return Path (First .. Path'Last);
      end if;

      case Kind is
         when TAR | ZIP =>
            return Path (First .. Last - 1);

         when TAR_GZ | TAR_BZ2 | TAR_XZ =>
            Last := Util.Strings.Rindex (Path, '.', Last - 1);
            return Path (First .. Last - 1);

         when others =>
            return Path (First .. Last - 1);

      end case;
   end Make_Project_Name;

   overriding
   procedure Check (Controller : in out Controller_Type;
                    Status     : out Status_Type;
                    Executor   : in out Porion.Executors.Executor_Type'Class) is
      Info   : Branch_Type;
      Path   : constant String := Controller.Config.Get ("repository_url");
   begin
      Log.Info ("Checking changes on '{0}'", Path);

      if Ada.Directories.Exists (Path) then
         Info.Last_Date := Ada.Directories.Modification_Time (Path);
         Info.Tag := To_UString ("main");
         Status.Head := Info.Tag;
         Status.Changes.Include ("main", Info);
      else
         Log.Warn ("Source file '{0}' does not exist anymore", Path);
      end if;
      Status.Check_Date := Ada.Calendar.Clock;
   end Check;

   overriding
   procedure Checkout (Controller : in out Controller_Type;
                       Path       : in String;
                       Executor   : in out Porion.Executors.Executor_Type'Class) is
      Status   : Integer;
      Src_Path : constant String := Controller.Config.Get ("repository_url");
      Kind     : constant File_Type := Get_File_Type (Src_Path);
   begin
      Log.Info ("Extracting files from '{0}' to '{1}'", Src_Path, Path);

      Controller.Setup (Kind);
      Controller.Config.Set ("build_dir", Path);
      Executor.Execute (Command     => Controller.Extract_Command,
                        Parameters  => Controller.Config,
                        Working_Dir => Path,
                        Strip_Crlf  => False,
                        Status      => Status);
   end Checkout;

   overriding
   procedure Changes (Controller : in out Controller_Type;
                      Result     : out Status_Type;
                      Executor   : in out Porion.Executors.Executor_Type'Class) is
   begin
      null;
   end Changes;

   --  ------------------------------
   --  Guess some information about the sources located in the given directory.
   --  The source controller tries to find if it can manage the files at the given location
   --  and provides information on how to manage those files.
   --  ------------------------------
   overriding
   procedure Guess (Controller : in out Controller_Type;
                    Path       : in String;
                    Result     : out Source_Info_Type;
                    Executor   : in out Porion.Executors.Executor_Type'Class) is

      procedure Process (Line : in String);

      procedure Process (Line : in String) is
      begin
         if Line'Length > 0 then
            Result.URI := To_UString (Line);
         end if;
         Executor.Log (Line);
      end Process;

      Status : Integer;
      Kind   : constant File_Type := Get_File_Type (Path);
   begin
      if Kind = UNKNOWN then
         return;
      end if;
      if not Ada.Directories.Exists (Path) then
         return;
      end if;
      if Ada.Directories.Kind (Path) /= Ada.Directories.Ordinary_File then
         return;
      end if;

      --  Run git config remote.origin.url to find out the git repository.
      Controller.Config.Set ("path", Path);
      Controller.Setup (Kind);
      Executor.Execute (Controller.Guess_Command, Controller.Config,
                        Process'Access, Strip_Crlf => True, Status => Status);
      if Status = 0 then
         Result.URI := To_UString (Realpath (Path));
         Result.Name := To_UString (Make_Project_Name (Path, Kind));
         Result.Kind := SRC_FILE;
      end if;
   end Guess;

   procedure Setup (Controller : in out Controller_Type;
                    Kind       : in File_Type) is

      function Get_Command (Name    : in String;
                            Default : in String) return EL.Expressions.Expression;

      Config : Configs.Config_Type;
      Ctx    : EL.Contexts.Default.Default_Context;

      function Get_Command (Name    : in String;
                            Default : in String) return EL.Expressions.Expression is
         Command : constant String := Config.Get (Name, Default);
      begin
         return EL.Expressions.Create_Expression (Command, Ctx);
      end Get_Command;

   begin
      Log.Info ("Configure files source controller for {0}", File_Type'Image (Kind));

      case Kind is
         when TAR =>
            Config := Porion.Configs.Get_Config (TAR_CONFIG_NAME);
            Controller.Guess_Command := Get_Command (GUESS_CONFIG_NAME,
                                                     TAR_GUESS_COMMAND);
            Controller.Extract_Command := Get_Command (EXTRACT_CONFIG_NAME,
                                                       TAR_EXTRACT_COMMAND);

         when TAR_GZ =>
            Config := Porion.Configs.Get_Config (TAR_GZ_CONFIG_NAME);
            Controller.Guess_Command := Get_Command (GUESS_CONFIG_NAME,
                                                     TAR_GZ_GUESS_COMMAND);
            Controller.Extract_Command := Get_Command (EXTRACT_CONFIG_NAME,
                                                       TAR_GZ_EXTRACT_COMMAND);

         when TAR_BZ2 =>
            Config := Porion.Configs.Get_Config (TAR_BZ2_CONFIG_NAME);
            Controller.Guess_Command := Get_Command (GUESS_CONFIG_NAME,
                                                     TAR_BZ2_GUESS_COMMAND);
            Controller.Extract_Command := Get_Command (EXTRACT_CONFIG_NAME,
                                                       TAR_BZ2_EXTRACT_COMMAND);

         when TAR_XZ =>
            Config := Porion.Configs.Get_Config (TAR_XZ_CONFIG_NAME);
            Controller.Guess_Command := Get_Command (GUESS_CONFIG_NAME,
                                                     TAR_XZ_GUESS_COMMAND);
            Controller.Extract_Command := Get_Command (EXTRACT_CONFIG_NAME,
                                                       TAR_XZ_EXTRACT_COMMAND);

         when ZIP =>
            Config := Porion.Configs.Get_Config (ZIP_CONFIG_NAME);
            Controller.Guess_Command := Get_Command (GUESS_CONFIG_NAME,
                                                     ZIP_GUESS_COMMAND);
            Controller.Extract_Command := Get_Command (EXTRACT_CONFIG_NAME,
                                                       ZIP_EXTRACT_COMMAND);

         when others =>
            return;
      end case;
   end Setup;

   function Create (Config : in Porion.Configs.Config_Type) return Controller_Access is
      Controller : constant Files_Controller_Access := new Controller_Type;
   begin
      Controller.Config := Config;
      return Controller.all'Access;
   end Create;

end Porion.Sources.Files;
