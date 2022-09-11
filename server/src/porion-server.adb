-----------------------------------------------------------------------
--  Porion-server -- Application server
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

with Util.Log.Loggers;
with Util.Commands;

with Servlet.Server.Web;

with AWA.Commands.Drivers;
with AWA.Commands.Start;
with AWA.Commands.Stop;
with AWA.Commands.List;
with AWA.Commands.Info;
with AWA.Commands.User;
with AWA.Commands.Migrate;

with ADO.Sqlite;

with Porion.Configs;
with Porion.Services;
with Porion.Projects.Services;
with Porion.Resources.Server_Schema;
with Porion.Resources.Queries;
with Porion.Applications;
with Porion.Globals;
procedure Porion.Server is

   package Server_Commands is
     new AWA.Commands.Drivers (Driver_Name => "porion",
                               Container_Type => Servlet.Server.Web.AWS_Container);

   package List_Command is new AWA.Commands.List (Server_Commands);
   package Start_Command is new AWA.Commands.Start (Server_Commands);
   package Stop_Command is new AWA.Commands.Stop (Server_Commands);
   package Info_Command is new AWA.Commands.Info (Server_Commands);
   package User_Command is new AWA.Commands.User (Server_Commands);
   package Migrate_Command is new AWA.Commands.Migrate (Server_Commands);
   pragma Unreferenced (List_Command, Start_Command, Stop_Command, Info_Command,
                        User_Command, Migrate_Command);

   type Init_Command_Type is new Server_Commands.Command_Type with null record;

   overriding
   procedure Execute (Command : in out Init_Command_Type;
                      Name    : in String;
                      Args    : in Util.Commands.Argument_List'Class;
                      Context : in out AWA.Commands.Context_Type);

   Log       : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Server");
   WS        : Servlet.Server.Web.AWS_Container renames Server_Commands.WS;
   Context   : AWA.Commands.Context_Type;
   Arguments : Util.Commands.Dynamic_Argument_List;

   overriding
   procedure Execute (Command : in out Init_Command_Type;
                      Name    : in String;
                      Args    : in Util.Commands.Argument_List'Class;
                      Context : in out AWA.Commands.Context_Type) is
      pragma Unreferenced (Command, Name);

      Config_Path : constant String := Server_Commands.Get_Configuration_Path (Context);
      Schema      : constant Porion.Resources.Content_Access
        := Porion.Resources.Server_Schema.Get_Content ("create-porion_server-sqlite");
      Project_Service : Porion.Projects.Services.Context_Type;
   begin
      if Args.Get_Count = 0 then
         Log.Error (-("missing directory to setup"));

      elsif Args.Get_Count /= 1 then
         Log.Error (-("too many arguments for the command"));
      else
         Porion.Configs.Initialize (Config_Path);
         declare
            Path  : constant String := Args.Get_Argument (1);
         begin
            Project_Service.Setup (Path, Resources.Queries.Get_Content'Access, Schema);

            Log.Info (-("Porion workspace created in {0}"), Path);
            Log.Info (-("Default build node 'localhost' is registered"));
            Log.Info (-("Use 'porion add' to register a first project"));

         exception
            when Porion.Services.Invalid_Workspace =>
               Log.Error (-("workspace directory '{0}' is not empty"), Path);

         end;
      end if;
   end Execute;

   Init_Command : aliased Init_Command_Type;
begin
   --  Initialize the database drivers (all of them or specific ones).
   ADO.Sqlite.Initialize;

   Server_Commands.Driver.Add_Command ("init", -("setup the build server"),
                                       Init_Command'Access);

   WS.Register_Application (Porion.Applications.CONTEXT_PATH, Globals.App'Access);

   Server_Commands.Run (Context, Arguments);

exception
   when E : others =>
      Context.Print (E);
end Porion.Server;
