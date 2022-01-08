-----------------------------------------------------------------------
--  porion-nodes-services -- Build node management operations
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
with Ada.Calendar;
with Ada.Containers;
with Ada.Strings.Fixed;
with Util.Log.Loggers;
with Util.Strings.Vectors;
with Util.Strings.Tokenizers;
with Porion.Configs;
with Porion.Nodes.Local;
with Porion.Nodes.SSH;
with ADO.SQL;
package body Porion.Nodes.Services is

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Nodes.Services");

   --  ------------------------------
   --  Create the controller executor for the build node.
   --  ------------------------------
   function Create_Controller (Listener : in Listener_Access;
                               Node     : in Models.Node_Ref) return Controller_Access is
   begin
      case Node.Get_Kind is
         when Nodes.NODE_LOCAL =>
            return Local.Create (Listener);

         when Nodes.NODE_SSH =>
            return SSH.Create (Listener, Node);

         when others =>
            log.Error ("Node type {0} supported", Node.Get_Kind'Image);
            return null;

      end case;
   end Create_Controller;

   function Create_Controller (Listener : in Listener_Access) return Controller_Access is
   begin
      return Local.Create (Listener);
   end Create_Controller;

   --  ------------------------------
   --  Load the build node corresponding to the given hostname.
   --  ------------------------------
   procedure Load_Node (Service  : in out Context_Type'Class;
                        Hostname : in String) is
      Query : ADO.SQL.Query;
      Found : Boolean;
   begin
      Log.Debug ("Load build node {0}", Hostname);

      Query.Bind_Param (1, Hostname);
      Query.Set_Filter ("o.name = ? AND o.deleted = 0");
      Service.Build_Node.Find (Service.DB, Query, Found);
      if not Found then
         Log.Warn ("Build node {0} does not exist", Hostname);
         raise Not_Found;
      end if;

      Log.Info ("Build node {0} loaded", Hostname);
   end Load_Node;

   --  ------------------------------
   --  Load the default build node.
   --  ------------------------------
   procedure Load_Default_Node (Service  : in out Context_Type'Class) is
      Query : ADO.SQL.Query;
      Found : Boolean;
   begin
      Log.Debug ("Load default build node");

      Query.Set_filter ("o.main_node AND o.deleted = 0");
      Service.Build_Node.Find (Service.DB, Query, Found);
      if not Found then
         Log.Warn ("Default build node does not exist");
         raise Not_Found;
      end if;

      Log.Info ("Default build node {0} loaded", String '(Service.Build_Node.Get_Name));
   end Load_Default_Node;

   --  ------------------------------
   --  Probe the current node to check and update its status.
   --  ------------------------------
   procedure Probe_Node (Service     : in out Context_Type;
                         Check_Rules : in String;
                         Rules       : in out Rule_Status_Vector) is
      procedure Probe_Uname (Controller : in Controller_Access);
      procedure Probe_Os_Release (Controller : in Controller_Access);
      procedure Probe_Rule (Controller : in Controller_Access;
                            Rule       : in out Rule_Status_Type);
      procedure Read_Rules (Token : in String;
                            Done  : out Boolean);

      --  Parse result of uname -a which provides most information.
      --  Examples:
      --
      --  Linux zebulon 5.4.0-84-generic #94-Ubuntu SMP ... x86_64 x86_64 x86_64 GNU/Linux
      --  NetBSD poseidon.lan 9.2 NetBSD 9.2 (GENERIC) #0: ...ile/GENERIC amd64
      --  FreeBSD apollon.lan 13.0-RELEASE FreeBSD 13.0-RELEASE #0 ...IC  amd64
      procedure Probe_Uname (Controller : in Controller_Access) is

         use type Ada.Containers.Count_Type;

         procedure Process (Line : in String);
         procedure New_Token (Token : in String;
                              Done  : out Boolean);

         Uname  : constant String := Configs.Get (UNAME_COMMAND_NAME, UNAME_COMMAND);
         Status : Natural;
         Tokens : Util.Strings.Vectors.Vector;

         procedure New_Token (Token : in String;
                              Done  : out Boolean) is
         begin
            Tokens.Append (Token);
            Done := False;
         end New_Token;

         procedure Process (Line : in String) is
         begin
            Util.Strings.Tokenizers.Iterate_Tokens (Line, " ", New_Token'Access);
         end Process;

      begin
         Controller.Execute (Command     => Uname,
                             Working_Dir => "",
                             Process     => Process'Access,
                             Strip_Crlf  => True,
                             Status      => Status);

         if Status /= 0 then
            Service.Build_Node.Set_Status (NODE_ERROR);
            return;
         end if;

         if Tokens.Length < 5 then
            Service.Build_Node.Set_Status (NODE_ERROR);
            return;
         end if;

         Service.Build_Node.Set_Status (NODE_ONLINE);
         Service.Build_Node.Set_Os_Name (Tokens.Element (1));
         if Tokens.Last_Element = "GNU/Linux" then
            Tokens.Delete_Last;
            for Token of Tokens loop
               if Ada.Strings.Fixed.Index (Token, "Ubuntu") > 0 then
                  Service.Build_Node.Set_OS_Name ("Ubuntu");
                  exit;
               end if;
               if Ada.Strings.Fixed.Index (Token, "Debian") > 0 then
                  Service.Build_Node.Set_Os_Name ("Debian");
                  exit;
               end if;
            end loop;
         end if;
         Service.Build_Node.Set_Os_Version (Tokens.Element (3));
         if Tokens.Last_Element = "amd64" then
            Service.Build_Node.Set_Cpu_Type ("x86_64");
         else
            Service.Build_Node.Set_Cpu_Type (Tokens.Last_Element);
         end if;
      end Probe_Uname;

      --  Parse the /etc/os-release which provides a more formatted set of information.
      --  OS_NAME and OS_VERSION_ID if provided give more reliable information than uname.
      procedure Probe_Os_Release (Controller : in Controller_Access) is

         procedure Process (Line : in String);

         Release_Cmd : constant String := Configs.Get (RELEASE_COMMAND_NAME, RELEASE_COMMAND);
         Status      : Natural;
         Os_Name     : UString;
         Os_Version  : UString;

         procedure Process (Line : in String) is
            Pos   : constant Natural := Util.Strings.Index (Line, '=');
            First : Natural;
            Last  : Natural;
         begin
            if Pos = 0 or Pos = Line'Last then
               return;
            end if;
            if Line (Line'Last) = '"' or Line (Line'Last) = ''' then
               Last := Line'Last - 1;
            else
               Last := Line'Last;
            end if;
            if Line (Pos + 1) = '"' or Line (Pos + 1) = ''' then
               First := Pos + 2;
            else
               First := Pos + 1;
            end if;
            if Line (Line'First .. Pos) = "NAME=" then
               Os_Name := To_UString (Line (First .. Last));
               return;
            end if;

            if Line (Line'First .. Pos) = "VERSION_ID=" then
               Os_Version := To_UString (Line (First .. Last));
               return;
            end if;
         end Process;

      begin
         Controller.Execute (Command     => Release_Cmd,
                             Working_Dir => "",
                             Process     => Process'Access,
                             Strip_Crlf  => True,
                             Status      => Status);

         if Status /= 0 then
            return;
         end if;

         if Length (Os_Name) > 0 then
            Service.Build_Node.Set_Os_Name (Os_Name);
         end if;
         if Length (Os_Version) > 0 then
            Service.Build_Node.Set_Os_Version (Os_Version);
         end if;
      end Probe_Os_Release;

      --  Check if the given rule is available on the node and get its version.
      procedure Probe_Rule (Controller : in Controller_Access;
                            Rule       : in out Rule_Status_Type) is

         procedure Process_Availability (Line : in String);
         procedure Process_Version (Line : in String);

         Status      : Natural;

         procedure Process_Availability (Line : in String) is
         begin
            if Line'Length > 0 then
               Log.Info ("{0}", Line);

               Rule.Path := To_UString (Line);
            end if;
         end Process_Availability;

         procedure Process_Version (Line : in String) is
         begin
            if Line'Length > 0 then
               Log.Info ("{0}", Line);

               Rule.Version := To_UString (Line);
            end if;
         end Process_Version;

         Availability_Command : constant String
            := Configs.Rules.Get_Command (Rule.Rule, "availability", "");
         Version_Command      : constant String
            := Configs.Rules.Get_Command (Rule.Rule, "version", "");
      begin
         if Availability_Command'Length = 0 then
            return;
         end if;

         Controller.Execute (Command     => Availability_Command,
                             Working_Dir => "",
                             Process     => Process_Availability'Access,
                             Strip_Crlf  => True,
                             Status      => Status);

         if Status /= 0 then
            return;
         end if;

         if Version_Command'Length = 0 then
            return;
         end if;

         Controller.Execute (Command     => Version_Command,
                             Working_Dir => "",
                             Process     => Process_Version'Access,
                             Strip_Crlf  => True,
                             Status      => Status);

         if Status /= 0 then
            return;
         end if;

      end Probe_Rule;

      --  Read the rule definition that must be checked.
      procedure Read_Rules (Token : in String;
                            Done  : out Boolean) is
      begin
         Done := False;
         if Token'Length > 0 then
            declare
               R : constant Configs.Rules.Rule_Type := Configs.Rules.Get_Definition (Token);
            begin
               if not Configs.Rules.Is_Null (R) then
                  Rules.Append ((Rule => R, others => <>));
               end if;
            end;
         end if;
      end Read_Rules;

      Controller : Controller_Access;
   begin
      if Service.Build_Node.Get_Status = NODE_DISABLED then
         return;
      end if;

      Controller := Create_Controller (null, Service.Build_Node);
      if Controller = null then
         return;
      end if;

      Probe_Uname (Controller);

      --  When some check rules are specified, update the build node to check these rules.
      if Check_Rules'Length > 0 then
         Service.Build_Node.Set_Check_Rules (To_Filter_Rules (Check_Rules));
      end if;

      if Service.Build_Node.Get_Status /= NODE_ERROR then
         Probe_Os_Release (Controller);

         if Rules.Is_Empty then
            Util.Strings.Tokenizers.Iterate_Tokens (Content => Service.Build_Node.Get_Check_Rules,
                                                    Pattern => " ",
                                                    Process => Read_Rules'Access);
         end if;

         for Rule of Rules loop
            Probe_Rule (Controller, Rule);
         end loop;
      end if;

      Service.Build_Node.Set_Info_Date ((Is_Null => False,
                                         Value   => Ada.Calendar.Clock));
      Service.Build_Node.Save (Service.DB);
   end Probe_Node;

   --  ------------------------------
   --  Add a default build node.
   --  ------------------------------
   procedure Add_Default_Node (Service   : in out Context_Type;
                               Hostname  : in String;
                               Login     : in String) is
      Query : ADO.SQL.Query;
      Found : Boolean;
   begin
      Log.Debug ("Add build node {0} with {1}", Hostname, Login);

      Service.DB.Begin_Transaction;
      Query.Bind_Param (1, Hostname);
      Query.Set_Filter ("o.name = ? AND o.deleted = 0");
      Service.Build_Node.Find (Service.DB, Query, Found);
      if Found then
         Log.Warn ("Build node name {0} already used", Hostname);
         raise Not_Found;
      end if;
      Service.Build_Node.Set_Name (Hostname);
      Service.Build_Node.Set_Login (Login);
      Service.Build_Node.Set_Create_Date (Ada.Calendar.Clock);
      Service.Build_Node.Set_Kind (Porion.Nodes.NODE_LOCAL);
      Service.Build_Node.Set_Status (NODE_ENABLED);
      Service.Build_Node.Set_Repository_Dir (Porion.Configs.Get_Project_Directory);
      Service.Build_Node.Set_Main_Node (True);
      Service.Build_Node.Save (Service.DB);
      Service.DB.Commit;

      Log.Info ("Default build node {0} added", Hostname);
   end Add_Default_Node;

   --  ------------------------------
   --  Add a build node
   --  ------------------------------
   procedure Add_Node (Service    : in out Context_Type;
                       Kind       : in Node_Type;
                       Hostname   : in String;
                       Login      : in String;
                       Repository : in String) is
      Query : ADO.SQL.Query;
      Found : Boolean;
   begin
      Log.Debug ("Add build node {0} with {1}", Hostname, Login);

      Service.DB.Begin_Transaction;
      Query.Bind_Param (1, Hostname);
      Query.Set_Filter ("o.name = ? AND o.deleted = 0");
      Service.Build_Node.Find (Service.DB, Query, Found);
      if Found then
         Log.Warn ("Build node name {0} already used", Hostname);
         raise Name_Used;
      end if;
      Service.Build_Node.Set_Name (Hostname);
      Service.Build_Node.Set_Login (Login);
      Service.Build_Node.Set_Create_Date (Ada.Calendar.Clock);
      Service.Build_Node.Set_Kind (Kind);
      Service.Build_Node.Set_Status (NODE_ENABLED);
      Service.Build_Node.Set_Repository_Dir (Repository);
      Service.Build_Node.Save (Service.DB);
      Service.DB.Commit;

      Log.Info ("Build node {0} added", Hostname);
   end Add_Node;

   --  ------------------------------
   --  Remove the node with the given name.
   --  ------------------------------
   procedure Remove_Node (Service : in out Context_Type;
                          Name    : in String) is
   begin
      Load_Node (Service, Name);

      --  Mark the database node entry offline and deleted but keep the record.
      Service.DB.Begin_Transaction;
      Service.Build_Node.Set_Status (NODE_OFFLINE);
      Service.Build_Node.Set_Deleted (True);
      Service.Build_Node.Save (Service.DB);
      Service.DB.Commit;

      Log.Info ("Build node {0} removed", Name);
   end Remove_Node;

end Porion.Nodes.Services;
