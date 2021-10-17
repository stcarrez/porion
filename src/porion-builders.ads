-----------------------------------------------------------------------
--  porion-builders -- Continuous integration controller
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
with Util.Strings.Vectors;
with Util.Serialize.IO;
with ADO.Sessions;
with Porion.Configs;
with Porion.Builds.Models;
with Porion.Executors;
private package Porion.Builders is

   MAX_PARAM_SIZE : constant := 64 * 1024;

   subtype Builder_Type is Porion.Builds.Models.Builder_Type;
   subtype String_Vector is Util.Strings.Vectors.Vector;

   --  Run the builder with the parameters.
   procedure Run (Builder    : in Builder_Type;
                  Session    : in ADO.Sessions.Master_Session;
                  Parameters : in Configs.Config_Type;
                  Build      : in out Builds.Models.Build_Ref;
                  Path       : in String;
                  Executor   : in out Executors.Executor_Type'Class);

   --  Save the parameters for the builder configuration.
   function Save_Configuration (Builder    : in Builder_Type;
                                Session    : in ADO.Sessions.Master_Session;
                                Parameters : in String_Vector) return String;

   function Save_Configuration (Builder    : in Builder_Type;
                                Session    : in ADO.Sessions.Master_Session;
                                Parameters : in Configs.Config_Type) return String;

private

   type Controller_Type is limited interface;

   type Controller_Access is access all Controller_Type'Class;

   procedure Build (Controller : in out Controller_Type;
                    Build      : in out Builds.Models.Build_Ref;
                    Path       : in String;
                    Executor   : in out Executors.Executor_Type'Class) is abstract;

   procedure Clean (Controller : in out Controller_Type) is abstract;

   procedure Configure (Controller : in out Controller_Type;
                        Parameters : in String_Vector) is null;

   procedure Print (Controller : in out Controller_Type;
                    Stream     : in out Util.Serialize.IO.Output_Stream'Class) is null;

end Porion.Builders;
