-----------------------------------------------------------------------
--  porion-templates-generator -- build recipe generator from a template
--  Copyright (C) 2023 Stephane Carrez
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
with Porion.Builders;
package body Porion.Templates.Generator is

   use Porion.Builds;
   use Porion.Builds.Services;

   function Get_Timeout (Action : in Step_Action) return Natural
     is (if Action.Timeout.Is_Null then 0 else Action.Timeout.Value);

   function Get_Execution (Action : in Step_Action) return Execution_Type
     is (if Action.Ignore.Is_Null or else not Action.Ignore.Value then EXEC_NO_ERROR else EXEC_IGNORE_ERROR);

   procedure Generate (Service : in out Porion.Services.Context_Type;
                       Into    : in out Build_Config_Vector;
                       Recipe  : in Recipe_Type) is
      Config : Build_Config;
      Id     : Natural := 0;
   begin
      Config.Config.Set_Name (Recipe.Name);
      for Step of Recipe.Steps loop
         for Action of Step.Value.Actions loop
            declare
               S : Build_Step;
            begin
               Id := Id + 1;
               S.Step.Set_Number (Id);
               S.Step.Set_Step (Action.Kind);
               S.Step.Set_Timeout (Get_Timeout (Action));
               S.Step.Set_Execution (Get_Execution (Action));
               S.Step.Set_Builder (Action.Builder);
               S.Step.Set_Parameters (Builders.Save_Configuration (Action.Builder, Service.DB, Action.Params));
               Config.Steps.Append (S);
            end;
         end loop;
      end loop;
      Into.Append (Config);
   end Generate;

   procedure Generate (Service    : in out Porion.Services.Context_Type;
                       Template   : in Template_Ref;
                       List       : in out Build_Config_Vector) is
   begin
      for Recipe of Template.Value.Recipes loop
         Generate (Service, List, Recipe.Value);
      end loop;
   end Generate;

end Porion.Templates.Generator;
