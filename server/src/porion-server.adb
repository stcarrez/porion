-----------------------------------------------------------------------
--  Porion-server -- Application server
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
with Util.Log.Loggers;
with Util.Commands;

with Servlet.Server.Web;

with AWA.Setup.Applications;
with AWA.Commands.Drivers;
with AWA.Commands.Start;
with AWA.Commands.Setup;
with AWA.Commands.Stop;
with AWA.Commands.List;
with AWA.Commands.Info;

with ADO.Drivers;
--  with ADO.Sqlite;
--  with ADO.Mysql;
--  with ADO.Postgresql;

with Porion.Applications;
procedure Porion.Server is

   package Server_Commands is
     new AWA.Commands.Drivers (Driver_Name => "porion",
                               Container_Type => Servlet.Server.Web.AWS_Container);

   package List_Command is new AWA.Commands.List (Server_Commands);
   package Start_Command is new AWA.Commands.Start (Server_Commands);
   package Stop_Command is new AWA.Commands.Stop (Server_Commands);
   package Info_Command is new AWA.Commands.Info (Server_Commands);
   package Setup_Command is new AWA.Commands.Setup (Start_Command);

   Log       : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Server");
   App       : constant Porion.Applications.Application_Access := new Porion.Applications.Application;
   WS        : Servlet.Server.Web.AWS_Container renames Server_Commands.WS;
   Context   : AWA.Commands.Context_Type;
   Arguments : Util.Commands.Dynamic_Argument_List;
begin
   --  Initialize the database drivers (all of them or specific ones).
   ADO.Drivers.Initialize;
   --  ADO.Sqlite.Initialize;
   --  ADO.Mysql.Initialize;
   --  ADO.Postgresql.Initialize;
   Log.Info ("Connect you browser to: http://localhost:8080{0}/index.html",
             Porion.Applications.CONTEXT_PATH);
   WS.Register_Application (Porion.Applications.CONTEXT_PATH, App.all'Access);

   Server_Commands.Run (Context, Arguments);

exception
   when E : others =>
      Context.Print (E);
end Porion.Server;
