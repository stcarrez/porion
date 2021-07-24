-----------------------------------------------------------------------
--  porion-builders -- Continuous integration controller
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
with Util.Log.Loggers;
with Util.Strings.Vectors;
with Porion.Tools;
with EL.Expressions;
with EL.Contexts.Default;
package body Porion.Builders.Scripts is

   --  The logger
   Log   : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builders.Scripts");

   overriding
   procedure Build (Controller : in out Controller_Type;
                    Logger     : in out Porion.Loggers.Logger_Type) is
      procedure Process (Line : in String) is
      begin
         if Line'First + 1 < Line'Last then
            Log.Info ("{0}", Line (Line'First .. Line'Last - 1));
         end if;
         Logger.Write (Line (Line'First .. Line'Last - 1));
      end Process;
   begin
      Porion.Tools.Execute (Controller.Configure_Command, Controller.Config, Process'Access);
      Porion.Tools.Execute (Controller.Build_Command, Controller.Config, Process'Access);
   end Build;

   overriding
   procedure Clean (Controller : in out Controller_Type) is
   begin
      null;
   end Clean;

   function Create (Config : in Porion.Configs.Config_Type) return Controller_Access is
      Ctx        : EL.Contexts.Default.Default_Context;
      Configure  : constant String := Porion.Configs.Get ("command_configure", "cd #{build_dir} && ./configure");
      Build      : constant String := Porion.Configs.Get ("command_build", "make -C #{build_dir}");
      Controller : constant Script_Controller_Access := new Controller_Type;
   begin
      Controller.Configure_Command := EL.Expressions.Create_Expression (Configure, Ctx);
      Controller.Build_Command := EL.Expressions.Create_Expression (Build, Ctx);
      Controller.Config := Config;
      return Controller.all'Access;
   end Create;

end Porion.Builders.Scripts;
