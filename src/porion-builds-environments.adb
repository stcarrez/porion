-----------------------------------------------------------------------
--  porion-builds-environments -- Environment variables to execute build recipes
--  Copyright (C) 2023, 2024 Stephane Carrez
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
with Ada.Strings.Fixed;
with ADO.Queries;
with Util.Strings.Sets;
package body Porion.Builds.Environments is

   use Ada.Strings.Unbounded;

   --  ------------------------------
   --  Load the environment variable definitions to execute the recipe.
   --  ------------------------------
   procedure Load (Env     : in out Environment_Type;
                   Service : in out Porion.Services.Context_Type) is
      Envs  : Porion.Builds.Models.Variable_Info_Vector;
      Query : ADO.Queries.Context;
   begin
      Query.Set_Query (Porion.Builds.Models.Query_Build_Variables);
      Query.Bind_Param ("project_id", Service.Project.Get_Id);
      Query.Bind_Param ("branch_id", Service.Branch.Get_Id);
      Query.Bind_Param ("recipe_id", Service.Recipe.Get_Id);
      Query.Bind_Param ("node_id", Service.Build_Node.Get_Id);
      Porion.Builds.Models.List (Envs, Service.DB, Query);
      for Item of Envs loop
         declare
            Var : Variable_Type;
         begin
            Var.Var := Item;
            if Item.Secret then
               Var.Content := Service.Get_Secret (To_String (SECRET_PREFIX & Item.Name));
            else
               Var.Content := Item.Value;
            end if;
            Env.Vars.Append (Var);
         end;
      end loop;
   end Load;

   --  ------------------------------
   --  Prepare the environment to execute the given step number.
   --  ------------------------------
   procedure Prepare (Env  : in out Environment_Type;
                      Step : in Positive;
                      Node : in Porion.Nodes.Controller_Access) is
      Prev : Util.Strings.Sets.Set;
   begin
      Env.Env.Clear;
      for Item of Env.Vars loop
         declare
            Name : constant String := To_String (Item.Var.Name);
         begin
            if not Prev.Contains (Name) then
               Prev.Insert (Name);
               Env.Prepare (Node, Item);
            end if;
         end;
      end loop;
      Node.Set_Environment (Env.Env);
   end Prepare;

   procedure Prepare (Env  : in out Environment_Type;
                      Node : in Porion.Nodes.Controller_Access;
                      Var  : in Variable_Type) is
   begin
      if Var.Var.Secret then
         null;
      end if;
      case Var.Var.Kind is
         when Models.VAR_FILE =>
            declare
               Path : constant String := Node.Create_Random_Path;
            begin
               Node.Create_File (Path, To_String (Var.Content));
               Env.Env.Include (To_String (Var.Var.Name),
                                Path);
            end;

         when Models.VAR_ENV | Models.VAR_SHELL =>
            Env.Env.Include (To_String (Var.Var.Name),
                             To_String (Var.Content));
      end case;
   end Prepare;

   --  ------------------------------
   --  Cleanup after execution of all build steps.
   --  ------------------------------
   procedure Cleanup (Env  : in out Environment_Type;
                      Node : in Porion.Nodes.Controller_Access) is
   begin
      null;
   end Cleanup;

   function Has_Secrets (Env : in Environment_Type) return Boolean is
   begin
      return not Env.Secrets.Is_Empty;
   end Has_Secrets;

   --  ------------------------------
   --  Filter the line to hide the secrets which are used in the environment.
   --  ------------------------------
   function Filter (Env : in Environment_Type; Line : in String) return String is
      Result : String := Line;
      Pos    : Natural;
   begin
      for Secret of Env.Secrets loop
         Pos := Ada.Strings.Fixed.Index (Line, Secret);
         while Pos >= Line'First and then Pos < Line'Last loop
            Result (Pos .. Pos + Secret'Length - 1) := (others => 'X');
            Pos := Ada.Strings.Fixed.Index (Line, Secret, Pos + Secret'Length);
         end loop;
      end loop;
      return Result;
   end Filter;

end Porion.Builds.Environments;
