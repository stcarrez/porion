-----------------------------------------------------------------------
--  porion-configs-rules -- Configuration rules
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
with Ada.Directories;
with EL.Expressions;
with Porion.Logs.Analysis;
package Porion.Configs.Rules is

   type Rule_Type is private;

   --  Get a rule definition.
   function Get_Definition (Name : in String) return Rule_Type;

   --  Returns True if the rule is empty.
   function Is_Null (Rule : in Rule_Type) return Boolean;

   --  Get the command to execute.
   function Get_Command (Rule    : in Rule_Type;
                         Name    : in String;
                         Default  : in String)
      return EL.Expressions.Expression;

   function Get_Command (Rule    : in Rule_Type;
                         Name    : in String;
                         Default  : in String)
      return String;

   --  Get the name of this rule.
   function Get_Name (Rule : in Rule_Type) return String;

   --  Read the rule configuration file.
   procedure Read (Path    : in String;
                   Process : not null
                      access procedure (Line : in String;
                                        Level : in Logs.Analysis.Level_Type)) with
      Pre => Ada.Directories.Exists (Path);

   --  Find the rule configuration file and read it.
   procedure Read_Rule (Name    : in String;
                        Process : not null
                           access procedure (Line : in String;
                                             Level : in Logs.Analysis.Level_Type)) with
      Pre => Name'Length > 0;

private

   type Definition_Type is record
      Config : Config_Type;
      Name   : UString;
   end record;

   type Definition_Access is access all Definition_Type;

   type Rule_Type is record
      Def : Definition_Access;
   end record;

end Porion.Configs.Rules;
