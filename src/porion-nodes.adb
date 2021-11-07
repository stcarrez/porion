-----------------------------------------------------------------------
--  porion-nodes -- Build node information and management
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

package body Porion.Nodes is

   --  ------------------------------
   --  Returns true if commands are not executed but collected.
   --  ------------------------------
   function Is_Dry_Run (Controller : in Controller_Type'Class) return Boolean is
   begin
      return Controller.Listener /= null and then Controller.Listener.Is_Dry_Run;
   end Is_Dry_Run;

   --  ------------------------------
   --  Record a command that is executed during the build step.
   --  The command is not executed but added to the list of commands.
   --  ------------------------------
   procedure Record_Command (Controller : in out Controller_Type'Class;
                             Command    : in String) is
   begin
      if Controller.Listener /= null then
         Controller.Listener.Record_Command (Command);
      end if;
   end Record_Command;

   --  ------------------------------
   --  Set the listener instance.
   --  ------------------------------
   procedure Set_Listener (Controller : in out Controller_Type'Class;
                           Listener   : in Listener_Access) is
   begin
      Controller.Listener := Listener;
   end Set_Listener;

   --  ------------------------------
   --  Return the usage identified when running commands on this build node.
   --  ------------------------------
   function Get_Usage (Controller : in Controller_Type'Class) return Usage_Type is
   begin
      return Controller.Usage;
   end Get_Usage;

end Porion.Nodes;
