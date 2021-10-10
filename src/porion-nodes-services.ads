-----------------------------------------------------------------------
--  porion-nodes-services -- Build node management operations
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
with Porion.Services;
with Porion.Nodes.Models;
package Porion.Nodes.Services is

   UNAME_COMMAND_NAME   : constant String := "command_uname";
   RELEASE_COMMAND_NAME : constant String := "command_cat_release";

   UNAME_COMMAND        : constant String := "uname -a";
   RRELEASE_COMMAND     : constant String := "cat /etc/os-release";

   Name_Used    : exception;

   Invalid_Name : exception;

   Not_Found    : exception renames Porion.Services.Not_Found;

   subtype Context_Type is Porion.Services.Context_Type;

   --  Load the build node corresponding to the given hostname.
   procedure Load_Node (Service  : in out Context_Type'Class;
                        Hostname : in String) with
     Pre  => Service.Is_Open,
     Post => Service.Build_Node.Is_Loaded;

   --  Load the default build node.
   procedure Load_Default_Node (Service  : in out Context_Type'Class) with
     Pre  => Service.Is_Open,
     Post => Service.Build_Node.Is_Loaded;

   --  Probe the current node to check and update its status.
   procedure Probe_Node (Service : in out Context_Type) with
     Pre => Service.Is_Open and Service.Build_Node.Is_Loaded;

   --  Add a default build node.
   procedure Add_Default_Node (Service   : in out Context_Type;
                               Hostname  : in String;
                               Login     : in String) with
     Pre  => Service.Is_Open and Hostname'Length > 0,
     Post => Service.Build_Node.Is_Inserted;

   --  Add a build node
   procedure Add_Node (Service    : in out Context_Type;
                       Kind       : in Node_Type;
                       Hostname   : in String;
                       Login      : in String;
                       Repository : in String) with
     Pre  => Service.Is_Open and Hostname'Length > 0,
     Post => Service.Build_Node.Is_Inserted;

   --  Remove the node with the given name.
   procedure Remove_Node (Service : in out Context_Type;
                          Name    : in String) with
     Pre  => Service.Is_Open and Name'Length > 0,
     Post => Service.Build_Node.Is_Null;

   --  Create the controller executor for the build node.
   function Create_Controller (Node : in Models.Node_Ref) return Controller_Access;

end Porion.Nodes.Services;
