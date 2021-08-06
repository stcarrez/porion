--  Advanced Resource Embedder 1.2.0
package Porion.Resources is

   type Content_Access is access constant String;

   type Name_Access is access constant String;

   type Name_Array is array (Natural range <>) of Name_Access;

   Names : constant Name_Array;

   --  Returns the data stream with the given name or null.
   function Get_Content (Name : String) return
      access constant String;

private


   K_0             : aliased constant String := "command-builds.xml";
   K_1             : aliased constant String := "command-nodes.xml";
   K_2             : aliased constant String := "command-projects.xml";
   K_3             : aliased constant String := "project-branches.xml";
   K_4             : aliased constant String := "project-builds.xml";

   Names : constant Name_Array := (
      K_0'Access, K_1'Access, K_2'Access, K_3'Access,
      K_4'Access);
end Porion.Resources;
