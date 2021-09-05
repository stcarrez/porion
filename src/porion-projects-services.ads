-----------------------------------------------------------------------
--  porion-projects -- Project information
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
with Util.Serialize.IO;
with Porion.Sources;
with Porion.Services;
with Porion.Projects.Models;
package Porion.Projects.Services is

   Name_Used : exception;

   Invalid_Name : exception;

   type Context_Type is limited new Porion.Services.Context_Type with private;

   --  Add a build node
   procedure Add_Node (Service   : in out Context_Type;
                       Hostname  : in String;
                       Login     : in String);

   --  Add a project with the source information.
   procedure Add_Project (Service   : in out Context_Type;
                          Info      : in Porion.Sources.Source_Info_Type);

   procedure Add_Branch (Service : in out Context_Type;
                         Name    : in String;
                         Item    : in Porion.Sources.Branch_Type);

   --  Remove a project with the given name and all its build data.
   procedure Remove_Project (Service : in out Context_Type;
                             Name    : in String);

   procedure Check_Sources (Service : in out Context_Type;
                            Status  : in out Porion.Sources.Status_Type);

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class;
                     Process : access
                       procedure (Stream : in out Util.Serialize.IO.Output_Stream'Class));

   procedure Update (Service : in out Context_Type;
                     Project : in out Porion.Projects.Models.Project_Ref);

private

   type Context_Type is limited new Porion.Services.Context_Type with record
      Source_Controller : Porion.Sources.Controller_Access;
   end record;

end Porion.Projects.Services;
