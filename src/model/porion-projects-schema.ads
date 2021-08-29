-- Advanced Resource Embedder 1.1.0
package Porion.Projects.Schema is

   type Content_Array is array (Natural range <>) of access constant String;
   type Content_Access is access constant Content_Array;

   type Name_Access is access constant String;

   type Name_Array is array (Natural range <>) of Name_Access;

   Names : constant Name_Array;

   --  Returns the data stream with the given name or null.
   function Get_Content (Name : String) return Content_Access;

private


   K_0             : aliased constant String := "create-porion-sqlite";

   Names : constant Name_Array := (
      0 => K_0'Access);
end Porion.Projects.Schema;
