-----------------------------------------------------------------------
--  porion-templates-export -- Export a project to generate a build template
--  Copyright (C) 2022, 2026 Stephane Carrez
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
with ADO.Queries;
with Util.Properties;
with Util.Beans.Objects;
with Util.Serialize.IO.JSON;
with Porion.Configs;
with Porion.Builds.Models;
with Porion.Projects.Models;

package body Porion.Templates.Export is

   package UBO renames Util.Beans.Objects;

   type Recipe_Context_Type is record
      Timeout : Util.Nullables.Nullable_Integer;
      Ignore  : Util.Nullables.Nullable_Boolean;
   end record;

   procedure Export (Service : in out Porion.Services.Context_Type;
                     Recipe  : in Porion.Builds.Models.Recipe_Ref;
                     File    : in out Ada.Text_IO.File_Type);

   procedure Export_Timeout (Context : in out Recipe_Context_Type;
                             Timeout : in Natural;
                             File    : in out Ada.Text_IO.File_Type);

   procedure Export (Service : in out Porion.Services.Context_Type;
                     Step    : in Porion.Builds.Models.Recipe_Step_Ref;
                     Context : in out Recipe_Context_Type;
                     File    : in out Ada.Text_IO.File_Type);

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Porion.Services.Context_Type;
                     File    : in out Ada.Text_IO.File_Type) is
      Recipes : Porion.Builds.Models.Recipe_Vector;
      Query   : ADO.Queries.Context;
   begin
      Query.Set_Filter ("o.project_id = :project_id");
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Porion.Builds.Models.List (Recipes, Service.DB, Query);

      for Recipe of Recipes loop
         Export (Service, Recipe, File);
      end loop;
   end Export;

   procedure Export_Timeout (Context : in out Recipe_Context_Type;
                             Timeout : in Natural;
                             File    : in out Ada.Text_IO.File_Type) is
   begin
      if Context.Timeout.Is_Null or else Context.Timeout.Value /= Timeout then
         Ada.Text_IO.Put (File, "    set timeout");
         Ada.Text_IO.Put (File, Timeout'Image);
         Ada.Text_IO.Put_Line (File, ";");
         Context.Timeout.Is_Null := False;
         Context.Timeout.Value := Timeout;
      end if;
   end Export_Timeout;

   procedure Export (Service : in out Porion.Services.Context_Type;
                     Step    : in Porion.Builds.Models.Recipe_Step_Ref;
                     Context : in out Recipe_Context_Type;
                     File    : in out Ada.Text_IO.File_Type) is
      pragma Unreferenced (Service);
      use Porion.Builds;
      use type Porion.Builds.Models.Builder_Type;

      procedure Print (Name : in String;
                       Value : Util.Properties.Value);

      Kind    : constant Porion.Builds.Step_Type := Step.Get_Step;
      Builder : constant Porion.Builds.Models.Builder_Type := Step.Get_Builder;
      Params  : constant String := Step.Get_Parameters;
      Config  : Porion.Configs.Config_Type;
      Metric_Name  : UString;
      Metric_Value : UString;

      procedure Print (Name  : in String;
                       Value : Util.Properties.Value) is
      begin
         if Name = "command" then
            Ada.Text_IO.Put (File, """");
            Ada.Text_IO.Put (File, Util.Properties.To_String (Value));
            Ada.Text_IO.Put (File, """");
         elsif Name = "metric" then
            Metric_Name := To_UString (Util.Properties.To_String (Value));
         elsif Name = "params" then
            Metric_Value := To_UString (Util.Properties.To_String (Value));
         elsif UBO.Is_Array (Value) then
            for I in 1 .. UBO.Get_Count (Value) loop
               if I > 1 then
                  Ada.Text_IO.Put (File, " ");
               end if;
               Ada.Text_IO.Put (File, """");
               Ada.Text_IO.Put (File, UBO.To_String (UBO.Get_Value (Value, I)));
               Ada.Text_IO.Put (File, """");
            end loop;
         else
            Ada.Text_IO.Put (File, """");
            Ada.Text_IO.Put (File, Util.Properties.To_String (Value));
            Ada.Text_IO.Put (File, """");
         end if;
      end Print;

   begin
      Export_Timeout (Context, Step.Get_Timeout, File);
      Ada.Text_IO.Put (File, "    ");
      case Kind is
         when STEP_CHECKOUT =>
            null;
         when STEP_SETUP =>
            Ada.Text_IO.Put (File, "as setup run ");
         when STEP_CONFIGURE =>
            Ada.Text_IO.Put (File, "as configure run ");
         when STEP_GENERATE =>
            Ada.Text_IO.Put (File, "as generate run ");
         when STEP_MAKE =>
            Ada.Text_IO.Put (File, "run ");
         when STEP_PACKAGE =>
            Ada.Text_IO.Put (File, "as package run ");
         when STEP_INSTALL =>
            Ada.Text_IO.Put (File, "as install run ");
         when STEP_PUBLISH =>
            Ada.Text_IO.Put (File, "as publish run ");
         when STEP_METRIC =>
            if Builder = Porion.Builds.Models.BUILDER_METRIC then
               Ada.Text_IO.Put (File, "metric");
            else
               Ada.Text_IO.Put (File, "as metric run ");
            end if;
         when STEP_TEST =>
            if Builder = Porion.Builds.Models.BUILDER_XUNIT then
               Ada.Text_IO.Put (File, "xunit ");
            else
               Ada.Text_IO.Put (File, "as test run ");
            end if;
      end case;

      Config := Util.Serialize.IO.JSON.Read (Params);
      Config.Iterate (Print'Access);
      if Length (Metric_Name) > 0 then
         Ada.Text_IO.Put (File, " ");
         Ada.Text_IO.Put (File, To_String (Metric_Name));
         if Length (Metric_Value) > 0 then
            Ada.Text_IO.Put (File, " ");
            Ada.Text_IO.Put (File, To_String (Metric_Value));
         end if;
      end if;
      Ada.Text_IO.Put_Line (File, ";");
   end Export;

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Porion.Services.Context_Type;
                     Recipe  : in Porion.Builds.Models.Recipe_Ref;
                     File   : in out Ada.Text_IO.File_Type) is
      Name    : constant String := Recipe.Get_Name;
   begin
      Ada.Text_IO.Put (File, "  recipe ");
      Ada.Text_IO.Put (File, Name);
      if not Recipe.Get_Node.Is_Null then
         Ada.Text_IO.Put (File, " on ");
         Ada.Text_IO.Put (File, Recipe.Get_Node.Get_Name);
      end if;
      Ada.Text_IO.Put_Line (File, " is");
      declare
         Description : constant String := Recipe.Get_Description;
      begin
         if Description'Length > 0 then
            Ada.Text_IO.Put (File, "    set description """);
            Ada.Text_IO.Put (File, Description);
            Ada.Text_IO.Put_Line (File, """;");
         end if;
      end;
      Ada.Text_IO.Put (File, "    set filtering """);
      Ada.Text_IO.Put (File, Recipe.Get_Filter_Rules);
      Ada.Text_IO.Put_Line (File, """;");

      --  Load the build steps.
      declare
         Steps   : Porion.Builds.Models.Recipe_Step_Vector;
         Query   : ADO.Queries.Context;
         Context : Recipe_Context_Type;
      begin
         Query.Set_Filter ("o.recipe_id = :recipe_id AND "
                           & "o.next_version_id IS NULL ORDER BY o.number");
         Query.Bind_Param ("recipe_id", Recipe.Get_Id);
         Porion.Builds.Models.List (Steps, Service.DB, Query);

         for Step of Steps loop
            Export (Service, Step, Context, File);
         end loop;
      end;

      --  Load the environment variables.
      declare
         Envs  : Porion.Builds.Models.Environment_Vector;
         Query : ADO.Queries.Context;
      begin
         Query.Set_Filter ("o.recipe_id = :recipe_id");
         Query.Bind_Param ("recipe_id", Recipe.Get_Id);
         Porion.Builds.Models.List (Envs, Service.DB, Query);

         if not Envs.Is_Empty then
            for Env of Envs loop
               Ada.Text_IO.Put (File, "   ");
               Ada.Text_IO.Put (File, Env.Get_Name);
               Ada.Text_IO.Put (File, " := """);
               Ada.Text_IO.Put (File, Env.Get_Value);
               Ada.Text_IO.Put_Line (File, """;");
            end loop;
         end if;
      end;

      Ada.Text_IO.Put (File, "   end ");
      Ada.Text_IO.Put (File, Name);
      Ada.Text_IO.Put_Line (File, ";");
   end Export;

   procedure Export (Service : in out Porion.Services.Context_Type;
                     Path    : in String) is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (File => File, Mode => Ada.Text_IO.Out_File, Name => Path);
      declare
         Name : constant String := Service.Project.Get_Name;
      begin
         Ada.Text_IO.Put (File, "build ");
         Ada.Text_IO.Put (File, Name);
         Ada.Text_IO.Put_Line (File, " is");
         Export (Service, File);
         Ada.Text_IO.Put (File, "end ");
         Ada.Text_IO.Put (File, Name);
         Ada.Text_IO.Put_Line (File, ";");
      end;
      Ada.Text_IO.Close (File);
   end Export;

end Porion.Templates.Export;
