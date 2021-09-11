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
with Porion.Configs;
private with EL.Expressions;
package Porion.Sources.Files is

   TAR_CONFIG_NAME         : constant String := "files-tar";
   TAR_GZ_CONFIG_NAME      : constant String := "files-tar.gz";
   TAR_BZ2_CONFIG_NAME     : constant String := "files-tar.bz2";
   TAR_XZ_CONFIG_NAME      : constant String := "files-tar.xz";
   ZIP_CONFIG_NAME         : constant String := "files-zip";
   GUESS_CONFIG_NAME       : constant String := "guess";
   EXTRACT_CONFIG_NAME     : constant String := "extract";

   TAR_EXTRACT_COMMAND     : constant String := "tar xf #{repository_url}";
   TAR_GUESS_COMMAND       : constant String := "tar tvf #{path}";

   TAR_GZ_EXTRACT_COMMAND  : constant String := "tar xzf #{repository_url}";
   TAR_GZ_GUESS_COMMAND    : constant String := "tar tzvf #{path}";

   TAR_BZ2_EXTRACT_COMMAND : constant String := "tar xzf #{repository_url}";
   TAR_BZ2_GUESS_COMMAND   : constant String := "tar tzvf #{path}";

   TAR_XZ_EXTRACT_COMMAND  : constant String := "tar xzf #{repository_url}";
   TAR_XZ_GUESS_COMMAND    : constant String := "tar tzvf #{path}";

   ZIP_EXTRACT_COMMAND     : constant String := "unzip #{repository_url}";
   ZIP_GUESS_COMMAND       : constant String := "zipinfo #{path}";

   type File_Type is (UNKNOWN, PLAIN, TAR, TAR_GZ, TAR_BZ2, TAR_XZ, ZIP);

   --  Guess the file type for the given file based on the file name extension.
   function Get_File_Type (Path : in String) return File_Type;

   type Controller_Type is limited new Porion.Sources.Controller_Type with private;

   overriding
   procedure Check (Controller : in out Controller_Type;
                    Status     : out Status_Type;
                    Executor   : in out Porion.Executors.Executor_Type'Class);

   overriding
   procedure Checkout (Controller : in out Controller_Type;
                       Path       : in String;
                       Executor   : in out Porion.Executors.Executor_Type'Class);

   overriding
   procedure Changes (Controller : in out Controller_Type;
                      Result     : out Status_Type;
                      Executor   : in out Porion.Executors.Executor_Type'Class);

   --  Guess some information about the sources located in the given directory.
   --  The source controller tries to find if it can manage the files at the given location
   --  and provides information on how to manage those files.
   overriding
   procedure Guess (Controller : in out Controller_Type;
                    Path       : in String;
                    Result     : out Source_Info_Type;
                    Executor   : in out Porion.Executors.Executor_Type'Class);

   function Create (Config : in Porion.Configs.Config_Type) return Controller_Access;

private

   type Controller_Type is limited new Porion.Sources.Controller_Type with record
      Config           : Porion.Configs.Config_Type;
      Extract_Command  : EL.Expressions.Expression;
      Guess_Command    : EL.Expressions.Expression;
   end record;

   procedure Setup (Controller : in out Controller_Type;
                    Kind       : in File_Type);

   type Files_Controller_Access is access all Controller_Type'Class;

end Porion.Sources.Files;
