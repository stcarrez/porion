-- Advanced Resource Embedder 1.1.0
package Porion.Resources.Queries is

   Names : constant Name_Array;

   --  Returns the data stream with the given name or null.
   function Get_Content (Name : String) return access constant String;

private


   K_0             : aliased constant String := "cleanup.xml";
   K_1             : aliased constant String := "command-branches.xml";
   K_2             : aliased constant String := "command-builds.xml";
   K_3             : aliased constant String := "command-info.xml";
   K_4             : aliased constant String := "command-nodes.xml";
   K_5             : aliased constant String := "command-projects.xml";
   K_6             : aliased constant String := "project-branches.xml";
   K_7             : aliased constant String := "project-builds.xml";
   K_8             : aliased constant String := "stat-builds.xml";

   Names : constant Name_Array := (
      K_0'Access, K_1'Access, K_2'Access, K_3'Access,
      K_4'Access, K_5'Access, K_6'Access, K_7'Access,
      K_8'Access);
end Porion.Resources.Queries;
