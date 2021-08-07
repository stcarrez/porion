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

with GNAT.Regpat;
with Porion.Tools;
with EL.Contexts.Default;
package body Porion.Sources.Files is

   use Ada.Directories;

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
      if Sep > Path'Last then
         return UNKNOWN;
      end if;
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
      return UNKNOWN;
   end Get_File_Type;

   overriding
   procedure Check (Controller : in out Controller_Type;
                    Status     : out Status_Type;
                    Logger     : in out Porion.Loggers.Logger_Type) is
      procedure Process (Line : in String);

      REGEX1 : constant String := "^([0-9a-fA-F]+)\srefs/heads/(.*)";

      Pattern1 : constant GNAT.Regpat.Pattern_Matcher := GNAT.Regpat.Compile (REGEX1);

      procedure Process (Line : in String) is
         Matches : GNAT.Regpat.Match_Array (0 .. 2);
      begin
         Logger.Write (Line);
         if GNAT.Regpat.Match (Pattern1, Line) then
            GNAT.Regpat.Match (Pattern1, Line, Matches);
            declare
               Info : Branch_Type;
            begin
               Info.Tag := To_UString (Line (Matches (1).First .. Matches (1).Last));
               Status.Changes.Include (Line (Matches (2).First .. Matches (2).Last), Info);
            end;
         end if;
      end Process;

      Result : Integer;
   begin
      Status.Check_Date := Ada.Calendar.Clock;
   end Check;

   overriding
   procedure Checkout (Controller : in out Controller_Type;
                       Path       : in String;
                       Logger     : in out Porion.Loggers.Logger_Type) is
      procedure Process (Line : in String);

      procedure Process (Line : in String) is
      begin
         Logger.Write (Line);
      end Process;

      Status : Integer;
   begin
      Controller.Config.Set ("build_dir", Path);
      Porion.Tools.Execute (Controller.Extract_Command, Controller.Config,
                            Process'Access, Strip_Crlf => False, Status => Status);
   end Checkout;

   overriding
   procedure Changes (Controller : in out Controller_Type;
                      Result     : out Status_Type;
                      Logger     : in out Porion.Loggers.Logger_Type) is
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
                    Logger     : in out Porion.Loggers.Logger_Type) is
      function Make_Project_Name (URI : in String) return String;
      procedure Process (Line : in String);

      function Make_Project_Name (URI : in String) return String is
         Last : Natural := Util.Strings.Rindex (URI, '/');
      begin
         if Last > 0 then
            return Make_Project_Name (URI (Last + 1 .. URI'Last));
         end if;

         Last := Util.Strings.Rindex (URI, '.');
         if Last > 0 then
            if Util.Strings.Ends_With (URI, ".git") then
               return URI (URI'First .. Last - 1);
            end if;

            return URI (URI'First .. Last - 1);
         end if;

         return URI;
      end Make_Project_Name;

      procedure Process (Line : in String) is
      begin
         if Line'Length > 0 then
            Result.URI := To_UString (Line);
            Result.Name := To_UString (Make_Project_Name (Line));
         end if;
         Logger.Write (Line);
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
      Porion.Tools.Execute (Controller.Guess_Command, Controller.Config,
                            Process'Access, Strip_Crlf => True, Status => Status);
      if Status = 0 then
         Result.URI := To_UString (Path);
         Result.Kind := To_UString (SOURCE_KIND);
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
