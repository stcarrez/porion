-----------------------------------------------------------------------
--  porion-executors -- Execute commands for builders or source controllers
--  Copyright (C) 2021, 2022 Stephane Carrez
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
with Util.Log.Loggers;
with Util.Beans.Objects;
with Ada.Text_IO;
with Porion.Nodes.Services;
package body Porion.Executors is

   use type Porion.Nodes.Controller_Access;

   Glog : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Executors");

   --  ------------------------------
   --  Returns true if commands are not executed but collected.
   --  ------------------------------
   function Is_Dry_Run (Executor : in Executor_Type) return Boolean is
   begin
      return Executor.Dry_Run;
   end Is_Dry_Run;

   --  ------------------------------
   --  Returns true if this executor is configured and can be used.
   --  ------------------------------
   function Is_Configured (Executor : in Executor_Type) return Boolean is
   begin
      return Executor.Dry_Run or Executor.Logger.Is_Opened;
   end Is_Configured;

   --  ------------------------------
   --  Returns true if this executor runs locally.
   --  ------------------------------
   function Is_Local (Executor : in Executor_Type) return Boolean is
   begin
      return Executor.Controller = null or else Executor.Controller.Is_Local;
   end Is_Local;

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

   --  ------------------------------
   --  Setup the executor to build with the given build node.
   --  ------------------------------
   procedure Set_Build_Node (Executor : in out Executor_Type;
                             Node     : in Porion.Nodes.Models.Node_Ref;
                             Env      : in Util.Strings.Maps.Map) is
   begin
      Executor.Controller := Nodes.Services.Create_Controller (Executor'Unchecked_Access, Node);
      Executor.Controller.Set_Environment (Env);
   end Set_Build_Node;

   --  ------------------------------
   --  Get the usage when running the executor on build nodes.
   --  ------------------------------
   function Get_Usage (Executor : in Executor_Type) return Nodes.Usage_Type is
      use type Nodes.Usage_Type;
   begin
      if Executor.Controller /= null and Executor.Local /= null then
         return Executor.Controller.Get_Usage + Executor.Local.Get_Usage;
      elsif Executor.Controller /= null then
         return Executor.Controller.Get_Usage;
      elsif Executor.Local /= null then
         return Executor.Local.Get_Usage;
      else
         return (0, 0);
      end if;
   end Get_Usage;

   --  ------------------------------
   --  Create the directory and optionally make sure it is cleaned.
   --  ------------------------------
   procedure Create_Directory (Executor : in out Executor_Type;
                               Path     : in String;
                               Clean    : in Boolean) is
      procedure Process (Line : in String);

      procedure Process (Line : in String) is
      begin
         Executor_Type'Class (Executor).Log (Porion.Logs.LOG_EXECUTION,
                                             Line (Line'First .. Line'Last - 1));
      end Process;

   begin
      if Executor.Controller /= null then
         Executor.Controller.Create_Directory (Path, Clean, Process'Access);
      else
         if Executor.Local = null then
            Executor.Local := Nodes.Services.Create_Controller (Executor'Unchecked_Access);
         end if;

         Executor.Local.Create_Directory (Path, Clean, Process'Access);
      end if;
   end Create_Directory;

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
         Executor_Type'Class (Executor).Log (Logs.LOG_EXECUTION,
                                             Line (Line'First .. Line'Last - 1));
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
   begin
      if Executor.Controller /= null then
         Executor.Controller.Execute (Command     => Command,
                                      Working_Dir => Working_Dir,
                                      Process     => Process,
                                      Strip_Crlf  => Strip_Crlf,
                                      Status      => Status);
      else
         if Executor.Local = null then
            Executor.Local := Nodes.Services.Create_Controller (Executor'Unchecked_Access);
         end if;
         Executor.Local.Execute (Command     => Command,
                                 Working_Dir => Working_Dir,
                                 Process     => Process,
                                 Strip_Crlf  => Strip_Crlf,
                                 Status      => Status);
      end if;

      if Status /= 0 then
         Executor.Log (Porion.Logs.LOG_FAILURE, "exit status:" & Integer'Image (Status));
         Executor.Status := Status;
      else
         Executor.Log (Porion.Logs.LOG_RESULT, "exit status: 0");
      end if;
   end Execute;

   --  ------------------------------
   --  Read the file with the controller and execute the `Process` procedure with the
   --  input buffer stream that gives access to the file content.
   --  ------------------------------
   procedure Read_File (Executor    : in out Executor_Type;
                        Path       : in String;
                        Process    : not null access
                           procedure (Stream : in out Input_Buffer_Stream'Class)) is
   begin
      if Executor.Controller /= null then
         Executor.Controller.Read_File (Path => Path, Process => Process);

      else
         if Executor.Local = null then
            Executor.Local := Nodes.Services.Create_Controller (Executor'Unchecked_Access);
         end if;
         Executor.Local.Read_File (Path => Path, Process => Process);
      end if;
   end Read_File;

   --  ------------------------------
   --  Scan the directory for files matching the given pattern.
   --  ------------------------------
   procedure Scan_Directory (Executor    : in out Executor_Type;
                             Path       : in String;
                             Pattern    : in String;
                             Excludes   : in Util.Strings.Vectors.Vector;
                             List       : in out Util.Strings.Sets.Set) is
   begin
      if Executor.Controller /= null then
         Executor.Controller.Scan_Directory (Path => Path, Pattern => Pattern, List => List);

      else
         if Executor.Local = null then
            Executor.Local := Nodes.Services.Create_Controller (Executor'Unchecked_Access);
         end if;
         Executor.Local.Scan_Directory (Path => Path, Pattern => Pattern, List => List);
      end if;
   end Scan_Directory;

   procedure Create_Logger (Executor : in out Executor_Type;
                            Dir      : in String;
                            Name     : in String) is
   begin
      if not Executor.Dry_Run then
         Executor.Logger.Create (Dir, Name);
      end if;
   end Create_Logger;

   --  ------------------------------
   --  Clear and reset the executor.
   --  ------------------------------
   procedure Clear (Executor : in out Executor_Type) is
   begin
      Executor.Commands.Clear;
   end Clear;

   --  ------------------------------
   --  Get the commands that were collected during execution and clear the current list.
   --  ------------------------------
   procedure Fetch_Commands (Executor : in out Executor_Type;
                             Commands : out Command_Vector) is
   begin
      Commands := Executor.Commands;
      Executor.Commands.Clear;
   end Fetch_Commands;

   --  ------------------------------
   --  Record a command that is executed during the build step.
   --  The command is not executed but added to the list of commands.
   --  ------------------------------
   procedure Record_Command (Executor : in out Executor_Type;
                             Command  : in String) is
   begin
      Executor.Log (Logs.LOG_COMMAND, Command);
      Executor.Commands.Append ((Len     => Command'Length,
                                 Step    => Executor.Step,
                                 Command => Command));
   end Record_Command;

   --  ------------------------------
   --  Write the line on the logger.
   --  ------------------------------
   procedure Log (Executor : in out Executor_Type;
                  Source   : in Porion.Logs.Source_Type;
                  Line     : in String) is
      use type Porion.Builds.Step_Type;
      use type Porion.Logs.Source_Type;
   begin
      Executor.Logger.Write (Source, Line);
      if Source /= Logs.LOG_RESULT and Executor.Output_Log
        and Executor.Step /= Porion.Builds.STEP_CHECKOUT
      then
         Ada.Text_IO.Put_Line (Line);
      end if;
   end Log;

end Porion.Executors;
