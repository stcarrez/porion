-----------------------------------------------------------------------
--  porion-xunit-analysis -- Continuous integration controller
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
with Ada.Containers.Indefinite_Ordered_Maps;
with Util.Strings.Vectors;
with ADO.Sessions;
with Porion.Projects.Models;
with Porion.XUnit.Models;
package Porion.XUnit.Analysis is

   subtype Group_Path is Util.Strings.Vectors.Vector;

   type Test_Type (Length : Positive) is record
      Status   : Porion.XUnit.Models.Test_Status_Type;
      Duration : Natural;
      Test     : Porion.XUnit.Models.Test_Ref;
      Group    : Porion.XUnit.Models.Test_Group_Ref;
      Run      : Porion.XUnit.Models.Test_Run_Ref;
      Name     : String (1 .. Length);
   end record;

   package Test_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type        => String,
      Element_Type    => Test_Type);

   subtype Test_Map is Test_Maps.Map;

   type Test_Group_Type (Length : Positive) is record
      Group : Porion.XUnit.Models.Test_Group_Ref;
      Run   : Porion.XUnit.Models.Test_Run_Group_Ref;
      Path  : Group_Path;
      Tests : Test_Map;
      Name  : String (1 .. Length);
   end record;

   package Test_Group_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type        => String,
      Element_Type    => Test_Group_Type);

   subtype Test_Group_Map is Test_Group_Maps.Map;

   use type ADO.Identifier;

   package Group_Id_Maps is
     new Ada.Containers.Indefinite_Ordered_Maps (Key_Type     => ADO.Identifier,
                                                 Element_Type => String);

   type Test_Results is record
      Groups    : Test_Group_Map;
      Tests     : Test_Map;
      Group_Ids : Group_Id_Maps.Map;
   end record;

   procedure Add_Test (Results  : in out Test_Results;
                       Group    : in Group_Path;
                       Name     : in String;
                       Duration : in Natural;
                       Status   : in Porion.XUnit.Models.Test_Status_Type);

   procedure Save (Results : in out Test_Results;
                   Build   : in out Porion.Projects.Models.Build_Ref;
                   Session : in out ADO.Sessions.Master_Session);

end Porion.XUnit.Analysis;
