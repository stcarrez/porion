-----------------------------------------------------------------------
--  porion-nodes-tests -- Tests for build node management
--  Copyright (C) 2021, 2022 Stephane Carrez
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

with Util.Assertions;
with Util.Test_Caller;

with Porion.Testsuite;
with Porion.Services;
with Porion.Nodes.Services;
package body Porion.Nodes.Tests is

   procedure Assert_Equals is
     new Util.Assertions.Assert_Equals_T (Value_Type => Porion.Nodes.Node_Status_Type);

   package Caller is new Util.Test_Caller (Test, "Porion.Nodes");

   procedure Add_Tests (Suite : in Util.Tests.Access_Test_Suite) is
   begin
      Caller.Add_Test (Suite, "Test Porion.Nodes.Services.Add_Node",
                       Test_Add_Remove_Node'Access);
      Caller.Add_Test (Suite, "Test Porion.Nodes.Services.Load_Node",
                       Test_Load_Node'Access);
      Caller.Add_Test (Suite, "Test Porion.Nodes.Create_Random_Path",
                       Test_Create_Random_Path'Access);
   end Add_Tests;

   --  ------------------------------
   --  Test Add_Node and Remove_Node.
   --  ------------------------------
   procedure Test_Add_Remove_Node (T : in out Test) is
      Path    : constant String := Util.Tests.Get_Test_Path ("nodes-1");
      Service : Porion.Services.Context_Type;
      Rules   : Porion.Nodes.Services.Rule_Status_Vector;
   begin
      Porion.Testsuite.Create (Service, Path, True);

      Nodes.Services.Add_Default_Node (Service, "localhost", "admin");
      T.Assert (not Service.Build_Node.Is_Null, "build node is null");
      T.Assert_Equals ("localhost", String '(Service.Build_Node.Get_Name),
                       "Invalid node name");
      T.Assert (Service.Build_Node.Get_Main_Node, "not the main node");

      Nodes.Services.Probe_Node (Service, "configure,make", Rules);
      Assert_Equals (T, Nodes.NODE_ONLINE, Service.Build_Node.Get_Status,
                     "invalid localhost node state");

      Nodes.Services.Add_Node (Service    => Service,
                               Kind       => Nodes.NODE_SSH,
                               Hostname   => "poseidon",
                               Login      => "porion",
                               Repository => "/home/porion/build");
      T.Assert (not Service.Build_Node.Is_Null, "build node is null");
      T.Assert_Equals ("poseidon", String '(Service.Build_Node.Get_Name),
                       "Invalid node name");
      T.Assert (not Service.Build_Node.get_Main_Node, "was the main node");

   end Test_Add_Remove_Node;

   --  ------------------------------
   --  Test Load_Node.
   --  ------------------------------
   procedure Test_Load_Node (T : in out Test) is
      Path    : constant String := Util.Tests.Get_Test_Path ("nodes-2");
      Service : Porion.Services.Context_Type;
   begin
      Porion.Testsuite.Create (Service, Path, True);

      begin
         Nodes.Services.Load_Default_Node (Service);
         T.Fail ("No Not_Found exception raised");

      exception
         when Nodes.Services.Not_Found =>
            null;

      end;

      begin
         Nodes.Services.Load_Node (Service, "invalid-hostname");
         T.Fail ("No Not_Found exception raised");

      exception
         when Nodes.Services.Not_Found =>
            null;

      end;
   end Test_Load_Node;

   procedure Test_Create_Random_Path (T : in out Test) is
      Path    : constant String := Util.Tests.Get_Test_Path ("nodes-2");
      Service : Porion.Services.Context_Type;
      Controller : Porion.Nodes.Controller_Access;
   begin
      Porion.Testsuite.Create (Service, Path, True);
      Nodes.Services.Add_Default_Node (Service, "localhost", "admin");
      Controller := Nodes.Services.Create_Controller (Executor'Unchecked_Access,
                                                               Service.Build_Node);
   end Test_Create_Random_Path;

end Porion.Nodes.Tests;
