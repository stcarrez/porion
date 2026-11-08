-----------------------------------------------------------------------
--  porion-logs -- Log build execution
--  Copyright (C) 2021 - 2026 Stephane Carrez
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
with Util.Log.Appenders.Factories;
with Util.Log.Appenders.Rolling_Files.Lzma;
private with Ada.Finalization;
private with Ada.Text_IO;
package Porion.Logs is

   type Source_Type is (LOG_INFO,
                        LOG_NODE,
                        LOG_COMMAND,
                        LOG_ENVIRONMENT,
                        LOG_EXECUTION,
                        LOG_EXECUTION_ERROR,
                        LOG_STEP_INFO,
                        LOG_RESULT,
                        LOG_FAILURE);

   type Logger_Interface is limited interface;

   --  Write the line on the logger.
   procedure Log (Logger   : in out Logger_Interface;
                  Source   : in Source_Type;
                  Line     : in String) is abstract;

   type Logger_Type is tagged limited private;

   --  Returns true if this logger is opened and we can write on it.
   function Is_Opened (Logger : in Logger_Type) return Boolean;

   --  Create and open the logger to write on the given path.
   procedure Create (Logger : in out Logger_Type;
                     Path   : in String);
   procedure Create (Logger : in out Logger_Type;
                     Dir    : in String;
                     Name   : in String);

   --  Close the logger file.
   procedure Close (Logger : in out Logger_Type);

   --  Write the line on the logger with the source to identify the producer.
   procedure Write (Logger : in out Logger_Type;
                    Source : in Source_Type;
                    Line   : in String);

   package Lzma_Rolling_Factory is
     new Util.Log.Appenders.Factories
       (Name   => "LzmaRollingFile",
        Create => Util.Log.Appenders.Rolling_Files.Lzma.Create'Access)
   with Unreferenced;

   type Null_Logger is limited new Logger_Interface with null record;

   procedure Log (L        : in out Null_Logger;
                  Source   : in Source_Type;
                  Line     : in String) is null;

private

   type Logger_Type is new Ada.Finalization.Limited_Controlled with record
      File : Ada.Text_IO.File_Type;
   end record;

   overriding
   procedure Finalize (Logger : in out Logger_Type);

end Porion.Logs;
