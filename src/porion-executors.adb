-----------------------------------------------------------------------
--  porion-executors -- Execute commands for builders or source controllers
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
with EL.Contexts.Properties;
with EL.Contexts.Default;
with Util.Processes;
with Util.Log.Loggers;
with Util.Streams;
with Util.Streams.Texts;
with Util.Beans.Objects;
with Ada.Text_IO;
package body Porion.Executors is

   Glog : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Executors");

   --  ------------------------------
   --  Returns true if commands are not executed but collected.
   --  ------------------------------
   function Is_Dry_Run (Executor : in Executor_Type) return Boolean is
   begin
      return Executor.Dry_Run;
   end Is_Dry_Run;

   --  ------------------------------
   --  Enable the dry run execution mode.
   --  ------------------------------
   procedure Enable_Dry_Run (Executor : in out Executor_Type) is
   begin
      Executor.Dry_Run := True;
   end Enable_Dry_Run;

   --  ------------------------------
   --  Enable writing command output to stdout.
   --  ------------------------------
   procedure Enable_Log (Executor : in out Executor_Type) is
   begin
      Executor.Output_Log := True;
   end Enable_Log;

   --  ------------------------------
   --  Get the execution status.
   --  ------------------------------
   function Get_Status (Executor : in Executor_Type) return Integer is
   begin
      return Executor.Status;
   end Get_Status;

   --  ------------------------------
   --  Set the execution status.
   --  ------------------------------
   procedure Set_Status (Executor : in out Executor_Type;
                         Status   : in Integer) is
   begin
      Executor.Status := Status;
   end Set_Status;

   --  ------------------------------
   --  Set the current execution step when building a project.
   --  ------------------------------
   procedure Set_Step (Executor : in out Executor_Type;
                       Step     : in Porion.Builds.Step_Type) is
   begin
      Executor.Step := Step;
   end Set_Step;

   procedure Execute (Executor    : in out Executor_Type;
                      Command     : in EL.Expressions.Expression;
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
      begin
         if Executor.Dry_Run then
            Status := 0;
            Executor.Commands.Append (Command);
            return;
         end if;

         Executor_Type'Class (Executor).Execute (Command, Process, Working_Dir,
                                                 Strip_Crlf, Status);
      end;
   end Execute;

   procedure Execute (Executor    : in out Executor_Type;
                      Command     : in EL.Expressions.Expression;
                      Parameters  : in Util.Properties.Manager;
                      Working_Dir : in String := "";
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer) is
      procedure Process (Line : in String);

      procedure Process (Line : in String) is
      begin
         if Line'First + 1 < Line'Last then
            Glog.Info ("{0}", Line (Line'First .. Line'Last - 1));
         end if;
         Executor_Type'Class (Executor).Log (Line (Line'First .. Line'Last - 1));
      end Process;

   begin
      Executor_Type'Class (Executor).Execute (Command, Parameters, Process'Access,
                                              Working_Dir, Strip_Crlf, Status);
   end Execute;
   procedure Execute (Executor    : in out Executor_Type;
                      Command     : in String;
                      Process     : not null access procedure (Line : in String);
                      Working_Dir : in String := "";
                      Strip_Crlf  : in Boolean := False;
                      Status      : out Integer) is
      Proc    : Util.Processes.Process;
      Output  : Util.Streams.Input_Stream_Access;
      Input   : Util.Streams.Output_Stream_Access;
      Reader  : Util.Streams.Texts.Reader_Stream;
   begin
      if Working_Dir'Length > 0 then
         Glog.Info ("Running '{0}' in '{1}'", Command, Working_Dir);
         Util.Processes.Set_Working_Directory (Proc, Working_Dir);
      else
         Glog.Info ("Running '{0}'", Command);
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
         Glog.Warn ("Command '{0}' terminated with exit code{1}", Command,
                    Integer'Image (Status));
         Executor.Log ("Command exit status:" & Integer'Image (Status) & ASCII.LF);
         Executor.Status := Status;
      end if;
   end Execute;

   procedure Create_Logger (Executor : in out Executor_Type;
                            Dir      : in String;
                            Name     : in String) is
   begin
      if not Executor.Dry_Run then
         Executor.Logger.Create (Dir, Name);
      end if;
   end Create_Logger;

   --  ------------------------------
   --  Get the commands that were collected during execution and clear the current list.
   --  ------------------------------
   procedure Fetch_Commands (Executor : in out Executor_Type;
                             Commands : out Util.Strings.Vectors.Vector) is
   begin
      Commands := Executor.Commands;
      Executor.Commands.Clear;
   end Fetch_Commands;

   --  ------------------------------
   --  Write the line on the logger.
   --  ------------------------------
   procedure Log (Executor : in out Executor_Type;
                  Line     : in String) is
      use type Porion.Builds.Step_Type;
   begin
      Executor.Logger.Write (Line);
      if Executor.Output_Log and Executor.Step /= Porion.Builds.STEP_CHECKOUT then
         Ada.Text_IO.Put_Line (Line);
      end if;
   end Log;

end Porion.Executors;
