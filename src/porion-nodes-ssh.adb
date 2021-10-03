-----------------------------------------------------------------------
--  porion-nodes-ssh -- SSH build node management
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
with Ada.Characters.Handling;
with Util.Strings.Vectors;
with Porion.Configs;
with EL.Contexts.Default;
package body Porion.Nodes.SSH is

   package UBO renames Util.Beans.Objects;

   --  ------------------------------
   --  Create the controller for the management of the given build node.
   --  ------------------------------
   function Create (Node : in Models.Node_Ref) return Nodes.Controller_Access is
      Controller : constant Controller_Access := new Controller_Type;
      Cmd        : constant String := Configs.Get (SSH_COMMAND_NAME, SSH_COMMAND);
      Ctx        : EL.Contexts.Default.Default_Context;
   begin
      Controller.Hostname := Node.Get_Name;
      Controller.Login := Node.Get_Login;
      Controller.Command := EL.Expressions.Create_Expression (Cmd, Ctx);
      return Controller.all'Access;
   end Create;

   --  ------------------------------
   --  Execute the command in the working directory on the remote host through
   --  ssh and for each output line produced by the command call Process.
   --  ------------------------------
   overriding
   procedure Execute (Controller  : in out Controller_Type;
                      Command     : in String;
                      Working_Dir : in String := "";
                      Process     : not null access procedure (Line : in String);
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer) is

      function Is_Space (C : in Character) return Boolean renames
        Ada.Characters.Handling.Is_Space;

      Props : aliased EL.Contexts.Default.Default_ELResolver;
      Ctx   : EL.Contexts.Default.Default_Context;
   begin
      Props.Register (To_UString ("login"), UBO.To_Object (Controller.Login));
      Props.Register (To_UString ("hostname"), UBO.To_Object (Controller.Hostname));
      Props.Register (To_UString ("identity"), UBO.To_Object (Controller.Identity));
      Ctx.Set_Resolver (Props'Unchecked_Access);
      declare
         Cmd   : constant UBO.Object := Controller.Command.Get_Value (Ctx);
         Ssh   : constant String := UBO.To_String (Cmd);
         Args  : Util.Strings.Vectors.Vector;
         First : Natural := Ssh'First;
         Pos   : Natural := First;
      begin
         loop
            while First <= Ssh'Last and then Is_Space (Ssh (First)) loop
               First := First + 1;
            end loop;
            exit when First > Ssh'Last;
            Pos := First;
            while Pos <= Ssh'Last and then not Is_Space (Ssh (Pos)) loop
               Pos := Pos + 1;
            end loop;
            Args.Append (Ssh (First .. Pos - 1));
            First := Pos;
         end loop;
         Args.Append (Command);
         Controller.Execute (Args, Working_Dir, Process, Strip_Crlf, Status);
      end;
   end Execute;

end Porion.Nodes.SSH;
