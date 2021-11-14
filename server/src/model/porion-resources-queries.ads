--  Advanced Resource Embedder 1.2.0
package Porion.Resources.Queries is

   Names : constant Name_Array;

   --  Returns the data stream with the given name or null.
   function Get_Content (Name : String) return
      access constant String;

private


   K_0             : aliased constant String := "cleanup.xml";
   K_1             : aliased constant String := "command-branches.xml";
   K_2             : aliased constant String := "command-info.xml";
   K_3             : aliased constant String := "command-nodes.xml";
   K_4             : aliased constant String := "project-branches.xml";
   K_5             : aliased constant String := "project-builds.xml";
   K_6             : aliased constant String := "project-update-status.xml";
   K_7             : aliased constant String := "report-build-queue.xml";
   K_8             : aliased constant String := "report-builds.xml";
   K_9             : aliased constant String := "report-projects.xml";
   K_10            : aliased constant String := "report-tests.xml";
   K_11            : aliased constant String := "stat-builds.xml";

   Names : constant Name_Array := (
      K_0'Access, K_1'Access, K_2'Access, K_3'Access,
      K_4'Access, K_5'Access, K_6'Access, K_7'Access,
      K_8'Access, K_9'Access, K_10'Access, K_11'Access);
end Porion.Resources.Queries;
