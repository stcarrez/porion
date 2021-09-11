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
with Porion.Configs;
private with EL.Expressions;
package Porion.Sources.Git is

   GIT_TEST_COMMAND        : constant String := "git ls-remote -h -- #{repository_url}";
   GIT_SHOW_REMOTE_COMMAND : constant String := "git remote show #{repository_url}";
   GIT_CHECKOUT_COMMAND    : constant String := "git clone #{repository_url} #{build_dir}";
   GIT_GUESS_COMMAND       : constant String := "git -C #{path} config remote.origin.url";

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
      Config              : Porion.Configs.Config_Type;
      Check_Command       : EL.Expressions.Expression;
      Checkout_Command    : EL.Expressions.Expression;
      Guess_Command       : EL.Expressions.Expression;
      Show_Remote_Command : EL.Expressions.Expression;
   end record;

   type Git_Controller_Access is access all Controller_Type'Class;

end Porion.Sources.Git;
