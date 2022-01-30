--  Advanced Resource Embedder 1.2.0
package Porion.Resources.Queries is

   Names : constant Name_Array;

   --  Returns the data stream with the given name or null.
   function Get_Content (Name : String) return
      access constant String;

private


   K_0             : aliased constant String := "build-metrics.xml";
   K_1             : aliased constant String := "cleanup-build.xml";
   K_2             : aliased constant String := "cleanup-project.xml";
   K_3             : aliased constant String := "cleanup-recipe.xml";
   K_4             : aliased constant String := "command-branches.xml";
   K_5             : aliased constant String := "command-jobs.xml";
   K_6             : aliased constant String := "command-sessions.xml";
   K_7             : aliased constant String := "command-users.xml";
   K_8             : aliased constant String := "permissions.xml";
   K_9             : aliased constant String := "project-branches.xml";
   K_10            : aliased constant String := "project-builds.xml";
   K_11            : aliased constant String := "project-update-status.xml";
   K_12            : aliased constant String := "queue-messages.xml";
   K_13            : aliased constant String := "report-build-queue.xml";
   K_14            : aliased constant String := "report-build-steps.xml";
   K_15            : aliased constant String := "report-builds.xml";
   K_16            : aliased constant String := "report-env.xml";
   K_17            : aliased constant String := "report-nodes.xml";
   K_18            : aliased constant String := "report-projects.xml";
   K_19            : aliased constant String := "report-tests.xml";
   K_20            : aliased constant String := "stat-builds.xml";
   K_21            : aliased constant String := "stat-metrics.xml";

   Names : constant Name_Array := (
      K_0'Access, K_1'Access, K_2'Access, K_3'Access,
      K_4'Access, K_5'Access, K_6'Access, K_7'Access,
      K_8'Access, K_9'Access, K_10'Access, K_11'Access,
      K_12'Access, K_13'Access, K_14'Access, K_15'Access,
      K_16'Access, K_17'Access, K_18'Access, K_19'Access,
      K_20'Access, K_21'Access);
end Porion.Resources.Queries;
