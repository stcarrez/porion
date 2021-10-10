-----------------------------------------------------------------------
--  porion-commands-node -- Node command to add/remove/update build nodes
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
with Porion.Projects.Services;
with Porion.Nodes.Services;
with Porion.Services;
with Porion.Reports;
package body Porion.Commands.Node is

   --  ------------------------------
   --  Add, remove or update build nodes.
   --  ------------------------------
   overriding
   procedure Execute (Command   : in out Command_Type;
                      Name      : in String;
                      Args      : in Argument_List'Class;
                      Context   : in out Context_Type) is
      pragma Unreferenced (Name);
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
               Name : constant String := Args.Get_Argument (I);
            begin
               Nodes.Services.Load_Node (Context.Project_Service, Name);
               Nodes.Services.Probe_Node (Context.Project_Service);
               Context.Console.Notice (N_INFO, Format (-("Node {0} is {1}"),
                                       Name, Get_Node_Status));

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
         begin
            Nodes.Services.Add_Node (Context.Project_Service,
                                     Kind       => Get_Type (Scheme),
                                     Hostname   => Hostname,
                                     Login      => Login,
                                     Repository => Directory);

            Nodes.Services.Probe_Node (Context.Project_Service);

         exception
            when Porion.Nodes.Services.Name_Used =>
               Porion.Commands.Error (-("node '{0}' already exists"),
                                      Hostname);

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
      GC.Define_Switch (Config, Command.Probe'Access,
                        "-p", "--probe", -("probe the build node"));
   end Setup;

end Porion.Commands.Node;
