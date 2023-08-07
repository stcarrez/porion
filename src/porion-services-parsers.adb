-----------------------------------------------------------------------
--  porion-services-parsers -- Parse project configuration
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
with Ada.Containers;

with Util.Log.Loggers;
with Util.Beans.Objects;
with Util.Beans.Objects.Vectors;
with Util.Serialize.Mappers.Record_Mapper;
with Util.Serialize.IO.XML;

with ADO.Utils;

with Porion.Configs;
with Porion.Sources;
package body Porion.Services.Parsers is

   Log : aliased constant Util.Log.Loggers.Logger
     := Util.Log.Loggers.Create ("Porion.Services.Parsers");

   package UBO renames Util.Beans.Objects;

   use type UBO.Vectors.Vector_Bean_Access;
   use type Ada.Containers.Count_Type;

   type Project_Fields is (PROJECT_ID,
                           PROJECT_VERSION,
                           PROJECT_NAME,
                           PROJECT_DESCRIPTION,
                           PROJECT_STATUS,
                           PROJECT_SCM,
                           PROJECT_SCM_URL,
                           BUILD_CONFIG_ID,
                           BUILD_CONFIG_VERSION,
                           NODE_ID,
                           BUILD_STEP_ID,
                           BUILD_STEP_VERSION,
                           BUILD_STEP_NUMBER,
                           BUILD_STEP_BUILDER,
                           BUILD_STEP_TIMEOUT,
                           BUILD_STEP_STEP,
                           BUILD_STEP_EXECUTION,
                           BUILD_STEP_END,
                           BUILD_PARAM_NAME,
                           BUILD_PARAM_VALUE,
                           BUILD_PARAM_END,
                           BUILD_CONFIG_END);

   type Project_Config is limited record
      Project           : Porion.Projects.Models.Project_Ref;
      Name              : UBO.Object;
      Description       : UBO.Object;
      Project_Id        : UBO.Object;
      Project_Version   : UBO.Object;
      Status            : UBO.Object;
      Param_Name        : UBO.Object;
      Param_Value       : UBO.Object;
      Param_Values_Bean : UBO.Vectors.Vector_Bean_Access;
      Param_Values      : UBO.Object;
      Config_Id         : Util.Beans.Objects.Object;
      Config_Version    : Util.Beans.Objects.Object;
      Node_Id           : Util.Beans.Objects.Object;
      Step              : Porion.Builds.Services.Build_Step;
      Config            : Porion.Builds.Services.Build_Config;
   end record;
   type Project_Config_Access is access all Project_Config;

   procedure  Parse (Service : in out Context_Type'Class;
                     Path    : in String;
                     Result  : in out Parser_Type) is

      procedure Set_Member (N     : in out Project_Config;
                            Field : in Project_Fields;
                            Value : in Util.Beans.Objects.Object);

      procedure Set_Member (N     : in out Project_Config;
                            Field : in Project_Fields;
                            Value : in Util.Beans.Objects.Object) is
         Found : Boolean;
      begin
         case Field is
            when PROJECT_ID =>
               N.Project.Load (Service.DB, ADO.Utils.To_Identifier (Value), Found);
               if not Found then
                  raise Util.Serialize.Mappers.Field_Error with
                    "Project id '" & UBO.To_String (Value) & "' not found";
               end if;

            when PROJECT_VERSION =>
               N.Project_Version := Value;

            when PROJECT_NAME =>
               N.Project.Set_Name (UBO.To_String (Value));

            when PROJECT_DESCRIPTION =>
               N.Project.Set_Description (UBO.To_String (Value));

            when PROJECT_STATUS =>
               N.Project.Set_Status (Projects.Models.Project_Status_Type_Objects.To_Value (Value));

            when PROJECT_SCM =>
               N.Project.Set_Scm (Source_Control_Type_Objects.To_Value (Value));

            when PROJECT_SCM_URL =>
               N.Project.Set_Scm_Url (UBO.To_String (Value));

            when BUILD_CONFIG_ID =>
               N.Config.Config.Load (Service.DB, ADO.Utils.To_Identifier (Value), Found);

            when BUILD_CONFIG_VERSION =>
               N.Config_Version := Value;

            when NODE_ID =>
               N.Node_Id := Value;

            when BUILD_STEP_ID =>
               if N.Config.Config.Is_Loaded then
                  N.Step.Step.Load (Service.DB, ADO.Utils.To_Identifier (Value), Found);
               end if;

            when BUILD_STEP_VERSION =>
               null; --  N.Step_Version := Value;

            when BUILD_STEP_NUMBER =>
               N.Step.Step.Set_Number (UBO.To_Integer (Value));

            when BUILD_STEP_STEP =>
               N.Step.Step.Set_Step (Builds.Step_Type_Objects.To_Value (Value));

            when BUILD_STEP_TIMEOUT =>
               N.Step.Step.Set_Timeout (UBO.To_Integer (Value));

            when BUILD_STEP_BUILDER =>
               N.Step.Step.Set_Builder (Builds.Models.Builder_Type_Objects.To_Value (Value));

            when BUILD_STEP_EXECUTION =>
               N.Step.Step.Set_Execution (Builds.Execution_Type_Objects.To_Value (Value));

            when BUILD_PARAM_NAME =>
               N.Param_Name := Value;

            when BUILD_PARAM_VALUE =>
               N.Param_Value := Value;
               if N.Param_Values_Bean = null then
                  N.Param_Values_Bean := new UBO.Vectors.Vector_Bean;
                  N.Param_Values := UBO.To_Object (Value => N.Param_Values_Bean,
                                                   Storage => UBO.DYNAMIC);
               end if;
               N.Param_Values_Bean.Append (Value);

            when BUILD_PARAM_END =>
               if N.Param_Values_Bean = null or else N.Param_Values_Bean.Length = 1 then
                  N.Step.Config.Set_Value (UBO.To_String (N.Param_Name), N.Param_Value);
               else
                  N.Step.Config.Set_Value (UBO.To_String (N.Param_Name), N.Param_Values);
               end if;
               N.Param_Values := UBO.Null_Object;
               N.Param_Value := UBO.Null_Object;
               N.Param_Values_Bean := null;

            when BUILD_STEP_END =>
               N.Config.Steps.Append (N.Step);
               N.Step.Step := Porion.Builds.Models.Null_Recipe_Step;
               N.Step.Config := Porion.Configs.Null_Config;

            when BUILD_CONFIG_END =>
               Result.Build_Configs.Append (N.Config);
               N.Config.Steps.Clear;
               N.Config.Config := Porion.Builds.Models.Null_Recipe;

         end case;
      end Set_Member;

      package Project_Mapper is
        new Util.Serialize.Mappers.Record_Mapper (Element_Type        => Project_Config,
                                                  Element_Type_Access => Project_Config_Access,
                                                  Fields              => Project_Fields,
                                                  Set_Member          => Set_Member);

      Config : aliased Project_Config;
      Mapper : aliased Project_Mapper.Mapper;
      Parser : Util.Serialize.Mappers.Processing;
      Reader : Util.Serialize.IO.XML.Parser;
   begin
      Mapper.Add_Mapping ("@id", PROJECT_ID);
      Mapper.Add_Mapping ("@version", PROJECT_VERSION);
      Mapper.Add_Mapping ("name", PROJECT_NAME);
      Mapper.Add_Mapping ("description", PROJECT_DESCRIPTION);
      Mapper.Add_Mapping ("status", PROJECT_STATUS);

      Mapper.Add_Mapping ("scm", PROJECT_SCM);
      Mapper.Add_Mapping ("scm_url", PROJECT_SCM_URL);
      Mapper.Add_Mapping ("recipe/@id", BUILD_CONFIG_ID);
      Mapper.Add_Mapping ("recipe/@version", BUILD_CONFIG_VERSION);
      Mapper.Add_Mapping ("recipe/node/@id", NODE_ID);
      Mapper.Add_Mapping ("recipe/step/@id", BUILD_STEP_ID);
      Mapper.Add_Mapping ("recipe/step/@version", BUILD_STEP_VERSION);
      Mapper.Add_Mapping ("recipe/step/number", BUILD_STEP_NUMBER);
      Mapper.Add_Mapping ("recipe/step/timeout", BUILD_STEP_TIMEOUT);
      Mapper.Add_Mapping ("recipe/step/builder", BUILD_STEP_BUILDER);
      Mapper.Add_Mapping ("recipe/step/execution", BUILD_STEP_EXECUTION);
      Mapper.Add_Mapping ("recipe/step/step", BUILD_STEP_STEP);
      Mapper.Add_Mapping ("recipe/step/parameters/parameter/@name", BUILD_PARAM_NAME);
      Mapper.Add_Mapping ("recipe/step/parameters/parameter/value", BUILD_PARAM_VALUE);
      Mapper.Add_Mapping ("recipe/step/parameters/parameter", BUILD_PARAM_END);
      Mapper.Add_Mapping ("recipe/step", BUILD_STEP_END);
      Mapper.Add_Mapping ("recipe", BUILD_CONFIG_END);

      Project_Mapper.Set_Context (Parser, Config'Unchecked_Access);
      Parser.Add_Mapping ("project", Mapper'Unchecked_Access);
      Reader.Set_Logger (Log'Access);
      Reader.Parse (Path, Parser);

      if Reader.Has_Error then
         Log.Error ("Error");
         return;
      end if;

      Result.Project := Config.Project;
   end Parse;

end Porion.Services.Parsers;
