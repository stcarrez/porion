-----------------------------------------------------------------------
--  porion-tools -- Toolbox for porion
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
with Ada.Strings.Unbounded;
with Util.Log.Loggers;
with Util.Beans.Objects;
with Util.Processes;
with Util.Streams;
with Util.Streams.Texts;
with EL.Contexts.Default;
with EL.Contexts.Properties;
package body Porion.Tools is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Tools");

   --  ------------------------------
   --  Return a string formed by a concatenation of strings in the vector.
   --  ------------------------------
   function To_String (Args : in Util.Strings.Vectors.Vector) return String is
      use Ada.Strings.Unbounded;

      Result : UString;
      Empty  : Boolean := True;
   begin
      for Arg of Args loop
         if not Empty then
            Append (Result, " ");
         end if;
         Append (Result, Arg);
         Empty := False;
      end loop;
      return To_String (Result);
   end To_String;

   procedure Execute (Command     : in EL.Expressions.Expression;
                      Parameters  : in Util.Properties.Manager;
                      Process     : not null access procedure (Line : in String);
                      Working_Dir : in String := "";
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer) is
      Prop_Resolver : aliased EL.Contexts.Properties.Property_Resolver;
      Ctx           : EL.Contexts.Default.Default_Context;
   begin
      Prop_Resolver.Set_Properties (Parameters);
      Ctx.Set_Resolver (Prop_Resolver'Unchecked_Access);
      declare
         Cmd     : constant Util.Beans.Objects.Object := Command.Get_Value (Ctx);
         Command : constant String := Util.Beans.Objects.To_String (Cmd);
         Proc    : Util.Processes.Process;
         Output  : Util.Streams.Input_Stream_Access;
         Input   : Util.Streams.Output_Stream_Access;
         Reader  : Util.Streams.Texts.Reader_Stream;
      begin
         if Working_Dir'Length > 0 then
            Log.Info ("Running '{0}' in '{1}'", Command, Working_Dir);
            Util.Processes.Set_Working_Directory (Proc, Working_Dir);
         else
            Log.Info ("Running '{0}'", Command);
         end if;

         Util.Processes.Spawn (Proc    => Proc,
                               Command => Command,
                               Mode    => Util.Processes.READ_WRITE_ALL);
         Input := Util.Processes.Get_Input_Stream (Proc);
         Output := Util.Processes.Get_Output_Stream (Proc);
         Reader.Initialize (Output, 4096);
         Input.Close;
         while not Reader.Is_Eof loop
            declare
               Line : Ada.Strings.Unbounded.Unbounded_String;
            begin
               Reader.Read_Line (Line, Strip_Crlf);
               Process (Ada.Strings.Unbounded.To_String (Line));
            end;
         end loop;
         Util.Processes.Wait (Proc);
         Status := Util.Processes.Get_Exit_Status (Proc);
         if Status /= 0 then
            Log.Warn ("Command '{0}' terminated with exit code{1}", Command,
                      Integer'Image (Status));
         end if;
      end;
   end Execute;

end Porion.Tools;
