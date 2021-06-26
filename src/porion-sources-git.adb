-----------------------------------------------------------------------
--  porion-sources -- Continuous integration controller
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
with GNAT.Regpat;
with Porion.Tools;
with EL.Contexts.Default;
package body Porion.Sources.Git is

   overriding
   procedure Check (Controller : in out Controller_Type;
                    Status     : out Status_Type) is

      REGEX1 : constant String := "^([0-9a-fA-F]+)\srefs/heads/(.*)";

      Pattern1 : constant GNAT.Regpat.Pattern_Matcher := GNAT.Regpat.Compile (REGEX1);

      procedure Process (Line : in String) is
         Matches : GNAT.Regpat.Match_Array (0 .. 2);
      begin
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

   begin
      Status.Check_Date := Ada.Calendar.Clock;
      Porion.Tools.Execute (Controller.Check_Command, Controller.Config, Process'Access);
   end Check;

   overriding
   procedure Checkout (Controller : in out Controller_Type;
                       Path       : in String) is

      procedure Process (Line : in String) is
      begin
         null;
      end Process;

   begin
      Controller.Config.Set ("build_dir", Path);
      Porion.Tools.Execute (Controller.Checkout_Command, Controller.Config, Process'Access);
   end Checkout;

   overriding
   procedure Changes (Controller : in out Controller_Type;
                      Result     : out Status_Type) is
   begin
      null;
   end Changes;

   function Create (Config : in Porion.Configs.Config_Type) return Controller_Access is
      Ctx        : EL.Contexts.Default.Default_Context;
      Check      : constant String := Porion.Configs.Get ("command_check", GIT_TEST_COMMAND);
      Checkout   : constant String := Porion.Configs.Get ("command_checkout", GIT_CHECKOUT_COMMAND);
      Controller : constant Git_Controller_Access := new Controller_Type;
   begin
      Controller.Check_Command := EL.Expressions.Create_Expression (Check, Ctx);
      Controller.Checkout_Command := EL.Expressions.Create_Expression (Checkout, Ctx);
      Controller.Config := Config;
      return Controller.all'Access;
   end Create;

end Porion.Sources.Git;
