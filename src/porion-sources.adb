-----------------------------------------------------------------------
--  porion-sources -- Source management
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
with Ada.Unchecked_Deallocation;
with Porion.Sources.Factories;
package body Porion.Sources is

   procedure Free is
      new Ada.Unchecked_Deallocation (Object => Controller_Type'Class,
                                      Name   => Controller_Access);

   --  ------------------------------
   --  Check for changes in the project by using the executor.
   --  The source control parameters are configured in Config.
   --  ------------------------------
   procedure Check (Kind      : in Source_Control_Type;
                    Config    : in Porion.Configs.Config_Type;
                    Status    : out Status_Type;
                    Executor  : in out Porion.Executors.Executor_Type'Class) is
      Controller : Controller_Access := Factories.Create (Kind, Config);
   begin
      Controller.Check (Status, Executor);
      Free (Controller);
   end Check;

   --  ------------------------------
   --  Checkout the source of the project by using the executor.
   --  The checkout parameters are configured in Config and the
   --  files are extracted in the Path directory (possibly on a remote host).
   --  ------------------------------
   procedure Checkout (Kind     : in Source_Control_Type;
                       Config   : in Porion.Configs.Config_Type;
                       Path     : in String;
                       Result   : out UString;
                       Executor : in out Porion.Executors.Executor_Type'Class) is
      Controller : Controller_Access := Factories.Create (Kind, Config);
   begin
      Controller.Checkout (Path, Result, Executor);
      Free (Controller);
   end Checkout;

   --  ------------------------------
   --  Checkout the source of the project by using the executor.
   --  The checkout parameters are configured in Config and the
   --  files are extracted in the Path directory (possibly on a remote host).
   --  ------------------------------
   procedure Checkout (Kind       : in Source_Control_Type;
                       Config     : in Porion.Configs.Config_Type;
                       Extraction : in out Checkout_Type;
                       Executor   : in out Porion.Executors.Executor_Type'Class) is
      Controller : Controller_Access := Factories.Create (Kind, Config);
      Result     : UString;
   begin
      Controller.Checkout (To_String (Extraction.Path), Result, Executor);
      if Length (Result) > 0 then
         Extraction.Path := Result;
      end if;
      Controller.Changes (To_String (Extraction.Path), Extraction, Executor);
      Free (Controller);
   end Checkout;

   --  ------------------------------
   --  Guess some information about the sources located in the given directory.
   --  The source controller tries to find if it can manage the files at the given location
   --  and provides information on how to manage those files.
   --  ------------------------------
   procedure Guess (Path       : in String;
                    Config     : in Porion.Configs.Config_Type;
                    Result     : out Source_Info_Type;
                    Executor   : in out Porion.Executors.Executor_Type'Class) is
      Log_Dir : constant String := Porion.Configs.Get_Default_Log_Directory;
   begin
      Executor.Create_Logger (Log_Dir, "guess.log");
      for Kind in SRC_GIT .. SRC_FILE loop
         declare
            C : Controller_Access := Factories.Create (Kind, Config);
         begin
            Result.Kind := SRC_UNKNOWN;
            C.Guess (Path     => Path,
                     Result   => Result,
                     Executor => Executor);
            Free (C);
            exit when Result.Kind = Kind;
         end;
      end loop;
   end Guess;

end Porion.Sources;
