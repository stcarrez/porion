-----------------------------------------------------------------------
--  porion-commands -- Porion agent commands
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
with System.Multiprocessors;
with Ada.Command_Line;
with Ada.Text_IO;
with Ada.Directories;
with Util.Strings;
with Util.Commands.Parsers.GNAT_Parser;
with PT.Drivers.Texts;
with PT.Colors;
with PT.Texts;
with Porion.Configs.Setup;
with Porion.Executors;
with Porion.Builds.Models;
with Porion.Builds.Services;
with Porion.Resources.Queries;
with Porion.Commands.Drivers;
with Porion.Commands.Build;
with Porion.Commands.Steps;
with Porion.Commands.Status;
with Porion.Commands.Add;
with Porion.Commands.Remove;
with Porion.Commands.List;
with Porion.Commands.Config;
with Porion.Commands.Init;
with Porion.Commands.Edit;
with Porion.Commands.Info;
with Porion.Commands.Depend;
with Porion.Commands.Node;
with Porion.Commands.Check;
with Porion.Commands.Logs;
with Porion.Commands.Set;
with Porion.Commands.Env;
private with Util.Systems.Constants;
package body Porion.Commands is

   Help_Command            : aliased Porion.Commands.Drivers.Help_Command_Type;
   Build_Command           : aliased Porion.Commands.Build.Command_Type;
   Status_Command          : aliased Porion.Commands.Status.Command_Type;
   Config_Command          : aliased Porion.Commands.Config.Command_Type;
   Add_Command             : aliased Porion.Commands.Add.Command_Type;
   List_Command            : aliased Porion.Commands.List.Command_Type;
   Init_Command            : aliased Porion.Commands.Init.Command_Type;
   Step_Command            : aliased Porion.Commands.Steps.Command_Type;
   Edit_Command            : aliased Porion.Commands.Edit.Command_Type;
   Remove_Command          : aliased Porion.Commands.Remove.Command_Type;
   Info_Command            : aliased Porion.Commands.Info.Command_Type;
   Depend_Command          : aliased Porion.Commands.Depend.Command_Type;
   Node_Command            : aliased Porion.Commands.Node.Command_Type;
   Check_Command           : aliased Porion.Commands.Check.Command_Type;
   Logs_Command            : aliased Porion.Commands.Logs.Command_Type;
   Set_Command             : aliased Porion.Commands.Set.Command_Type;
   Env_Command             : aliased Porion.Commands.Env.Command_Type;
   Driver                  : Drivers.Driver_Type;

   Text_Printer            : aliased PT.Drivers.Texts.Printer_Type;

   procedure Flush_Input;

   --  ------------------------------
   --  Print the command usage.
   --  ------------------------------
   procedure Usage (Args    : in Argument_List'Class;
                    Context : in out Context_Type;
                    Name    : in String := "") is
   begin
      GC.Display_Help (Context.Command_Config);
      if Name'Length > 0 then
         Driver.Usage (Args, Context, Name);
      end if;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end Usage;

   --  ------------------------------
   --  Execute the command with its arguments.
   --  ------------------------------
   procedure Execute (Name    : in String;
                      Args    : in Argument_List'Class;
                      Context : in out Context_Type) is
   begin
      Log.Info ("Execute command {0}", Name);

      Driver.Execute (Name, Args, Context);
   end Execute;

   --  ------------------------------
   --  Initialize the commands.
   --  ------------------------------
   overriding
   procedure Initialize (Context : in out Context_Type) is
   begin
      Intl.Initialize ("porion", Porion.Configs.Setup.PREFIX & "/share/locale");

      Context.Worker_Count := Positive (System.Multiprocessors.Number_Of_CPUs);

      GC.Set_Usage (Config => Context.Command_Config,
                    Usage  => "[switchs] command [arguments]",
                    Help   => -("porion - continuous build agent"));
      GC.Define_Switch (Config => Context.Command_Config,
                        Output => Context.Version'Access,
                        Switch => "-V",
                        Long_Switch => "--version",
                        Help   => -("Print the version"));
      GC.Define_Switch (Config => Context.Command_Config,
                        Output => Context.Verbose'Access,
                        Switch => "-v",
                        Long_Switch => "--verbose",
                        Help   => -("Verbose execution mode"));
      GC.Define_Switch (Config => Context.Command_Config,
                        Output => Context.Debug'Access,
                        Switch => "-vv",
                        Long_Switch => "--debug",
                        Help   => -("Enable debug execution"));
      GC.Define_Switch (Config => Context.Command_Config,
                        Output => Context.Dump'Access,
                        Switch => "-vvv",
                        Long_Switch => "--debug-sql",
                        Help   => -("Enable debug SQL execution"));
      GC.Define_Switch (Config => Context.Command_Config,
                        Output => Context.No_Colors'Access,
                        Long_Switch => "--no-color",
                        Help   => -("Disable colors in output"));
      GC.Define_Switch (Config => Context.Command_Config,
                        Output => Context.Quiet'Access,
                        Switch => "-q",
                        Long_Switch => "--quiet",
                        Help => -("quiet execution mode"));
      GC.Define_Switch (Config => Context.Command_Config,
                        Output => Context.Config_File'Access,
                        Switch => "-c:",
                        Long_Switch => "--config=",
                        Argument => "PATH",
                        Help   => -("Defines the path for porion global configuration"));
      GC.Initialize_Option_Scan (Stop_At_First_Non_Switch => True);

      Driver.Set_Description (-("porion - continuous build agent"));
      Driver.Set_Usage (-("[-V] [-v] [-vv] [-vvv] [-c path] " &
                          "<command> [<args>]" & ASCII.LF &
                          "where:" & ASCII.LF &
                          "  -V           Print the tool version" & ASCII.LF &
                          "  -v           Verbose execution mode" & ASCII.LF &
                          "  -vv          Debug execution mode" & ASCII.LF &
                          "  -vvv         Dump execution mode" & ASCII.LF &
                          "  -c path      Defines the path for porion " &
                          "global configuration" & ASCII.LF));
      Driver.Add_Command ("help",
                          -("print some help"),
                          Help_Command'Access);
      Driver.Add_Command ("build",
                          -("build the project"),
                          Build_Command'Access);
      Driver.Add_Command ("status",
                          -("status about the workspace or a project"),
                          Status_Command'Access);
      Driver.Add_Command ("config",
                          -("get or configure a global parameter"),
                          Config_Command'Access);
      Driver.Add_Command ("add",
                          -("add a new project or a new recipe"),
                          Add_Command'Access);
      Driver.Add_Command ("list",
                          -("list the projects, nodes, builds"),
                          List_Command'Access);
      Driver.Add_Command ("step",
                          -("control the build steps"),
                          Step_Command'Access);
      Driver.Add_Command ("edit",
                          -("edit the project configuration"),
                          Edit_Command'Access);
      Driver.Add_Command ("init",
                          -("setup the build agent node"),
                          Init_Command'Access);
      Driver.Add_Command ("remove",
                          -("remove a project and its build data"),
                          Remove_Command'Access);
      Driver.Add_Command ("info",
                          -("report some information about a project or a build"),
                          Info_Command'Access);
      Driver.Add_Command ("depend",
                          -("add or remove project dependencies"),
                          Depend_Command'Access);
      Driver.Add_Command ("node",
                          -("add, update or remove build nodes"),
                          Node_Command'Access);
      Driver.Add_Command ("check",
                          -("check for changes and update the build queue"),
                           Check_Command'Access);
      Driver.Add_Command ("logs",
                          -("display the build logs"),
                           Logs_Command'Access);
      Driver.Add_Command ("set",
                          -("set a project, branch or recipe variable"),
                           Set_Command'Access);
      Driver.Add_Command ("env",
                          -("set or unset build environment variables"),
                           Env_Command'Access);
   end Initialize;

   --  ------------------------------
   --  Setup the command before parsing the arguments and executing it.
   --  ------------------------------
   procedure Setup (Config  : in out GC.Command_Line_Configuration;
                    Context : in out Context_Type) is
   begin
      GC.Define_Switch (Config => Config,
                        Output => Context.Wallet_File'Access,
                        Switch => "-k:",
                        Long_Switch => "--keystore=",
                        Argument => "PATH",
                        Help   => -("Defines the path for the keystore file"));
      GC.Define_Switch (Config => Config,
                        Output => Context.Password_File'Access,
                        Long_Switch => "--passfile=",
                        Argument => "PATH",
                        Help   => -("Read the file that contains the password"));
      GC.Define_Switch (Config => Config,
                        Output => Context.Unsafe_Password'Access,
                        Long_Switch => "--passfd=",
                        Argument => "NUM",
                        Help   => -("Read the password from the pipe with"
                          & " the given file descriptor"));
      GC.Define_Switch (Config => Config,
                        Output => Context.Unsafe_Password'Access,
                        Long_Switch => "--passsocket=",
                        Help   => -("The password is passed within the socket connection"));
      GC.Define_Switch (Config => Config,
                        Output => Context.Password_Env'Access,
                        Long_Switch => "--passenv=",
                        Argument => "NAME",
                        Help   => -("Read the environment variable that contains"
                        & " the password (not safe)"));
      GC.Define_Switch (Config => Config,
                        Output => Context.Unsafe_Password'Access,
                        Switch => "-p:",
                        Long_Switch => "--password=",
                        Help   => -("The password is passed within the command line (not safe)"));
      GC.Define_Switch (Config => Config,
                        Output => Context.Password_Askpass'Access,
                        Long_Switch => "--passask",
                        Help   => -("Run the ssh-askpass command to get the password"));
      GC.Define_Switch (Config => Config,
                        Output => Context.Password_Command'Access,
                        Long_Switch => "--passcmd=",
                        Argument => "COMMAND",
                        Help   => -("Run the command to get the password"));
      GC.Define_Switch (Config => Config,
                        Output => Context.Wallet_Key_File'Access,
                        Long_Switch => "--wallet-key-file=",
                        Argument => "PATH",
                        Help   => -("Read the file that contains the wallet keys"));
   end Setup;

   --  ------------------------------
   --  Setup and configure the printer to write on the console.
   --  ------------------------------
   procedure Setup_Printer (Context : in out Context_Type) is
      function Get_Cols return Integer with
        Import => True, Convention => C,
        Link_Name => Util.Systems.Constants.SYMBOL_PREFIX & "porion_get_cols";

      W : Integer := Get_Cols;
   begin
      if W < 10 then
         W := 80;
      end if;

      Text_Printer.Create (Width => PT.W_Type (W));
      Context.Printer := Text_Printer'Access;

      Context.Styles.Default := Text_Printer.Create_Style;
      if not Context.No_Colors then
         Context.Styles.Default := Text_Printer.Create_Style (PT.Colors.Grey);
         Context.Styles.Error := Text_Printer.Create_Style (PT.Colors.Light_Red);
         Context.Styles.Info := Text_Printer.Create_Style (PT.Colors.White);
         Context.Styles.Success := Text_Printer.Create_Style (PT.Colors.Green);
         Context.Styles.Disabled := Text_Printer.Create_Style (PT.Colors.Blue);
         Context.Styles.Warning := Text_Printer.Create_Style (PT.Colors.Light_Blue);
      else
         Context.Styles.Error := Context.Styles.Default;
         Context.Styles.Error := Context.Styles.Default;
         Context.Styles.Info := Context.Styles.Default;
         Context.Styles.Success := Context.Styles.Default;
         Context.Styles.Disabled := Context.Styles.Default;
         Context.Styles.Warning := Context.Styles.Default;
      end if;
   end Setup_Printer;

   procedure Parse (Context   : in out Context_Type;
                    Arguments : out Util.Commands.Dynamic_Argument_List) is
   begin
      GC.Getopt (Config => Context.Command_Config);
      Util.Commands.Parsers.GNAT_Parser.Get_Arguments (Arguments, GC.Get_Argument);

      if Context.Debug or Context.Verbose or Context.Dump then
         Porion.Configure_Logs (Debug   => Context.Debug,
                                Dump    => Context.Dump,
                                Verbose => Context.Verbose);
      end if;

      Porion.Configs.Initialize (Context.Config_File.all);

      if Context.Version then
         Ada.Text_IO.Put_Line (Porion.Configs.Setup.RELEASE);
         return;
      end if;

      Context.Setup_Printer;

      declare
         Cmd_Name : constant String := Arguments.Get_Command_Name;
      begin
         if Cmd_Name'Length = 0 then
            Porion.Commands.Log.Error (-("missing command name to execute."));
            Porion.Commands.Usage (Arguments, Context);
            Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
            return;
         end if;
         Porion.Commands.Execute (Cmd_Name, Arguments, Context);

      exception
         when GNAT.Command_Line.Invalid_Parameter =>
            Porion.Commands.Error (-("missing option parameter"));
            raise Command_Error;
      end;

   end Parse;

   --  ------------------------------
   --  Report an error message and set exit status for a failure.
   --  ------------------------------
   procedure Error (Message : in String;
                    Arg1    : in String := "";
                    Arg2    : in String := "";
                    Arg3    : in String := "") is
   begin
      Log.Error (Message, Arg1, Arg2, Arg3);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end Error;

   --  ------------------------------
   --  Report an error related to the identification which is not found.
   --  ------------------------------
   procedure Error_Not_Found (Context : in out Context_Type;
                              Ident   : in Projects.Ident_Type) is
   begin
      if not Context.Project_Service.Has_Project then
         Error (-("project '{0}' not found"), To_String (Ident.Name));
      elsif Projects.Has_Branch (Ident) and not Context.Project_Service.Has_Branch then
         Error (-("project '{0}' has no branch named '{1}'"),
                To_String (Ident.Name), To_String (Ident.Branch));
      elsif Projects.Has_Build (Ident) and not Context.Project_Service.Has_Build then
         Error (-("project '{0}' has no build number '{1}'"),
                To_String (Ident.Name), Util.Strings.Image (Ident.Build));
      elsif Projects.Has_Node (Ident) and not Context.Project_Service.Has_Node then
         Error (-("build node '{0}' not found"),
                To_String (Ident.Node));
      elsif Projects.Has_Recipe (Ident) and not Context.Project_Service.Has_Recipe then
         Error (-("project '{0}' has no recipe named '{1}'"),
                To_String (Ident.Name), To_String (Ident.Recipe));
      else
         Error (-("project '{0}' not found"),
                To_String (Ident.Name));
      end if;
   end Error_Not_Found;

   --  ------------------------------
   --  Report an information message during or after executing some command.
   --  ------------------------------
   procedure Notice (Context : in out Context_Type;
                     Message : in String) is
   begin
      if not Context.Quiet then
         Ada.Text_IO.Put_Line (Message);
      end if;
   end Notice;

   procedure Notice (Context : in out Context_Type;
                     Message : in String;
                     Arg1    : in String;
                     Arg2    : in String := "";
                     Arg3    : in String := "") is
   begin
      if not Context.Quiet then
         Ada.Text_IO.Put_Line (Format (Message, Arg1, Arg2, Arg3));
      end if;
   end Notice;

   --  Open the database.
   procedure Open (Context : in out Context_Type) is
   begin
      Context.Project_Service.Open (Porion.Resources.Queries.Get_Content'Access, null);
   end Open;

   overriding
   procedure Finalize (Context : in out Context_Type) is
   begin
      GC.Free (Context.Command_Config);
   end Finalize;

   procedure Flush_Input is
      C         : Character;
      Available : Boolean;
   begin
      loop
         Ada.Text_IO.Get_Immediate (C, Available);
         exit when not Available;
      end loop;

   exception
      when Ada.Text_IO.End_Error =>
         null;
   end Flush_Input;

   function Confirm (Message : in String) return Boolean is
   begin
      Flush_Input;
      Ada.Text_IO.Put ("porion: ");
      Ada.Text_IO.Put (Message);
      Ada.Text_IO.Put (" ");
      declare
         Answer : constant String := Ada.Text_IO.Get_Line;
      begin
         return Answer = "Y" or Answer = "y";
      end;

   exception
      when Ada.Text_IO.End_Error =>
         return False;
   end Confirm;

   --  ------------------------------
   --  Print the build recipe steps of the current project.
   --  ------------------------------
   procedure Print_Recipe_Steps (Context : in out Context_Type) is
      Printer  : PT.Texts.Printer_Type := PT.Texts.Create (Context.Printer.all);
      Executor : Porion.Executors.Executor_Type;
      Commands : Porion.Executors.Command_Vector;
   begin
      Executor.Enable_Dry_Run;

      Porion.Builds.Services.Build (Context.Project_Service,
                                    Context.Project_Service.Recipe,
                                    Executor);

      Printer.New_Line;
      Executor.Fetch_Commands (Commands);
      Porion.Reports.List_Commands (Commands, Context.Printer.all, Context.Styles);
      Printer.New_Line;
   end Print_Recipe_Steps;

   procedure Print_Build_Logs (Levels  : in Porion.Logs.Analysis.Level_Map;
                               Context : in out Context_Type) is
      Path : constant String := Builds.Services.Get_Log_Directory (Context.Project_Service);
   begin
      Print_Build_Logs (Levels, Ada.Directories.Compose (Path, "build.log"), Context);
   end Print_Build_Logs;

   procedure Print_Build_Logs (Levels  : in Porion.Logs.Analysis.Level_Map;
                               Path    : in String;
                               Context : in out Context_Type) is
      use Porion.Logs;
      use type Porion.Logs.Analysis.Level_Type;

      Printer : PT.Texts.Printer_Type := PT.Texts.Create (Context.Printer.all);
      Fields  : PT.Texts.Field_Array (1 .. 2);
      List    : Analysis.Line_Vector;
      Ctx     : Analysis.Analyser_Type;
      Rules   : constant String := Context.Project_Service.Recipe.Get_Filter_Rules;
   begin
      Printer.Create_Field (Fields (1), Context.Styles.Default, 0.0);
      Printer.Create_Field (Fields (2), Context.Styles.Success, 90.0);
      Printer.Set_Bottom_Right_Padding (Fields (1), (1, 0));
      Printer.Set_Max_Dimension (Fields (1), (4, 0));
      Printer.Layout_Fields (Fields (1 .. 2));

      Porion.Logs.Analysis.Set_Rules (Ctx, Rules);
      Porion.Logs.Analysis.Set_Filter (Ctx, Levels);
      Porion.Logs.Analysis.Read (Ctx, Path, List);

      for Line of List loop
         if Line.Level = Analysis.LOG_ERROR then
            Printer.Set_Style (Fields (1), Context.Styles.Error);
            Printer.Set_Style (Fields (2), Context.Styles.Error);
         elsif Line.Level = Analysis.LOG_WARNING then
            Printer.Set_Style (Fields (1), Context.Styles.Warning);
            Printer.Set_Style (Fields (2), Context.Styles.Warning);
         elsif Line.Level = Analysis.LOG_INFO then
            Printer.Set_Style (Fields (1), Context.Styles.Info);
            Printer.Set_Style (Fields (2), Context.Styles.Info);
         else
            Printer.Set_Style (Fields (1), Context.Styles.Default);
            Printer.Set_Style (Fields (2), Context.Styles.Default);
         end if;
         Printer.Put_Int (Fields (1), Line.Number);
         Printer.Put (Fields (2), Line.Content);
         Printer.New_Line;
      end loop;
   end Print_Build_Logs;

end Porion.Commands;
