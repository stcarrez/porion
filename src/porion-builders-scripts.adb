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
with Porion.Tools;
with EL.Contexts.Default;
package body Porion.Builders.Scripts is

   --  The logger
   Log   : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builders.Scripts");

   overriding
   procedure Build (Controller : in out Controller_Type;
                    Build      : in out Porion.Builds.Models.Build_Ref;
                    Path       : in String;
                    Logger     : in out Porion.Loggers.Logger_Type) is
      procedure Process (Line : in String);

      procedure Process (Line : in String) is
      begin
         if Line'First + 1 < Line'Last then
            Log.Info ("{0}", Line (Line'First .. Line'Last - 1));
         end if;
         Logger.Write (Line (Line'First .. Line'Last - 1));
      end Process;

      Status : Integer;
   begin
      Porion.Tools.Execute (Command     => Controller.Command,
                            Parameters  => Controller.Config,
                            Process     => Process'Access,
                            Working_Dir => Path,
                            Strip_Crlf  => False,
                            Status      => Status);
   end Build;

   overriding
   procedure Clean (Controller : in out Controller_Type) is
   begin
      null;
   end Clean;

   overriding
   procedure Configure (Controller : in out Controller_Type;
                        Parameters : in Util.Strings.Vectors.Vector) is
      use Ada.Strings.Unbounded;

      Ctx     : EL.Contexts.Default.Default_Context;
      Command : UString;
   begin
      for Param of Parameters loop
         if Length (Command) > 0 then
            Append (Command, " ");
         end if;
         Append (Command, Param);
      end loop;
      Controller.Command := EL.Expressions.Create_Expression (To_String (Command), Ctx);
   end Configure;

   overriding
   procedure Print (Controller : in out Controller_Type;
                    Stream     : in out Util.Serialize.IO.Output_Stream'Class) is
   begin
      Stream.Start_Entity ("");
      Stream.Write_Entity ("command", Controller.Command.Get_Expression);
      Stream.End_Entity ("");
   end Print;

   function Create (Config : in Porion.Configs.Config_Type) return Controller_Access is
      Ctx        : EL.Contexts.Default.Default_Context;
      Command    : constant String := Config.Get ("command", "");
      Controller : constant Script_Controller_Access := new Controller_Type;
   begin
      Controller.Command := EL.Expressions.Create_Expression (Command, Ctx);
      Controller.Config := Config;
      return Controller.all'Access;
   end Create;

end Porion.Builders.Scripts;
