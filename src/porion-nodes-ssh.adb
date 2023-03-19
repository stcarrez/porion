-----------------------------------------------------------------------
--  porion-nodes-ssh -- SSH build node management
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
with Util.Strings.Vectors;
with Util.Files;
with Util.Log.Loggers;
with Porion.Configs;
with EL.Contexts.Default;
package body Porion.Nodes.SSH is

   package UBO renames Util.Beans.Objects;

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Nodes.SSH");

   --  ------------------------------
   --  Create the controller for the management of the given build node.
   --  ------------------------------
   function Create (Listener : in Listener_Access;
                    Node     : in Models.Node_Ref) return Nodes.Controller_Access is
      Controller : constant Controller_Access := new Controller_Type;
      Cmd        : constant String := Configs.Get (SSH_COMMAND_NAME, SSH_COMMAND);
      Ctx        : EL.Contexts.Default.Default_Context;
   begin
      Porion.Nodes.Set_Listener (Controller.all, Listener);
      Controller.Hostname := Node.Get_Name;
      Controller.Login := Node.Get_Login;
      Controller.Command := EL.Expressions.Create_Expression (Cmd, Ctx);
      return Controller.all'Access;
   end Create;

   overriding
   procedure Expand (Controller  : in out Controller_Type;
                     Command     : in String;
                     Working_Dir : in String;
                     Ignore_Working_Dir : out Boolean;
                     Args        : in out Util.Strings.Vectors.Vector) is
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
      begin
         Porion.Nodes.Controller_Type (Controller).Expand (Ssh, Working_Dir,
                                                           Ignore_Working_Dir, Args);

         --  cd <working_dir> && <command>
         if Working_Dir'Length > 0 then
            Args.Append ("cd " & Working_Dir & " && " & Command);
         else
            Args.Append (Command);
         end if;
         Ignore_Working_Dir := True;
      end;
   end Expand;

   --  ------------------------------
   --  Create the directory and optionally make sure it is cleaned.
   --  ------------------------------
   overriding
   procedure Create_Directory (Controller : in out Controller_Type;
                               Path       : in String;
                               Clean      : in Boolean;
                               Process    : not null access
                                 procedure (Kind : in Output_Type;
                                            Line : in String)) is
      Status : Integer;
   begin
      if Clean then
         Controller.Execute (Command => "rm -rf " & Path & " && mkdir -p " & Path,
                             Working_Dir => "",
                             Process => Process,
                             Strip_Crlf => False,
                             Status => Status);
      else
         Controller.Execute (Command => "mkdir -p " & Path,
                             Working_Dir => "",
                             Process => Process,
                             Strip_Crlf => False,
                             Status => Status);
      end if;
   end Create_Directory;

   --  Read the file with the controller and execute the `Process` procedure with the
   --  input buffer stream that gives access to the file content.
   overriding
   procedure Read_File (Controller : in out Controller_Type;
                        Path       : in String;
                        Process    : not null access
                           procedure (Stream : in out Input_Buffer_Stream'Class)) is
      procedure Read_Input (Out_Stream : in out Input_Buffer_Stream'Class;
                            Err_Stream : in out Input_Buffer_Stream'Class);

      procedure Print (Kind : in Output_Type;
                       Line : in String);
      procedure Print (Kind : in Output_Type;
                       Line : in String) is
      begin
         Log.Error ("{0}", Line);
      end Print;

      procedure Read_Input (Out_Stream : in out Input_Buffer_Stream'Class;
                            Err_Stream : in out Input_Buffer_Stream'Class) is
         Report : Report_Output;
         task Reader is
         end Reader;
         task body Reader is
         begin
            Read_Input (Report, Err_Stream, True, STDERR, Print'Access);
         end Reader;

      begin
         Process (Out_Stream);
      end Read_Input;

      Status : Integer;
      Args   : Util.Strings.Vectors.Vector;
      Ignore_Working_Dir : Boolean;
   begin
      Controller.Expand ("cat " & Path, "", Ignore_Working_Dir, Args);
      Controller.Execute (Args => Args,
                          Working_Dir => "",
                          Process => Read_Input'Access,
                          Status => Status);
   end Read_File;

   --  ------------------------------
   --  Scan the directory for files matching the given pattern.
   --  ------------------------------
   overriding
   procedure Scan_Directory (Controller : in out Controller_Type;
                             Path       : in String;
                             Pattern    : in String;
                             List       : in out Util.Strings.Sets.Set) is
      procedure Process (Kind : in Output_Type;
                         Line : in String);

      procedure Process (Kind : in Output_Type;
                         Line : in String) is
      begin
         if Kind = STDERR then
            Log.Error ("{0}", Line);
            return;
         end if;
         if Line'Length > 0 then
            List.Include (Util.Files.Compose (Path, Line));
         end if;
      end Process;

      Status : Integer;
   begin
      Controller.Execute (Command => "ls -c " & Pattern,
                          Working_Dir => Path,
                          Process => Process'Access,
                          Strip_Crlf => True,
                          Status => Status);
   end Scan_Directory;

end Porion.Nodes.SSH;
