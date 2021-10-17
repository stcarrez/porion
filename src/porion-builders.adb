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
with Ada.Unchecked_Deallocation;

with Util.Log.Loggers;
with Util.Streams;
with Util.Streams.Texts;
with Util.Serialize.IO.JSON;

with Porion.Builders.Factories;
package body Porion.Builders is

   Log   : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.Builders");

   procedure Free is
     new Ada.Unchecked_Deallocation (Object => Controller_Type'Class,
                                     Name   => Controller_Access);

   --  ------------------------------
   --  Run the builder with the parameters.
   --  ------------------------------
   procedure Run (Builder    : in Builder_Type;
                  Session    : in ADO.Sessions.Master_Session;
                  Parameters : in Configs.Config_Type;
                  Build      : in out Builds.Models.Build_Ref;
                  Path       : in String;
                  Executor   : in out Executors.Executor_Type'Class) is
      Controller : Controller_Access;
   begin
      Controller := Factories.Create (Builder, Session, Parameters);
      if Controller = null then
         Log.Error ("No builder for {0}", Builder_Type'Image (Builder));
         Executor.Set_Status (-1);
         return;
      end if;
      Controller.Build (Build, Path, Executor);
      Free (Controller);
   end Run;

   --  ------------------------------
   --  Save the parameters for the builder configuration.
   --  ------------------------------
   function Save_Configuration (Builder    : in Builder_Type;
                                Session    : in ADO.Sessions.Master_Session;
                                Parameters : in String_Vector) return String is
      Config     : Configs.Config_Type;
      Controller : Controller_Access;
      Output     : aliased Util.Streams.Texts.Print_Stream;
      Stream     : Util.Serialize.IO.JSON.Output_Stream;
   begin
      Controller := Factories.Create (Builder, Session, Config);
      if Controller = null then
         Log.Error ("No builder for {0}", Builder_Type'Image (Builder));
         return "";
      end if;
      Controller.Configure (Parameters);

      Output.Initialize (Size => MAX_PARAM_SIZE);
      Stream.Initialize (Output => Output'Unchecked_Access);
      Stream.Start_Document;
      Controller.Print (Stream);
      Stream.End_Document;

      Free (Controller);
      return Util.Streams.Texts.To_String (Output);
   end Save_Configuration;

   function Save_Configuration (Builder    : in Builder_Type;
                                Session    : in ADO.Sessions.Master_Session;
                                Parameters : in Configs.Config_Type) return String is
      Controller : Controller_Access;
      Output     : aliased Util.Streams.Texts.Print_Stream;
      Stream     : Util.Serialize.IO.JSON.Output_Stream;
   begin
      Controller := Factories.Create (Builder, Session, Parameters);
      if Controller = null then
         Log.Error ("No builder for {0}", Builder_Type'Image (Builder));
         return "";
      end if;

      Output.Initialize (Size => MAX_PARAM_SIZE);
      Stream.Initialize (Output => Output'Unchecked_Access);
      Stream.Start_Document;
      Controller.Print (Stream);
      Stream.End_Document;

      Free (Controller);
      return Util.Streams.Texts.To_String (Output);
   end Save_Configuration;

end Porion.Builders;
