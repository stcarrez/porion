-----------------------------------------------------------------------
--  porion-commands -- Porion agent commands
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
with Util.Commands;
private with Util.Log.Loggers;
private with Ada.Finalization;
private with GNAT.Command_Line;
private with GNAT.Strings;
private with Porion.Projects.Services;
private with Porion.Builds.Services;
private with Util.Commands.Consoles.Text;
private with Util.Strings.Formats;
package Porion.Commands is

   Command_Error : exception;

   subtype Argument_List is Util.Commands.Argument_List;

   type Context_Type is limited private;

   --  Print the command usage.
   procedure Usage (Args    : in Argument_List'Class;
                    Context : in out Context_Type;
                    Name    : in String := "");

   --  Execute the command with its arguments.
   procedure Execute (Name    : in String;
                      Args    : in Argument_List'Class;
                      Context : in out Context_Type);

   procedure Parse (Context   : in out Context_Type;
                    Arguments : out Util.Commands.Dynamic_Argument_List);

private

   Log     : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Commands");

   package GC renames GNAT.Command_Line;

   type Field_Number is range 1 .. 256;

   type Notice_Type is (N_USAGE, N_INFO, N_ERROR);

   package Consoles is
     new Util.Commands.Consoles (Field_Type  => Field_Number,
                                 Notice_Type => Notice_Type);

   package Text_Consoles is
      new Consoles.Text;

   type Context_Type is limited new Ada.Finalization.Limited_Controlled with record
      Console           : Text_Consoles.Console_Type;
      Worker_Count      : aliased Integer := 1;
      Version           : aliased Boolean := False;
      Verbose           : aliased Boolean := False;
      Debug             : aliased Boolean := False;
      Dump              : aliased Boolean := False;
      Zero              : aliased Boolean := False;
      Config_File       : aliased GNAT.Strings.String_Access;
      Wallet_File       : aliased GNAT.Strings.String_Access;
      Wallet_Key_File   : aliased GNAT.Strings.String_Access;
      Password_File     : aliased GNAT.Strings.String_Access;
      Password_Env      : aliased GNAT.Strings.String_Access;
      Unsafe_Password   : aliased GNAT.Strings.String_Access;
      Password_Socket   : aliased GNAT.Strings.String_Access;
      Password_Command  : aliased GNAT.Strings.String_Access;
      Password_Askpass  : aliased Boolean := False;
      No_Password_Opt   : Boolean := False;
      Command_Config    : GC.Command_Line_Configuration;
      First_Arg         : Positive := 1;
      Project_Service   : Porion.Projects.Services.Context_Type;
      Build_Service     : Porion.Builds.Services.Context_Type;
   end record;

   --  Initialize the commands.
   overriding
   procedure Initialize (Context : in out Context_Type);

   overriding
   procedure Finalize (Context : in out Context_Type);

   --  Open the database.
   procedure Open (Context : in out Context_Type);

   --  Setup the command before parsing the arguments and executing it.
   procedure Setup (Config  : in out GC.Command_Line_Configuration;
                    Context : in out Context_Type);

   --  Report an error message and set exit status for a failure.
   procedure Error (Message : in String;
                    Arg1    : in String := "";
                    Arg2    : in String := "";
                    Arg3    : in String := "");

   function Format (Message : in String;
                    Arg1    : in String) return String
     renames Util.Strings.Formats.Format;

   function Format (Message : in String;
                    Arg1    : in String;
                    Arg2    : in String;
                    Arg3    : in String := "";
                    Arg4    : in String := "") return String is
      (Util.Strings.Formats.Format (Message, Arg1, Arg2, Arg3, Arg4));

   function Confirm (Message : in String) return Boolean;

end Porion.Commands;
