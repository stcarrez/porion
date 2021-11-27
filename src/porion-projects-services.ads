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
with Porion.Executors;
with Porion.Projects.Models;
package Porion.Projects.Services is

   PROJECT_CHECK_DELAY_NAME    : constant String := "project_check_delay";
   PROJECT_DEFAULT_CHECK_DELAY : constant := 3600;

   Name_Used    : exception;

   Invalid_Name : exception;

   Not_Found    : exception renames Porion.Services.Not_Found;

   Bad_Value    : exception;

   subtype Context_Type is Porion.Services.Context_Type;

   --  Add a project with the source information.
   procedure Add_Project (Service   : in out Context_Type;
                          Info      : in Porion.Sources.Source_Info_Type) with
      Pre => Service.Is_Open;

   procedure Add_Branch (Service : in out Context_Type;
                         Name    : in String;
                         Item    : in Porion.Sources.Branch_Type;
                         Is_Head : in Boolean) with
      Pre => Service.Is_Open;

   --  Remove a project with the given name and all its build data.
   procedure Remove_Project (Service : in out Context_Type;
                             Name    : in String) with
      Pre => Service.Is_Open;

   --  Add a dependency on the current project.
   procedure Add_Dependency (Service : in out Context_Type;
                             Depend  : in String) with
      Pre => Service.Is_Open and Service.Has_Project;

   --  Remove a dependency on the current project.
   procedure Remove_Dependency (Service : in out Context_Type;
                                Depend  : in String) with
      Pre => Service.Is_Open and Service.Has_Project;

   procedure Check_Sources (Service  : in out Context_Type;
                            Executor : in out Porion.Executors.Executor_Type'Class;
                            Force    : in Boolean) with
      Pre => Service.Is_Open;

   procedure Check_Sources (Service  : in out Context_Type;
                            Status   : in out Porion.Sources.Status_Type;
                            Executor : in out Porion.Executors.Executor_Type'Class) with
      Pre => Service.Has_Project;

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class;
                     Process : access
                       procedure (Stream : in out Util.Serialize.IO.Output_Stream'Class));

   procedure Update (Service : in out Context_Type;
                     Project : in out Porion.Projects.Models.Project_Ref);

   procedure Set_Name (Service  : in out Context_Type;
                       Name     : in String;
                       Modified : out Boolean) with
      Pre => Service.Has_Project;

   --  Set the description associated with the project.
   procedure Set_Description (Service     : in out Context_Type;
                              Description : in String;
                              Modified    : out Boolean) with
      Pre => Service.Has_Project;

   --  Set the project status to enable, disable or put the project onhold.
   --  Raises Bad_Value if the status value is not correct.
   procedure Set_Status (Service  : in out Context_Type;
                         Status   : in String;
                         Modified : out Boolean) with
      Pre => Service.Has_Project;

   --  Set the branch or recipe rate factor.
   --  Raises Bad_Value if the factor is not a number.
   procedure Set_Rate_Factor (Service  : in out Context_Type;
                              Factor   : in String;
                              Modified : out Boolean) with
      Pre => Service.Has_Project and Service.Has_Branch;

end Porion.Projects.Services;
