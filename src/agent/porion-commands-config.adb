-----------------------------------------------------------------------
--  porion-commands-config -- Config command to configure porion
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
package body Porion.Commands.Config is

   --  ------------------------------
   --  Get a value from the keystore.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Command);
   begin
      if Args.Get_Count = 0 then
         Porion.Commands.Log.Error (-("missing configuration variable to get or set"));

      elsif Args.Get_Count = 2 then
         declare
            Name  : constant String := Args.Get_Argument (1);
            Value : constant String := Args.Get_Argument (2);
         begin
            Porion.Configs.Set (Name, Value);
         end;
         Porion.Configs.Save;
      end if;
   end Execute;

end Porion.Commands.Config;
