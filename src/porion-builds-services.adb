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
with Ada.Calendar;
with Ada.Directories;
with Ada.Unchecked_Deallocation;
with Util.Log.Loggers;
with Util.Strings;
with Util.Streams;
with Util.Streams.Texts;
with Util.Serialize.IO.JSON;
with Util.Properties;
with Util.Properties.JSON;
with Porion.Loggers;
with ADO.Statements;
with ADO.Queries;
with ADO.Sessions;
with Porion.Sources.Factories;
with Porion.Nodes.Models;
with Porion.Projects.Models;
with Porion.Builders.Factories;
package body Porion.Builds.Services is

   use type ADO.Identifier;
   use type Porion.Builders.Controller_Access;

   Log : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builds.Services");

   procedure Free is
     new Ada.Unchecked_Deallocation (Object => Porion.Builders.Controller_Type'Class,
                                     Name   => Porion.Builders.Controller_Access);

   procedure Start_Build (Service     : in out Context_Type;
                          Branch_Name : in String;
                          Branch      : in Porion.Sources.Branch_Type) is
      Query : ADO.Queries.Context;
      Found : Boolean;
      Stmt  : ADO.Statements.Query_Statement;
   begin
      if Service.Build_Node.Is_Null then
         Service.Load_Node ("localhost");
      end if;

      --  Add_Branch (Service, Branch_Name, Branch);

      Query.Set_Query (Projects.Models.Query_Project_Last_Build);
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
      Stmt := Service.DB.Create_Statement (Query);
      Stmt.Execute;

      Service.Build := Porion.Builds.Models.Null_Build;
      Service.Build.Set_Number (Stmt.Get_Result_Integer + 1);

      if Service.Build_Config.Is_Null then
         Query.Clear;
         Query.Bind_Param (1, Service.Project.Get_Id);
         Query.Bind_Param (2, Service.Build_Node.Get_Id);
         Query.Set_Filter ("o.project_id = ? AND o.node_id = ?");
         Service.Build_Config.Find (Service.DB, Query, Found);
         if not Found then
            Service.Build_Config.Set_Node (Service.Build_Node);
            Service.Build_Config.Set_Project (Service.Project);
            Service.Build_Config.Save (Service.DB);
         end if;
      end if;

      Service.Build.Set_Project (Service.Project);
      Service.Build.Set_Branch (Service.Branch);
      Service.Build.Set_Node (Service.Build_Node);
      Service.Build.Set_Build_Config (Service.Build_Config);
      Service.Build.Set_Create_Date (Ada.Calendar.Clock);
      Service.Build.Save (Service.DB);

      Service.Last_Build.Set_Build (Service.Build);
      Service.Last_Build.Set_Build_Config (Service.Build_Config);
      Service.Last_Build.Set_Branch (Service.Branch);
      Service.Last_Build.Set_Status (Porion.Builds.Models.BUILD_RUNNING);
      Service.Last_Build.Save (Service.DB);
      Service.DB.Commit;

      Log.Info ("Created build{0} for {1}", Natural'Image (Service.Build.Get_Number),
                Service.Project.Get_Name);
   end Start_Build;

   procedure Build (Service     : in out Context_Type;
                    Branch_Name : in String;
                    Branch      : in Porion.Sources.Branch_Type) is
   begin
      Start_Build (Service, Branch_Name, Branch);

      Service.Load_Environment;
      Service.Load_Build_Steps;

      declare
         Number  : constant Positive := Service.Build.Get_Number;
         Name    : constant String := Service.Project.Get_Name;
         Path    : constant String := Configs.Get_Build_Directory (Name, Branch_Name, Number);
         Log_Dir : constant String := Configs.Get_Build_Log_Directory (Name, Branch_Name, Number);
         Config  : Util.Properties.Manager;
         Logger  : Porion.Loggers.Logger_Type;
      begin
         Log.Info ("Build {0} in {1}", Name, Path);

         if not Ada.Directories.Exists (Path) then
            Ada.Directories.Create_Path (Path);
         end if;

         Config.Set ("repository_url", String '(Service.Project.Get_Scm_Url));
         Service.Source_Controller := Sources.Factories.Create (Service.Project.Get_Scm, Config);

         Logger.Create (Log_Dir, "build.log");
         Service.Source_Controller.Checkout (Path, Logger);

         Config.Set ("build_dir", Path);
         for Step of Service.Steps loop
            Service.Build_Controller
              := Builders.Factories.Create (Step.Step.Get_Builder, Service.DB, Step.Config);
            Service.Build_Controller.Build (Service.Build, Path, Logger);
         end loop;

         Service.Build.Set_Finish_Date (ADO.Nullable_Time '(Is_Null => False,
                                                            Value => Ada.Calendar.Clock));
         Service.Build.Save (Service.DB);
      end;
   end Build;

   procedure Load_Config (Service : in out Context_Type) is
      Query : ADO.Queries.Context;
      Found : Boolean;
   begin
      if Service.Build_Node.Is_Null then
         Service.Load_Node ("localhost");
      end if;

      if Service.Build_Config.Is_Null then
         Query.Bind_Param (1, Service.Project.Get_Id);
         Query.Bind_Param (2, Service.Build_Node.Get_Id);
         Query.Set_Filter ("o.project_id = ? AND o.node_id = ?");
         Service.Build_Config.Find (Service.DB, Query, Found);
         if not Found then
            Service.Build_Config.Set_Node (Service.Build_Node);
            Service.Build_Config.Set_Project (Service.Project);
            Service.Build_Config.Save (Service.DB);
         end if;
      end if;

      Service.Load_Build_Steps;
      Service.Load_Environment;
   end Load_Config;

   procedure Load_Environment (Service : in out Context_Type) is
      Envs  : Porion.Builds.Models.Environment_Vector;
      Query : ADO.Queries.Context;
   begin
      Service.Environments.Clear;
      Query.Set_Filter ("(o.build_config_id = :config_id OR o.node_id = :node_id)"
                        & " OR (o.build_config_id IS NULL AND o.node_id IS NULL)");
      Query.Bind_Param ("config_id", Service.Build_Config.Get_Id);
      Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
      Porion.Builds.Models.List (Envs, Service.DB, Query);


   end Load_Environment;

   procedure Load_Build_Steps (Service : in out Context_Type) is
      Steps : Porion.Builds.Models.Build_Step_Vector;
      Query : ADO.Queries.Context;
   begin
      Service.Steps.Clear;
      Query.Set_Filter ("o.build_config_id = :config_id ORDER BY o.number");
      Query.Bind_Param ("config_id", Service.Build_Config.Get_Id);
      Porion.Builds.Models.List (Steps, Service.DB, Query);

      for DB_Step of Steps loop
         declare
            Step : Build_Step;
            Params : constant String := DB_Step.Get_Parameters;
         begin
            Step.Step := DB_Step;
            if Params'Length > 0 then
               Util.Properties.JSON.Parse_JSON (Step.Config, Params);
            end if;
            Service.Steps.Append (Step);
         end;
      end loop;

      Log.Info ("Loaded{0} build steps",
                Ada.Containers.Count_Type'Image (Service.Steps.Length));
   end Load_Build_Steps;

   --  Delete the build step at the given execution order.
   procedure Delete_Step (Service  : in out Context_Type;
                          Position : in Natural) is
      Last : constant Natural := Natural (Service.Steps.Length);
   begin
      if Position > Last then
         raise Program_Error;
      end if;

      Service.DB.Begin_Transaction;
      declare
         Step : Build_Step := Service.Steps.Element (Position);
      begin
         Step.Step.Delete (Service.DB);
         Service.Steps.Delete (Position);
      end;
      for I in Position .. Last - 1 loop
         declare
            Step : Build_Step := Service.Steps.Element (I);
         begin
            Step.Step.Set_Number (I);
            Step.Step.Save (Service.DB);
         end;
      end loop;
      Service.DB.Commit;
   end Delete_Step;

   procedure Insert_Step (Service   : in out Context_Type;
                          Position  : in Natural;
                          Kind      : in Porion.Builds.Models.Builder_Type;
                          Arguments : in Util.Strings.Vectors.Vector) is
      use Porion.Builds.Models;

      Config     : Porion.Configs.Config_Type;
      Controller : Porion.Builders.Controller_Access
        := Porion.Builders.Factories.Create (Kind, Service.DB, Config);
      Output : aliased Util.Streams.Texts.Print_Stream;
      Stream : Util.Serialize.IO.JSON.Output_Stream;
   begin
      if Controller = null then
         Log.Error ("No builder for {0}", Builder_Type'Image (Kind));
         return;
      end if;
      Controller.Configure (Arguments);

      Output.Initialize (Size => 10000);
      Stream.Initialize (Output => Output'Unchecked_Access);
      Stream.Start_Document;
      Controller.Print (Stream);
      Stream.End_Document;

      Free (Controller);

      declare
         Step : Build_Step;
         Pos  : Natural := Position;
      begin
         if Pos = 0 then
            Pos := Natural (Service.Steps.Length);
         end if;
         Service.Steps.Insert (Pos, Step);
         Step.Step.Set_Parameters (Util.Streams.Texts.To_String (Output));
         Step.Step.Set_Builder (Kind);
         Step.Step.Set_Number (Pos);
         Step.Step.Set_Step (Porion.Builds.Models.STEP_MAKE);
         Step.Step.Set_Build_Config (Service.Build_Config);
         Step.Step.Save (Service.DB);

         Pos := Pos + 1;
         while Pos < Natural (Service.Steps.Length) loop
            Step := Service.Steps.Element (Pos);
            Step.Step.Set_Number (Pos);
            Step.Step.Save (Service.DB);
            Pos := Pos + 1;
         end loop;
      end;
   end Insert_Step;

   function Get_Build (Service : in Context_Type) return Porion.Builds.Models.Build_Ref is
   begin
      return Service.Build;
   end Get_Build;

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class) is
      Build_Configs : Porion.Builds.Models.Build_Config_Vector;
      Query         : ADO.Queries.Context;
   begin
      Query.Set_Filter ("o.project_id = :project_id");
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Porion.Builds.Models.List (Build_Configs, Service.DB, Query);

      Stream.Start_Array ("build_configs");
      for Build_Config of Build_Configs loop
         Service.Export (Build_Config, Stream);
      end loop;
      Stream.End_Array ("build_configs");
   end Export;

   --  Export some information about the project in the output stream.
   procedure Export (Service : in out Context_Type;
                     Build_Config : in Porion.Builds.Models.Build_Config_Ref;
                     Stream  : in out Util.Serialize.IO.Output_Stream'Class) is
   begin
      Stream.Start_Entity ("build_config");
      Stream.Write_Attribute ("id", Integer (Build_Config.Get_Id));
      Stream.Write_Attribute ("version", Build_Config.Get_Version);
      if not Build_Config.Get_Node.Is_Null then
         Stream.Start_Entity ("node");
         Stream.Write_Attribute ("id", Integer (Build_Config.Get_Node.Get_Id));
         Stream.End_Entity ("node");
      end if;

      --  Load the build steps.
      declare
         Steps : Porion.Builds.Models.Build_Step_Vector;
         Query : ADO.Queries.Context;
      begin
         Query.Set_Filter ("o.build_config_id = :config_id ORDER BY o.number");
         Query.Bind_Param ("config_id", Build_Config.Get_Id);
         Porion.Builds.Models.List (Steps, Service.DB, Query);

         if not Steps.Is_Empty then
            Stream.Start_Array ("steps");
            for Step of Steps loop
               Stream.Start_Entity ("step");
               Stream.Write_Attribute ("id", Integer (Step.Get_Id));
               Stream.Write_Attribute ("version", Step.Get_Version);
               Stream.Write_Entity ("number", Step.Get_Number);
               Stream.Write_Entity ("timeout", Step.Get_Timeout);
               Stream.Write_Entity ("builder", Step.Get_Builder'Image);
               Stream.Write_Entity ("step", Step.Get_Step'Image);
               Stream.Start_Entity ("parameters");
               declare
                  Params : constant String := Step.Get_Parameters;
                  Config : Porion.Configs.Config_Type;

                  procedure Print (Name : in String;
                                   Value : Util.Properties.Value) is
                  begin
                     Stream.Start_Entity ("parameter");
                     Stream.Write_Attribute ("name", Name);
                     Stream.Write_Entity ("value", Value);
                     Stream.End_Entity ("parameter");
                  end Print;

               begin
                  if Params'Length > 0 then
                     Config := Util.Serialize.IO.JSON.Read (Params);
                     Config.Iterate (Print'Access);
                  end if;
               end;
               Stream.End_Entity ("parameters");
               Stream.End_Entity ("step");
            end loop;
            Stream.End_Array ("steps");
         end if;
      end;

      --  Load the environment variables.
      declare
         Envs  : Porion.Builds.Models.Environment_Vector;
         Query : ADO.Queries.Context;
      begin
         Query.Set_Filter ("o.build_config_id = :config_id");
         Query.Bind_Param ("config_id", Service.Build_Config.Get_Id);
         Porion.Builds.Models.List (Envs, Service.DB, Query);

         if not Envs.Is_Empty then
            Stream.Start_Array ("environments");
            for Env of Envs loop
               Stream.Start_Entity ("environment");
               Stream.Write_Attribute ("id", Integer (Env.Get_Id));
               Stream.Write_Attribute ("version", Env.Get_Version);
               Stream.Write_Entity ("name", String '(Env.Get_Name));
               Stream.Write_Entity ("value", String '(Env.Get_Value));
               Stream.End_Entity ("environment");
            end loop;
            Stream.End_Array ("environments");
         end if;
      end;

      Stream.End_Entity ("build_config");
   end Export;

   procedure Update_Parameters (Service : in out Context_Type;
                                Step    : in out Build_Step) is
      Kind       : constant Models.Builder_Type := Step.Step.Get_Builder;
      Controller : Porion.Builders.Controller_Access;
      Output     : aliased Util.Streams.Texts.Print_Stream;
      Stream     : Util.Serialize.IO.JSON.Output_Stream;
   begin
      Controller := Builders.Factories.Create (Kind, Service.DB, Step.Config);
      if Controller = null then
         Log.Error ("No builder for {0}", Models.Builder_Type'Image (Kind));
         return;
      end if;

      Output.Initialize (Size => 10000);
      Stream.Initialize (Output => Output'Unchecked_Access);
      Stream.Start_Document;
      Controller.Print (Stream);
      Stream.End_Document;

      Free (Controller);

      Step.Step.Set_Parameters (Util.Streams.Texts.To_String (Output));
   end Update_Parameters;

   procedure Update (Service : in out Context_Type;
                     Config  : in out Build_Config) is
      procedure Remove (List : in out Models.Build_Step_Vector;
                        Id   : in ADO.Identifier);

      procedure Remove (List : in out Models.Build_Step_Vector;
                        Id   : in ADO.Identifier) is
         Iter : Models.Build_Step_Vectors.Cursor := List.First;
      begin
         while Models.Build_Step_Vectors.Has_Element (Iter) loop
            if Models.Build_Step_Vectors.Element (Iter).Get_Id = Id then
               List.Delete (Iter);
               return;
            end if;
            Models.Build_Step_Vectors.Next (Iter);
         end loop;
      end Remove;

      Config_Id : constant ADO.Identifier := Config.Config.Get_Id;
      Steps     : Models.Build_Step_Vector;
      Query     : ADO.Queries.Context;
      Rank      : Natural := 0;
   begin
      Log.Info ("Update build config {0}", Config_Id'Image);

      Query.Set_Filter ("o.build_config_id = :config_id ORDER BY o.number");
      Query.Bind_Param ("config_id", Config_Id);
      Models.List (Steps, Service.DB, Query);

      --  Step 1: update and insert the build steps.
      for Pos in Config.Steps.Iterate loop
         declare
            Step_Ref : constant Build_Step_Vectors.Reference_Type := Config.Steps.Reference (Pos);
         begin
            Rank := Rank + 1;
            Step_Ref.Step.Set_Number (Rank);
            Service.Update_Parameters (Step_Ref.Element.all);
            if Step_Ref.Step.Is_Loaded then
               if Step_Ref.Step.Is_Modified then
                  Step_Ref.Step.Save (Service.DB);
               end if;

               Remove (Steps, Step_Ref.Step.Get_Id);
            else
               Step_Ref.Step.Set_Build_Config (Config.Config);
               Step_Ref.Step.Save (Service.DB);
            end if;
         end;
      end loop;

      --  Step 2: remove the build steps.
      for To_Delete_Step of Steps loop
         To_Delete_Step.Delete (Service.DB);
      end loop;
   end Update;

   procedure Update (Service : in out Context_Type;
                     Configs : in out Build_Config_Vector) is
      procedure Remove (List : in out Models.Build_Config_Vector;
                        Id   : in ADO.Identifier);

      procedure Remove (List : in out Models.Build_Config_Vector;
                        Id   : in ADO.Identifier) is
         Iter : Models.Build_Config_Vectors.Cursor := List.First;
      begin
         while Models.Build_Config_Vectors.Has_Element (Iter) loop
            if Models.Build_Config_Vectors.Element (Iter).Get_Id = Id then
               List.Delete (Iter);
               return;
            end if;
            Models.Build_Config_Vectors.Next (Iter);
         end loop;
      end Remove;

      Project_Id    : constant ADO.Identifier := Service.Project.Get_Id;
      Build_Configs : Models.Build_Config_Vector;
      Query         : ADO.Queries.Context;
   begin
      Log.Info ("Update build configs for{0}", Project_Id'Image);

      Query.Set_Filter ("o.project_id = :project_id");
      Query.Bind_Param ("project_id", Project_Id);
      Porion.Builds.Models.List (Build_Configs, Service.DB, Query);

      Service.DB.Begin_Transaction;

      --  Step 1: update the existing configs and create the new one.
      for Pos in Configs.Iterate loop
         declare
            Config_Ref : constant Build_Config_Vectors.Reference_Type
              := Configs.Reference (Pos);
         begin
            if Config_Ref.Config.Is_Loaded then
               if Config_Ref.Config.Is_Modified then
                  Config_Ref.Config.Save (Service.DB);
               end if;

               Service.Update (Config_Ref.Element.all);
               Remove (Build_Configs, Config_Ref.Config.Get_Id);
            else
               Config_Ref.Config.Save (Service.DB);
            end if;
         end;
      end loop;

      --  Step 2: remove the build configs
      for To_Delete_Config of Build_Configs loop
         To_Delete_Config.Delete (Service.DB);
      end loop;
      Service.DB.Commit;
   end Update;

end Porion.Builds.Services;
