-----------------------------------------------------------------------
--  porion-builders-xunit -- Builder to start the analysis of unit tests
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
with ADO.Sessions;
with Porion.Configs;
with Porion.Builds.Models;
package Porion.Builders.XUnit is

   NAME : constant String := "xunit";

   type Controller_Type is limited new Porion.Builders.Controller_Type with private;

   overriding
   procedure Build (Controller : in out Controller_Type;
                    Build      : in out Porion.Builds.Models.Build_Ref;
                    Path       : in String;
                    Logger     : in out Porion.Loggers.Logger_Type);

   overriding
   procedure Clean (Controller : in out Controller_Type);

   overriding
   procedure Configure (Controller : in out Controller_Type;
                        Parameters : in Util.Strings.Vectors.Vector);

   overriding
   procedure Print (Controller : in out Controller_Type;
                    Stream     : in out Util.Serialize.IO.Output_Stream'Class);

   function Create (Session : in ADO.Sessions.Master_Session;
                    Config  : in Porion.Configs.Config_Type) return Controller_Access;

private

   type Controller_Type is limited new Porion.Builders.Controller_Type with record
      Config   : Porion.Configs.Config_Type;
      Session  : ADO.Sessions.Master_Session;
      Includes : Util.Strings.Vectors.Vector;
      Excludes : Util.Strings.Vectors.Vector;
   end record;

   type XUnit_Controller_Access is access all Controller_Type'Class;

end Porion.Builders.XUnit;
