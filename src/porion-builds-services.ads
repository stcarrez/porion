-----------------------------------------------------------------------
--  porion-builds-services -- build service to manage builds
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
with Ada.Containers.Vectors;
with Util.Strings.Vectors;
with Util.Serialize.IO;
with Porion.Configs;
with Porion.Builds.Models;
with Porion.Projects;
with Porion.Services;
with Porion.Executors;
package Porion.Builds.Services is

   Invalid_Position : exception;

   type Build_Step is record
      Step   : Porion.Builds.Models.Recipe_Step_Ref;
      Config : Porion.Configs.Config_Type;
   end record;

   package Build_Step_Vectors is
     new Ada.Containers.Vectors (Index_Type   => Positive,
                                 Element_Type => Build_Step);
   subtype Build_Step_Vector is Build_Step_Vectors.Vector;
   subtype Build_Step_Cursor is Build_Step_Vectors.Cursor;

   type Build_Config is record
      Config : Porion.Builds.Models.Recipe_Ref;
      Steps  : Build_Step_Vector;
   end record;

   package Build_Config_Vectors is
     new Ada.Containers.Vectors (Index_Type   => Positive,
                                 Element_Type => Build_Config);
   subtype Build_Config_Vector is Build_Config_Vectors.Vector;
   subtype Build_Config_Cursor is Build_Config_Vectors.Cursor;

   subtype Context_Type is Porion.Services.Context_Type;

   --  Get the directory that contains the logs for the build.
   function Get_Log_Directory (Service : in Context_Type) return String with
      Pre => Service.Has_Project and Service.Has_Branch and Service.Has_Build;

   procedure Build (Service     : in out Context_Type;
                    Executor    : in out Porion.Executors.Executor_Type'Class;
                    Found       : out Boolean) with
      Pre => Service.Is_Open;

   procedure Build (Service     : in out Context_Type;
                    Recipe      : in Porion.Builds.Models.Recipe_Ref;
                    Executor    : in out Porion.Executors.Executor_Type'Class) with
     Pre => Service.Has_Project and Recipe.Is_Loaded;

   procedure Build_Queue (Service : in out Context_Type;
                          Node    : in String) with
      Pre => Service.Is_Open;

   procedure Start_Build (Service     : in out Context_Type;
                          Recipe      : in Porion.Builds.Models.Recipe_Ref;
                          Executor    : in out Porion.Executors.Executor_Type'Class) with
     Pre => Service.Has_Project;

   --  Delete the build step at the given execution order.
   --  Raises Invalid_Position if the position is invalid.
   procedure Delete_Step (Service  : in out Context_Type;
                          Recipe   : in out Porion.Builds.Models.Recipe_Ref;
                          Position : in Positive) with
     Pre => Service.Has_Project and Recipe.Is_Loaded;

   --  Insert the build step in the recipe at the given position.
   procedure Insert_Step (Service   : in out Context_Type;
                          Recipe    : in out Porion.Builds.Models.Recipe_Ref;
                          Position  : in Natural;
                          Kind      : in Porion.Builds.Models.Builder_Type;
                          Step      : in Porion.Builds.Step_Type;
                          Arguments : in Util.Strings.Vectors.Vector) with
     Pre => Service.Has_Project and Recipe.Is_Loaded;

   --  Update the build step at the given position in the recipe.  To update the
   --  recipe, the Update procedure is called.  The build step parameters should
   --  not be modified.
   procedure Update_Step (Service   : in out Context_Type;
                          Recipe    : in out Porion.Builds.Models.Recipe_Ref;
                          Position  : in Positive;
                          Update    : not null access
                           procedure (Step : in out Porion.Builds.Models.Recipe_Step_Ref)) with
      Pre => Service.Has_Project and Recipe.Is_Loaded;

   --  Update the build step command at the given position in the recipe.
   procedure Update_Step (Service   : in out Context_Type;
                          Recipe    : in out Porion.Builds.Models.Recipe_Ref;
                          Position  : in Positive;
                          Kind      : in Porion.Builds.Models.Builder_Type;
                          Step      : in Porion.Builds.Step_Type;
                          Arguments : in Util.Strings.Vectors.Vector) with
      Pre => Service.Has_Project and Recipe.Is_Loaded;

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class);

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Recipe  : in Porion.Builds.Models.Recipe_Ref;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class);

   procedure Update_Parameters (Service : in out Context_Type;
                                Step    : in out Builds.Models.Recipe_Step_Ref;
                                Config  : in out Porion.Configs.Config_Type);

   procedure Update (Service : in out Context_Type;
                     Config  : in out Build_Config);

   procedure Update (Service : in out Context_Type;
                     Configs : in out Build_Config_Vector);

   procedure Make_Recipes (Service  : in out Context_Type;
                           Branch   : in String;
                           Executor : in out Porion.Executors.Executor_Type'Class) with
     Pre => Service.Is_Open and Service.Has_Project;

   --  Load the recipes of a project according to the identification.
   procedure Load_Recipes (Service : in out Context_Type;
                           Ident   : in Porion.Projects.Ident_Type;
                           List    : in out Porion.Builds.Models.Recipe_Vector) with
     Pre => Service.Is_Open;

   procedure Copy_Recipe (Service  : in out Context_Type;
                          Project  : in String;
                          Branch   : in String;
                          Node     : in String;
                          Recipe   : in out Models.Recipe_Ref);

   procedure Guess (Service  : in out Context_Type;
                    Path     : in String;
                    Executor : in out Porion.Executors.Executor_Type'Class);

   procedure Find_Build_Configs (Service : in out Context_Type;
                                 Force   : in Boolean;
                                 List    : in out Porion.Builds.Models.Recipe_Vector);

   --  Add in the build queue the recipes for the current branch and use the given
   --  reason for adding them in the build queue.
   procedure Add_Build_Queue (Service : in out Context_Type;
                              Reason  : in Porion.Builds.Models.Reason_Type;
                              Added   : out Boolean) with
      Pre => Service.Is_Open and Service.Has_Project;

   --  Add in the build queue the given recipe with the reason for adding it
   --  in the build queue.
   procedure Add_Build_Queue (Service : in out Context_Type;
                              Recipe  : in out Porion.Builds.Models.Recipe_Ref;
                              Reason  : in Porion.Builds.Models.Reason_Type;
                              Added   : out Boolean) with
      Pre => Service.Is_Open and Service.Has_Project and not Recipe.Is_Null;

   --  Update the build queue to trigger builds and/or re-order the build queue according
   --  to the build dependency.
   procedure Update_Build_Queue (Service : in out Context_Type;
                                 Trigger_Builds : in Boolean) with
      Pre => Service.Is_Open and Service.Has_Project
             and (not Trigger_Builds or Service.Has_Branch);

   --  Get the build queue size.
   function Get_Queue_Size (Service : in Context_Type) return Natural
      with Pre => Service.Is_Open;

private

   --  Returns True if the recipe is contained in the build queue.
   function Contains (List   : in Porion.Builds.Models.Build_Queue_Vector;
                      Recipe : in Porion.Builds.Models.Recipe_Ref) return Boolean
      with Pre => not Recipe.Is_Null;

   function Get_Build_Directory (Service : in Context_Type) return String;

   procedure Build (Service     : in out Context_Type;
                    Steps       : in Build_Step_Vector;
                    Executor    : in out Porion.Executors.Executor_Type'Class);

   procedure Update_Build (Service : in out Context_Type;
                           Status  : in Builds.Models.Build_Status_Type);

   procedure Load_Environment (Service : in out Context_Type;
                               Recipe  : in Models.Recipe_Ref);

   procedure Load_Recipe (Service : in out Context_Type;
                          Recipe  : in Models.Recipe_Ref;
                          Steps   : in out Build_Step_Vector) with
      Pre  => Service.Has_Project and not Recipe.Is_Null,
      Post => Service.Has_Branch;

   --  Update the build reason when starting the build or once it is finished.
   procedure Update_Build_Reason (Service     : in out Context_Type;
                                  Is_Finished : in Boolean) with
      Pre => not Service.Queue.Is_Null;

   --  Update the ratings on the branch when a build is finished.
   procedure Update_Branch_Ratings (Service : in out Context_Type) with
      Pre => Service.Has_Project and Service.Has_Branch and Service.Has_Build;

   --  Update the ratings on the project by looking at the branches.
   procedure Update_Project_Ratings (Service : in out Context_Type) with
      Pre => Service.Has_Project;

end Porion.Builds.Services;
