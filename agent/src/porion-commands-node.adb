-----------------------------------------------------------------------
--  porion-commands-node -- Node command to add/remove/update build nodes
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
with PT.Texts;
with Porion.Configs.Rules;
with Porion.Nodes.Services;
with Porion.Reports;
package body Porion.Commands.Node is

   procedure List_Rules (Rules   : in Porion.Nodes.Services.Rule_Status_Vector;
                         Printer : in out PT.Printer_Type'Class;
                         Styles  : in Porion.Reports.Style_Configuration);

   procedure List_Rules (Rules   : in Porion.Nodes.Services.Rule_Status_Vector;
                         Printer : in out PT.Printer_Type'Class;
                         Styles  : in Porion.Reports.Style_Configuration) is
      Writer : PT.Texts.Printer_Type := PT.Texts.Create (Printer);
      Fields : PT.Texts.Field_Array (1 .. 8);
      Style1 : constant PT.Style_Type := Writer.Create_Style (Styles.Default);
   begin
      Writer.Create_Field (Fields (1), Style1, 10.0);
      Writer.Create_Field (Fields (2), Style1, 40.0);
      Writer.Create_Field (Fields (3), Style1, 50.0);
      Writer.Layout_Fields (Fields);

      for Rule of Rules loop
         if Length (Rule.Path) = 0 then
            Writer.Copy_Style (To => Style1, From => Styles.Error);
         else
            Writer.Copy_Style (To => Style1, From => Styles.Default);
         end if;
         Writer.Put (Fields (1), Porion.Configs.Rules.Get_Name (Rule.Rule));
         if Length (Rule.Path) = 0 then
            Writer.Put (Fields (2), -("* not found *"));
         else
            Writer.Put_UString (Fields (2), Rule.Path);
         end if;
         Writer.Put_UString (Fields (3), Rule.Version);
         Writer.New_Line;
      end loop;
   end List_Rules;

   --  ------------------------------
   --  Add, remove or update build nodes.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);

      function Get_Scheme (URI : in String) return String;
      function Get_Login (URI : in String) return String;
      function Get_Hostname (URI : in String) return String;
      function Get_Path (URI : in String) return String;
      function Get_Type (Scheme : in String) return Porion.Nodes.Node_Type;

      Count : constant Natural := Args.Get_Count;

      function Get_Node_Status return String is
         (Porion.Reports.Get_Status (Context.Project_Service.Build_Node.Get_Status));

      function Get_Scheme (URI : in String) return String is
         Sep : constant Natural := Util.Strings.Index (URI, ':');
      begin
         if Sep > 0 then
            return URI (URI'First .. Sep - 1);
         else
            return "";
         end if;
      end Get_Scheme;

      function Get_Login (URI : in String) return String is
         Sep   : Natural := Util.Strings.Index (URI, ':');
         First : Natural;
      begin
         if Sep > 0 then
            First := Sep + 1;
            while First <= URI'Last and then URI (First) = '/' loop
               First := First + 1;
            end loop;
         else
            First := URI'First;
         end if;
         Sep := Util.Strings.Index (URI, '@', First);
         if Sep = 0 then
            return "";
         end if;
         return URI (First .. Sep - 1);
      end Get_Login;

      function Get_Hostname (URI : in String) return String is
         First : Natural;
         Sep   : Natural := Util.Strings.Index (URI, ':');
      begin
         if Sep > 0 then
            First := Sep + 1;
            while First <= URI'Last and then URI (First) = '/' loop
               First := First + 1;
            end loop;
         else
            First := URI'First;
         end if;
         Sep := Util.Strings.Index (URI, '@', First);
         if Sep > 0 then
            First := Sep + 1;
         end if;
         Sep := Util.Strings.Index (URI, '/', First);
         if Sep > 0 then
            return URI (First .. Sep - 1);
         else
            return URI (First .. URI'Last);
         end if;
      end Get_Hostname;

      function Get_Path (URI : in String) return String is
         First : Natural;
         Sep   : Natural := Util.Strings.Index (URI, ':');
      begin
         if Sep > 0 then
            First := Sep + 1;
            while First <= URI'Last and then URI (First) = '/' loop
               First := First + 1;
            end loop;
         else
            First := URI'First;
         end if;
         Sep := Util.Strings.Index (URI, '@', First);
         if Sep > 0 then
            First := Sep + 1;
         end if;
         Sep := Util.Strings.Index (URI, '/', First);
         if Sep = 0 then
            return "";
         else
            return URI (Sep .. URI'Last);
         end if;
      end Get_Path;

      function Get_Type (Scheme : in String) return Porion.Nodes.Node_Type is
      begin
         if Scheme = "ssh" then
            return Porion.Nodes.NODE_SSH;
         end if;

         if Scheme = "docker" then
            return Porion.Nodes.NODE_DOCKER;
         end if;

         if Scheme = "local" then
            return Porion.Nodes.NODE_LOCAL;
         end if;

         return Porion.Nodes.NODE_SSH;
      end Get_Type;

   begin
      if Count = 0 then
         Porion.Commands.Error (-("missing node name"));
         return;
      end if;
      Context.Open;

      if Command.Remove then
         return;
      elsif Command.Probe then
         for I in 1 .. Count loop
            declare
               Name  : constant String := Args.Get_Argument (I);
               Rules : Porion.Nodes.Services.Rule_Status_Vector;
            begin
               Nodes.Services.Load_Node (Context.Project_Service, Name);
               Nodes.Services.Probe_Node (Context.Project_Service, Command.Rules.all, Rules);
               Context.Notice (-("Node {0} is {1}"), Name, Get_Node_Status);
               List_Rules (Rules, Context.Printer.all, Context.Styles);

            exception
               when Porion.Nodes.Services.Not_Found =>
                  Porion.Commands.Error (-("build node '{0}' not found"), Name);
            end;
         end loop;
      else
         declare
            URI       : constant String := Args.Get_Argument (1);
            Scheme    : constant String := Get_Scheme (URI);
            Login     : constant String := Get_Login (URI);
            Hostname  : constant String := Get_Hostname (URI);
            Directory : constant String := Get_Path (URI);
            Rules     : Porion.Nodes.Services.Rule_Status_Vector;
         begin
            if Command.Update then
               Nodes.Services.Update_Node (Context.Project_Service,
                                           Kind       => Get_Type (Scheme),
                                           Hostname   => Hostname,
                                           Login      => Login,
                                           Repository => Directory);
            else
               Nodes.Services.Add_Node (Context.Project_Service,
                                        Kind       => Get_Type (Scheme),
                                        Hostname   => Hostname,
                                        Login      => Login,
                                        Repository => Directory);
            end if;

            Nodes.Services.Probe_Node (Context.Project_Service, Command.Rules.all, Rules);
            Context.Notice (-("Node {0} is {1}"), Hostname, Get_Node_Status);
            List_Rules (Rules, Context.Printer.all, Context.Styles);

         exception
            when Porion.Nodes.Services.Name_Used =>
               Commands.Error (-("node '{0}' already exists"), Hostname);

         end;
      end if;
   end Execute;

   --  ------------------------------
   --  Setup the command before parsing the arguments and executing it.
   --  ------------------------------
   overriding
   procedure Setup (Command : in out Command_Type;
                    Config  : in out GNAT.Command_Line.Command_Line_Configuration;
                    Context : in out Context_Type) is
   begin
      Drivers.Command_Type (Command).Setup (Config, Context);
      GC.Define_Switch (Config, Command.Remove'Access,
                        "-r", "--remove", -("remove the build node"));
      GC.Define_Switch (Config, Command.Update'Access,
                        "-u", "--update", -("update the build node"));
      GC.Define_Switch (Config, Command.Probe'Access,
                        "-P", "--probe", -("probe the build node"));
      GC.Define_Switch (Config, Command.Rules'Access,
                        "-R=", "--rules=",
                        Argument => "RULES",
                        Help     =>  -("Use the specific rules when probing the build node"));
   end Setup;

end Porion.Commands.Node;
