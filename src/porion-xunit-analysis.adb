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
with Ada.Calendar;
with ADO.SQL;
with Util.Log.Loggers;
with Porion.Projects.Models;
package body Porion.XUnit.Analysis is

   --  The logger
   Log   : constant Util.Log.Loggers.Logger := Util.Log.Loggers.Create ("Porion.XUnit.Analysis");

   subtype Count_Type is Ada.Containers.Count_Type;
   use type Ada.Containers.Count_Type;

   use Porion.XUnit.Models;
   use Ada.Strings.Unbounded;

   function Get_Group_Path (Group : in Group_Path;
                            Last  : in Count_Type) return String;

   procedure Merge (Into : in out Test_Group_Type;
                    From : in out Test_Group_Type);

   procedure Find_Group (Results : in out Test_Results;
                         Group   : in Group_Path;
                         Last    : in Count_Type;
                         Pos     : out Test_Group_Maps.Cursor);

   function Find_Group (From : in Test_Results;
                        Path : in String) return Porion.XUnit.Models.Test_Group_Ref;

   procedure Save_Run_Tests (Results  : in out Test_Results;
                             Existing : in out Test_Results;
                             Build    : in out Porion.Builds.Models.Build_Ref;
                             Session  : in out ADO.Sessions.Master_Session);

   procedure Load (Tests      : in out Test_Results;
                   Project_Id : in ADO.Identifier;
                   Session    : in out ADO.Sessions.Master_Session);

   Group_Separator : constant String := "$";

   function Get_Group_Path (Group : in Group_Path;
                            Last  : in Count_Type) return String is
      Result  : Ada.Strings.Unbounded.Unbounded_String;
      Current : Count_Type := 0;
   begin
      for Name of Group loop
         exit when Current = Last;
         Current := Current + 1;
         if Length (Result) > 0 then
            Append (Result, Group_Separator);
         end if;
         Append (Result, Name);
      end loop;
      return To_String (Result);
   end Get_Group_Path;

   procedure Find_Group (Results : in out Test_Results;
                         Group   : in Group_Path;
                         Last    : in Count_Type;
                         Pos     : out Test_Group_Maps.Cursor) is
      Path : constant String := Get_Group_Path (Group, Last);
   begin
      Pos := Results.Groups.Find (Path);
      if not Test_Group_Maps.Has_Element (Pos) then
         if Last > 1 then
            Find_Group (Results, Group, Last - 1, Pos);
         end if;

         declare
            Group_Name : constant String := Group.Element (Positive (Last));
            New_Group  : Test_Group_Type (Length => Group_Name'Length);
         begin
            New_Group.Name := Group_Name;
            if Test_Group_Maps.Has_Element (Pos) then
               declare
                  Group_Ref : constant Test_Group_Maps.Reference_Type
                    := Results.Groups.Reference (Pos);
               begin
                  New_Group.Group := Group_Ref.Group;
               end;
            end if;
            Results.Groups.Insert (Path, New_Group);
            Pos := Results.Groups.Find (Path);
         end;
      end if;
   end Find_Group;

   procedure Add_Test (Results  : in out Test_Results;
                       Group    : in Group_Path;
                       Name     : in String;
                       Duration : in Natural;
                       Status   : in Porion.XUnit.Models.Test_Status_Type) is
      use Util.Strings.Vectors;

      --  Path : constant String := Get_Group_Path (Group, Group.Length);
      Pos  : Test_Group_Maps.Cursor;
   begin
      Find_Group (Results, Group, Group.Length, Pos);

      declare
         Group_Ref : constant Test_Group_Maps.Reference_Type := Results.Groups.Reference (Pos);
         New_Test  : Test_Type (Length => Name'Length);
      begin
         New_Test.Name := Name;
         New_Test.Duration := Duration;
         New_Test.Status := Status;
         --  New_Test.Group := Group_Ref.Group;
         Group_Ref.Tests.Include (Name, New_Test);
      end;
   end Add_Test;

   function Find_Group (From : in Test_Results;
                        Path : in String) return Porion.XUnit.Models.Test_Group_Ref is
      Pos_Group : constant Test_Group_Maps.Cursor := From.Groups.Find (Path);
   begin
      if not Test_Group_Maps.Has_Element (Pos_Group) then
         return Porion.XUnit.Models.Null_Test_Group;
      end if;
      return Test_Group_Maps.Element (Pos_Group).Group;
   end Find_Group;

   procedure Merge (Into : in out Test_Group_Type;
                    From : in out Test_Group_Type) is
   begin
      Into.Group := From.Group;
      for Iter in Into.Tests.Iterate loop
         declare
            Test_Ref : constant Test_Maps.Reference_Type := Into.Tests.Reference (Iter);
            Pos      : constant Test_Maps.Cursor := From.Tests.Find (Test_Ref.Name);
         begin
            Test_Ref.Group := From.Group;
            if Test_Maps.Has_Element (Pos) then
               Test_Ref.Test := From.Tests.Reference (Pos).Test;
            end if;
         end;
      end loop;
   end Merge;

   procedure Save_Run_Tests (Results  : in out Test_Results;
                             Existing : in out Test_Results;
                             Build    : in out Porion.Builds.Models.Build_Ref;
                             Session  : in out ADO.Sessions.Master_Session) is
      Build_Id   : constant ADO.Nullable_Integer := (Is_Null => False, Value => Build.Get_Number);
      Project_Id : constant ADO.Identifier := Build.Get_Project.Get_Id;
      Now        : constant ADO.Nullable_Time := (Is_Null => False, Value => Ada.Calendar.Clock);
   begin
      --  Step 1: make sure the test groups are created and inserted in the database.
      for Iter in Results.Groups.Iterate loop
         declare
            Path : constant String := Test_Group_Maps.Key (Iter);
            Ref  : constant Test_Group_Maps.Reference_Type := Results.Groups.Reference (Iter);
            Pos  : constant Test_Group_Maps.Cursor := Existing.Groups.Find (Path);
         begin
            if Test_Group_Maps.Has_Element (Pos) then
               Merge (Ref.Element.all, Existing.Groups.Reference (Pos).Element.all);
            end if;
            if not Ref.Group.Is_Loaded then
               Ref.Group.Set_Group (Find_Group (Results, Get_Group_Path (Ref.Path, 10)));
               Ref.Group.Set_Name (Ref.Name);
               Ref.Group.Set_Create_Date (Now.Value);
               Ref.Group.Set_Project_Id (Project_Id);
               Ref.Group.Save (Session);
            end if;

            Ref.Run.Set_Group (Ref.Group);
            Ref.Run.Set_Build (Build);
            Ref.Run.Save (Session);
         end;
      end loop;

      --  Step 2: write the tests
      for Iter in Results.Groups.Iterate loop
         declare
            Group         : constant Test_Group_Maps.Reference_Type
              := Results.Groups.Reference (Iter);
            Pass_Count    : Natural := 0;
            Fail_Count    : Natural := 0;
            Timeout_Count : Natural := 0;
            Duration      : Natural := 0;
         begin
            for Test_Iter in Group.Tests.Iterate loop
               declare
                  Test : constant Test_Maps.Reference_Type := Group.Tests.Reference (Test_Iter);
               begin
                  if not Test.Test.Is_Loaded then
                     Test.Test.Set_Name (Test.Name);
                     Test.Test.Set_Create_Date (Now.Value);
                     Test.Test.Set_Group (Group.Group);
                  end if;
                  if Test.Status = XUnit.Models.TEST_PASS then
                     Pass_Count := Pass_Count + 1;
                     Test.Test.Set_Total_Pass_Count (Test.Test.Get_Total_Pass_Count + 1);
                     Test.Test.Set_Last_Pass_Date (Now);
                     Test.Test.Set_Last_Pass_Build (Build_Id);
                  elsif Test.Status = XUnit.Models.TEST_FAIL then
                     Fail_Count := Fail_Count + 1;
                     Test.Test.Set_Total_Fail_Count (Test.Test.Get_Total_Fail_Count + 1);
                     Test.Test.Set_Last_Fail_Date (Now);
                     Test.Test.Set_Last_Fail_Build (Build_Id);
                  else
                     Timeout_Count := Timeout_Count + 1;
                     Test.Test.Set_Total_Timeout_Count (Test.Test.Get_Total_Timeout_Count + 1);
                     Test.Test.Set_Last_Timeout_Date (Now);
                     Test.Test.Set_Last_Timeout_Build (Build_Id);
                  end if;
                  Test.Test.Save (Session);

                  Duration := Duration + Test.Duration;
                  Test.Run.Set_Duration (Test.Duration);
                  Test.Run.Set_Status (Test.Status);
                  Test.Run.Set_Test (Test.Test);
                  Test.Run.Set_Group (Group.Run);
                  Test.Run.Save (Session);
               end;
            end loop;
            Group.Run.Set_Total_Pass_Count (Pass_Count + Group.Run.Get_Total_Pass_Count);
            Group.Run.Set_Total_Fail_Count (Fail_Count + Group.Run.Get_Total_Fail_Count);
            Group.Run.Set_Total_Timeout_Count (Timeout_Count + Group.Run.Get_Total_Timeout_Count);
            Group.Run.Set_Duration (Duration);
         end;
      end loop;

      --  Step 3: save the group since their stats have been updated.
      declare
         Pass_Count    : Natural := 0;
         Fail_Count    : Natural := 0;
         Timeout_Count : Natural := 0;
         Duration      : Natural := 0;
      begin
         for Iter in Results.Groups.Iterate loop
            declare
               Group : constant Test_Group_Maps.Reference_Type := Results.Groups.Reference (Iter);
            begin
               Group.Run.Save (Session);
               Pass_Count := Pass_Count + Group.Run.Get_Total_Pass_Count;
               Fail_Count := Fail_Count + Group.Run.Get_Total_Fail_Count;
               Timeout_Count := Timeout_Count + Group.Run.Get_Total_Timeout_Count;
               Duration := Duration + Group.Run.Get_Duration;
            end;
         end loop;

         Build.Set_Pass_Count (Pass_Count);
         Build.Set_Fail_Count (Fail_Count);
         Build.Set_Timeout_Count (Timeout_Count);
         Build.Set_Test_Duration (Duration);
         Build.Save (Session);
      end;
   end Save_Run_Tests;

   procedure Load (Tests      : in out Test_Results;
                   Project_Id : in ADO.Identifier;
                   Session    : in out ADO.Sessions.Master_Session) is
      function Find_Path (Test  : in Test_Ref) return String;
      procedure Add_Group (Group : in out Porion.XUnit.Models.Test_Group_Ref);
      procedure Add_Test (Test : in Porion.XUnit.Models.Test_Ref);

      function Find_Path (Test  : in Test_Ref) return String is
         Group : constant Porion.XUnit.Models.Test_Group_Ref'Class := Test.Get_Group;
         Pos   : Group_Id_Maps.Cursor;
      begin
         if Group.Is_Null then
            return "(root)";
         end if;
         Pos := Tests.Group_Ids.Find (Group.Get_Id);
         if Group_Id_Maps.Has_Element (Pos) then
            return Group_Id_Maps.Element (Pos);
         else
            return "(root)";
         end if;
      end Find_Path;

      procedure Add_Group (Group : in out Porion.XUnit.Models.Test_Group_Ref) is
         Name   : constant String := Group.Get_Name;
         Parent : constant Porion.XUnit.Models.Test_Group_Ref'Class := Group.Get_Group;
         Pos    : Group_Id_Maps.Cursor;
         Existing_Group : Test_Group_Type (Length => Name'Length);
      begin
         Existing_Group.Name := Name;
         Existing_Group.Group := Group;
         if not Parent.Is_Null then
            Pos := Tests.Group_Ids.Find (Parent.Get_Id);
            if not Group_Id_Maps.Has_Element (Pos) then
               Log.Error ("Parent group {0} was not found",
                          ADO.Identifier'Image (Parent.Get_Id));
            else
               declare
                  Path : constant String := Group_Id_Maps.Element (Pos);
                  Pos  : constant Test_Group_Maps.Cursor := Tests.Groups.Find (Path);
               begin
                  if Test_Group_Maps.Has_Element (Pos) then
                     declare
                        Ref : constant Test_Group_Maps.Reference_Type
                          := Tests.Groups.Reference (Pos);
                     begin
                        Group.Set_Group (Ref.Group);
                     end;
                  end if;
               end;
            end if;
         end if;
         Existing_Group.Path.Append (Name);

         declare
            Path  : constant String
              := Get_Group_Path (Existing_Group.Path, Existing_Group.Path.Length);
         begin
            Tests.Group_Ids.Insert (Group.Get_Id, Path);
            Tests.Groups.Include (Path, Existing_Group);
         end;
      end Add_Group;

      procedure Add_Test (Test : in Porion.XUnit.Models.Test_Ref) is
         Name  : constant String := Test.Get_Name;
         Path  : constant String := Find_Path (Test);
         Pos   : constant Test_Group_Maps.Cursor := Tests.Groups.Find (Path);
      begin
         if not Test_Group_Maps.Has_Element (Pos) then
            Log.Error ("Group not found for test {0}",
                       ADO.Identifier'Image (Test.Get_Id));
            return;
         end if;

         declare
            Group_Ref     : constant Test_Group_Maps.Reference_Type
              := Tests.Groups.Reference (Pos);
            Existing_Test : Test_Type (Length => Name'Length);
         begin
            Existing_Test.Name := Name;
            Existing_Test.Test := Test;
            Existing_Test.Group := Group_Ref.Group;
            Group_Ref.Tests.Include (Name, Existing_Test);
         end;
      end Add_Test;

      Query           : ADO.SQL.Query;
      Existing_Groups : Porion.XUnit.Models.Test_Group_Vector;
      Existing_Tests  : Porion.XUnit.Models.Test_Vector;
   begin
      Query.Set_Filter ("o.project_id = ? ORDER BY o.id ASC");
      Query.Add_Param (Project_Id);
      Porion.XUnit.Models.List (Existing_Groups, Session, Query);
      for Group of Existing_Groups loop
         Add_Group (Group);
      end loop;

      Query.Clear;
      Query.Set_Join ("INNER JOIN porion_test_group g ON o.group_id = g.id");
      Query.Set_Filter ("g.project_id = ? ORDER BY o.id ASC");
      Query.Add_Param (Project_Id);
      Porion.XUnit.Models.List (Existing_Tests, Session, Query);

      for Test of Existing_Tests loop
         Add_Test (Test);
      end loop;
   end Load;

   procedure Save (Results : in out Test_Results;
                   Build   : in out Porion.Builds.Models.Build_Ref;
                   Session : in out ADO.Sessions.Master_Session) is
      Known_Tests : Test_Results;
   begin
      Load (Known_tests, Build.Get_Project.Get_Id, Session);

      Save_Run_Tests (Results, Known_Tests, Build, Session);
   end Save;

end Porion.XUnit.Analysis;
