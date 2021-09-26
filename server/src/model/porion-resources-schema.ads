--  Advanced Resource Embedder 1.2.0
package Porion.Resources.Schema is

   Names : constant Name_Array;

   --  Returns the data stream with the given name or null.
   function Get_Content (Name : String) return
      Content_Access;

private


   K_0             : aliased constant String := "create-porion_server-sqlite";

   Names : constant Name_Array := (
      0 => K_0'Access);
end Porion.Resources.Schema;
