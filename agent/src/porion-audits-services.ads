-----------------------------------------------------------------------
--  porion-audits-services -- Porion Audit Manager/AWA Audit Manager
--  Copyright (C) 2018, 2022 Stephane Carrez
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
with Ada.Containers.Indefinite_Hashed_Maps;

with ADO.Audits;
with ADO.Sessions;
package Porion.Audits.Services is

   --  ------------------------------
   --  Audit manager
   --  ------------------------------
   --  The audit manager is informed about changes on database objects and is
   --  responsible for creating audit fields to record these changes.  A database
   --  field is audited when it has the `<<Auditable>>` stereotype.
   --
   --  For porion agent, we record the same changes as the porion server but
   --  we don't associate the change with a user session.  The porion library
   --  is not linked against AWA to keep it small.  The porion audit records
   --  are defined in `Porion.Audits.Models` but they map to the same database
   --  tables as AWA audit records defined in `AWA.Audits.Models`.
   type Audit_Manager is limited new ADO.Audits.Audit_Manager with private;
   type Audit_Manager_Access is access all Audit_Manager'Class;

   --  Save the audit changes in the database.
   overriding
   procedure Save (Manager : in out Audit_Manager;
                   Session : in out ADO.Sessions.Master_Session'Class;
                   Object  : in ADO.Audits.Auditable_Object_Record'Class;
                   Changes : in ADO.Audits.Audit_Array);

   --  Find the audit field identification number from the entity type and field name.
   function Get_Audit_Field (Manager : in Audit_Manager;
                             Name    : in String;
                             Entity  : in ADO.Entity_Type) return Integer;

   --  Initialize the audit manager.
   procedure Initialize (Manager : in out Audit_Manager;
                         DB      : in ADO.Sessions.Session'Class);

private

   type Field_Key (Len : Natural) is record
      Entity : ADO.Entity_Type;
      Name   : String (1 .. Len);
   end record;

   function Hash (Item : in Field_Key) return Ada.Containers.Hash_Type;

   package Audit_Field_Maps is
     new Ada.Containers.Indefinite_Hashed_Maps (Key_Type        => Field_Key,
                                                Element_Type    => Integer,
                                                Hash            => Hash,
                                                Equivalent_Keys => "=");

   type Audit_Manager is limited new ADO.Audits.Audit_Manager with record
      Fields : Audit_Field_Maps.Map;
   end record;

end Porion.Audits.Services;
