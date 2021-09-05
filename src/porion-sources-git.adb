-----------------------------------------------------------------------
--  porion-sources-git -- Source management with git
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
with Util.Strings;
with Porion.Tools;
with EL.Contexts.Default;
package body Porion.Sources.Git is

   use Ada.Directories;

   overriding
   procedure Check (Controller : in out Controller_Type;
                    Status     : out Status_Type;
                    Logger     : in out Porion.Loggers.Logger_Type) is
      procedure Process (Line : in String);
      procedure Process_Show (Line : in String);

      REGEX1 : constant String := "^([0-9a-fA-F]+)\srefs/heads/(.*)";
      REGEX2 : constant String := "^ +HEAD branch: (.*)";

      Pattern1 : constant GNAT.Regpat.Pattern_Matcher := GNAT.Regpat.Compile (REGEX1);
      Pattern2 : constant GNAT.Regpat.Pattern_Matcher := GNAT.Regpat.Compile (REGEX2);

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

      procedure Process_Show (Line : in String) is
         Matches : GNAT.Regpat.Match_Array (0 .. 1);
      begin
         Logger.Write (Line);
         if GNAT.Regpat.Match (Pattern2, Line) then
            GNAT.Regpat.Match (Pattern2, Line, Matches);
            Status.Head := To_UString (Line (Matches (1).First .. Matches (1).Last));
         end if;
      end Process_Show;

      Result : Integer;
   begin
      Status.Check_Date := Ada.Calendar.Clock;
      Porion.Tools.Execute (Controller.Check_Command, Controller.Config,
                            Process'Access, Strip_Crlf => False, Status => Result);
      Porion.Tools.Execute (Controller.Show_Remote_Command, Controller.Config,
                            Process_Show'Access, Strip_Crlf => False, Status => Result);
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
      Porion.Tools.Execute (Controller.Checkout_Command, Controller.Config,
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
   begin
      --  Don't even try to run the git config command if the path is not a directory.
      if not Ada.Directories.Exists (Path) then
         if not Util.Strings.Ends_With (Path, ".git") then
            return;
         end if;
         Result.URI := To_UString (Path);
         Result.Name := To_UString (Make_Project_Name (Path));
         Result.Kind := SRC_GIT;
         return;
      end if;
      if Ada.Directories.Kind (Path) /= Ada.Directories.Directory then
         return;
      end if;

      --  Run git config remote.origin.url to find out the git repository.
      Controller.Config.Set ("path", Path);
      Porion.Tools.Execute (Controller.Guess_Command, Controller.Config,
                            Process'Access, Strip_Crlf => True, Status => Status);
      if Status = 0 then
         Result.Kind := SRC_GIT;
      end if;
   end Guess;

   function Create (Config : in Porion.Configs.Config_Type) return Controller_Access is
      Ctx        : EL.Contexts.Default.Default_Context;
      Check      : constant String := Configs.Get ("command_check", GIT_TEST_COMMAND);
      Checkout   : constant String := Configs.Get ("command_checkout", GIT_CHECKOUT_COMMAND);
      Guess      : constant String := Configs.Get ("command_guess", GIT_GUESS_COMMAND);
      Show       : constant String := Configs.Get ("command_show_remote", GIT_SHOW_REMOTE_COMMAND);
      Controller : constant Git_Controller_Access := new Controller_Type;
   begin
      Controller.Check_Command := EL.Expressions.Create_Expression (Check, Ctx);
      Controller.Checkout_Command := EL.Expressions.Create_Expression (Checkout, Ctx);
      Controller.Guess_Command := EL.Expressions.Create_Expression (Guess, Ctx);
      Controller.Show_Remote_Command := EL.Expressions.Create_Expression (Show, Ctx);
      Controller.Config := Config;
      return Controller.all'Access;
   end Create;

end Porion.Sources.Git;
