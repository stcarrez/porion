--  Advanced Resource Embedder 1.2.0
with Interfaces; use Interfaces;

package body Porion.Resources.Queries is
   function Hash (S : String) return Natural;

   P : constant array (0 .. 2) of Natural :=
     (1, 12, 13);

   T1 : constant array (0 .. 2) of Unsigned_8 :=
     (16, 28, 30);

   T2 : constant array (0 .. 2) of Unsigned_8 :=
     (4, 21, 5);

   G : constant array (0 .. 35) of Unsigned_8 :=
     (0, 0, 0, 0, 13, 3, 0, 0, 0, 10, 9, 0, 12, 15, 0, 0, 11, 0, 0, 0, 0, 0,
      0, 0, 2, 0, 1, 0, 0, 3, 9, 2, 6, 4, 0, 2);

   function Hash (S : String) return Natural is
      F : constant Natural := S'First - 1;
      L : constant Natural := S'Length;
      F1, F2 : Natural := 0;
      J : Natural;
   begin
      for K in P'Range loop
         exit when L < P (K);
         J  := Character'Pos (S (P (K) + F));
         F1 := (F1 + Natural (T1 (K)) * J) mod 36;
         F2 := (F2 + Natural (T2 (K)) * J) mod 36;
      end loop;
      return (Natural (G (F1)) + Natural (G (F2))) mod 17;
   end Hash;

   C_0 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        Build metrics" & ASCII.LF & "  "
       & "  </description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Que"
       & "ries.Metric_Info"" bean=""no"">" & ASCII.LF & "        <comment>A metric"
       & " collected during the build.</comment>" & ASCII.LF & "        <property "
       & "type='ADO.Identifier' name=""id"">" & ASCII.LF & "            <comment>t"
       & "he metric id.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & " "
       & "       <property type='Integer' name=""value"">" & ASCII.LF & "         "
       & "   <comment>the metric value.</comment>" & ASCII.LF & "        </propert"
       & "y>" & ASCII.LF & "        <property type='String' name=""content"">" & ASCII.LF
       & "            <comment>the metric detailed content.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='String' name="
       & """name"">" & ASCII.LF & "            <comment>the metric logical name.</"
       & "comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <prop"
       & "erty type='String' name=""label"">" & ASCII.LF & "            <comment>t"
       & "he metric label.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Porion.Metrics.Metric_Type' name=""kind"">" & ASCII.LF
       & "            <comment>the metric type.</comment>" & ASCII.LF & "        <"
       & "/property>" & ASCII.LF & "    </class>" & ASCII.LF & ASCII.LF & "    <q"
       & "uery name='build-metrics'>" & ASCII.LF & "        <comment>Metrics colle"
       & "cted during a build</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & " "
       & "         SELECT" & ASCII.LF & "          bm.id AS id," & ASCII.LF & "   "
       & "       bm.value AS value," & ASCII.LF & "          bm.content AS content"
       & "," & ASCII.LF & "          m.name AS name," & ASCII.LF & "          m.la"
       & "bel AS label," & ASCII.LF & "          m.metric AS metric" & ASCII.LF & " "
       & "         FROM porion_build_metric AS bm" & ASCII.LF & "          INNER J"
       & "OIN porion_metric AS m ON bm.metric_id = m.id" & ASCII.LF & "          W"
       & "HERE bm.build_id = :build_id" & ASCII.LF & "        </sql>" & ASCII.LF & " "
       & "   </query> " & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_1 : aliased constant String := "<query-mapping package='Porion.Builds.Mod"
       & "els'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Queries to c"
       & "leanup a build" & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF
       & "    <query name='cleanup-build-step'>" & ASCII.LF & "       <comment>Cle"
       & "anup the build steps of a project.</comment>" & ASCII.LF & "       <sql>"
       & ASCII.LF & "    DELETE FROM porion_build_step WHERE build_id = :build_id"
       & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF
       & "    <query name='cleanup-build-reason'>" & ASCII.LF & "       <comment>C"
       & "leanup the build reaon.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF
       & "    DELETE FROM porion_build_reason WHERE build_id = :build_id" & ASCII.LF
       & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "   "
       & " <query name='cleanup-build-metrics'>" & ASCII.LF & "       <comment>Cle"
       & "anup the build metrics.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF
       & "    DELETE FROM porion_build_metric WHERE build_id = :build_id" & ASCII.LF
       & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "   "
       & " <query name='cleanup-build-test-run'>" & ASCII.LF & "       <comment>Cl"
       & "eanup the test run of a build.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF
       & "    DELETE FROM porion_test_run WHERE group_id IN" & ASCII.LF & "      ("
       & "SELECT porion_test_run_group.id FROM porion_test_run_group" & ASCII.LF & " "
       & "               WHERE porion_test_run_group.build_id = :build_id)" & ASCII.LF
       & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "   "
       & " <query name='cleanup-build-test-run-group'>" & ASCII.LF & "       <comm"
       & "ent>Cleanup the test run group of a build.</comment>" & ASCII.LF & "    "
       & "   <sql>" & ASCII.LF & "    DELETE FROM porion_test_run_group WHERE pori"
       & "on_test_run_group.build_id = :build_id" & ASCII.LF & "       </sql>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-build-l"
       & "ast-build'>" & ASCII.LF & "       <comment>Cleanup the project last buil"
       & "d reference.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    DE"
       & "LETE FROM porion_last_build WHERE build_id = :build_id" & ASCII.LF & "  "
       & "     </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "</que"
       & "ry-mapping>" & ASCII.LF;

   C_2 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Queries to"
       & " cleanup a project" & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF
       & "    <query name='cleanup-project-build-step'>" & ASCII.LF & "       <com"
       & "ment>Cleanup the build steps of a project.</comment>" & ASCII.LF & "    "
       & "   <sql>" & ASCII.LF & "    DELETE FROM porion_build_step WHERE build_id"
       & " IN" & ASCII.LF & "      (SELECT id FROM porion_build WHERE project_id ="
       & " :project_id)" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF
       & ASCII.LF & "    <query name='cleanup-project-build-metrics'>" & ASCII.LF
       & "       <comment>Cleanup the project build metrics.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_build_metric WHERE bu"
       & "ild_id IN" & ASCII.LF & "      (SELECT porion_build.id FROM porion_build"
       & " WHERE porion_build.project_id = :project_id)   " & ASCII.LF & "       <"
       & "/sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "    <query "
       & "name='cleanup-project-build-reason'>" & ASCII.LF & "       <comment>Clea"
       & "nup the project build reason.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF
       & "    DELETE FROM porion_build_reason WHERE build_id IN" & ASCII.LF & "   "
       & "   (SELECT porion_build.id FROM porion_build WHERE porion_build.project_"
       & "id = :project_id)" & ASCII.LF & "       </sql>" & ASCII.LF & "    </quer"
       & "y>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-project-build-que"
       & "ue'>" & ASCII.LF & "       <comment>Remove the project from build queue."
       & "</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    DELETE FROM po"
       & "rion_build_queue WHERE recipe_id IN" & ASCII.LF & "      (SELECT porion_"
       & "recipe.id FROM porion_recipe WHERE porion_recipe.project_id = :project_i"
       & "d)   " & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF
       & ASCII.LF & "    <query name='cleanup-project-test-run'>" & ASCII.LF & " "
       & "      <comment>Cleanup the test run of a project.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_test_run WHERE group_"
       & "id IN" & ASCII.LF & "      (SELECT porion_test_run_group.id FROM porion_"
       & "test_run_group INNER JOIN porion_test_group ON" & ASCII.LF & "          "
       & " porion_test_run_group.group_id = porion_test_group.id" & ASCII.LF & "  "
       & "              WHERE porion_test_group.project_id = :project_id)" & ASCII.LF
       & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "   "
       & " <query name='cleanup-project-test-run-group'>" & ASCII.LF & "       <co"
       & "mment>Cleanup the test run group of a project.</comment>" & ASCII.LF & " "
       & "      <sql>" & ASCII.LF & "    DELETE FROM porion_test_run_group WHERE g"
       & "roup_id IN" & ASCII.LF & "      (SELECT id FROM porion_test_group WHERE "
       & "porion_test_group.project_id = :project_id)" & ASCII.LF & "       </sql>"
       & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "    <query name='cle"
       & "anup-project-test'>" & ASCII.LF & "       <comment>Cleanup the test of a"
       & " project.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    DELET"
       & "E FROM porion_test WHERE group_id IN" & ASCII.LF & "      (SELECT id FRO"
       & "M porion_test_group WHERE porion_test_group.project_id = :project_id)" & ASCII.LF
       & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "   "
       & " <query name='cleanup-project-test-group'>" & ASCII.LF & "       <commen"
       & "t>Cleanup the test group of a project.</comment>" & ASCII.LF & "       <"
       & "sql>" & ASCII.LF & "    DELETE FROM porion_test_group WHERE porion_test_"
       & "group.project_id = :project_id" & ASCII.LF & "       </sql>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-project"
       & "-last-build'>" & ASCII.LF & "       <comment>Cleanup the project last bu"
       & "ild references of a project.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF
       & "    DELETE FROM porion_last_build WHERE recipe_id IN" & ASCII.LF & "    "
       & "  (SELECT id FROM porion_recipe WHERE project_id = :project_id)" & ASCII.LF
       & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "   "
       & " <query name='cleanup-project-build'>" & ASCII.LF & "       <comment>Cle"
       & "anup the project builds.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF
       & "    DELETE FROM porion_build WHERE project_id = :project_id" & ASCII.LF
       & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "   "
       & " <query name='cleanup-project-environment'>" & ASCII.LF & "       <comme"
       & "nt>Cleanup the project specific environment.</comment>" & ASCII.LF & "  "
       & "     <sql>" & ASCII.LF & "    DELETE FROM porion_environment WHERE recip"
       & "e_id IN" & ASCII.LF & "      (SELECT id FROM porion_recipe WHERE project"
       & "_id = :project_id)" & ASCII.LF & "       </sql>" & ASCII.LF & "    </que"
       & "ry>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-project-build-re"
       & "cipe-step'>" & ASCII.LF & "       <comment>Cleanup the project build rec"
       & "ipe of a project.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & " "
       & "   DELETE FROM porion_recipe_step WHERE recipe_id IN" & ASCII.LF & "    "
       & "  (SELECT id FROM porion_recipe WHERE project_id = :project_id)" & ASCII.LF
       & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "   "
       & " <query name='cleanup-project-build-recipe'>" & ASCII.LF & "       <comm"
       & "ent>Cleanup the project build recipe of a project.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_recipe WHERE project_"
       & "id = :project_id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query"
       & ">" & ASCII.LF & ASCII.LF & "    <query name='cleanup-project-branch'>" & ASCII.LF
       & "       <comment>Cleanup the project branch of a project.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_branch WHERE project_"
       & "id = :project_id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query"
       & ">" & ASCII.LF & ASCII.LF & "    <query name='cleanup-project-dependency"
       & "'>" & ASCII.LF & "       <comment>Cleanup the project dependencies of a "
       & "project.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    DELETE"
       & " FROM porion_dependency WHERE project_id = :project_id OR owner_id = :pr"
       & "oject_id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF
       & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_3 : aliased constant String := "<query-mapping package='Porion.Builds.Mod"
       & "els'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Queries to c"
       & "leanup a recipe" & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF
       & "    <query name='cleanup-recipe-build-step'>" & ASCII.LF & "       <comm"
       & "ent>Cleanup the build steps of a recipe.</comment>" & ASCII.LF & "      "
       & " <sql>" & ASCII.LF & "    DELETE FROM porion_build_step WHERE build_id I"
       & "N" & ASCII.LF & "      (SELECT id FROM porion_build WHERE recipe_id = :r"
       & "ecipe_id)" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF
       & ASCII.LF & "    <query name='cleanup-recipe-build-metrics'>" & ASCII.LF
       & "       <comment>Cleanup the recipe build metrics.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_build_metric WHERE bu"
       & "ild_id IN" & ASCII.LF & "      (SELECT porion_build.id FROM porion_build"
       & " WHERE porion_build.recipe_id = :recipe_id)   " & ASCII.LF & "       </s"
       & "ql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "    <query na"
       & "me='cleanup-recipe-build-reason'>" & ASCII.LF & "       <comment>Cleanup"
       & " the build reason.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & " "
       & "   DELETE FROM porion_build_reason WHERE build_id IN" & ASCII.LF & "    "
       & "  (SELECT porion_build.id FROM porion_build WHERE porion_build.recipe_id"
       & " = :recipe_id)   " & ASCII.LF & "       </sql>" & ASCII.LF & "    </quer"
       & "y>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-recipe-build-queu"
       & "e'>" & ASCII.LF & "       <comment>Remove the recipe from build queue.</"
       & "comment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    DELETE FROM pori"
       & "on_build_queue WHERE recipe_id = :recipe_id" & ASCII.LF & "       </sql>"
       & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "    <query name='cle"
       & "anup-recipe-test-run'>" & ASCII.LF & "       <comment>Cleanup the test r"
       & "un of all builds for the recipe.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF
       & "    DELETE FROM porion_test_run WHERE group_id IN" & ASCII.LF & "      ("
       & "SELECT porion_test_run_group.id FROM porion_test_run_group INNER JOIN po"
       & "rion_test_group ON" & ASCII.LF & "           porion_test_run_group.group"
       & "_id = porion_test_group.id" & ASCII.LF & "           INNER JOIN porion_b"
       & "uild ON porion_build.id = porion_test_run_group.build_id" & ASCII.LF & " "
       & "               WHERE porion_build.recipe_id = :recipe_id)" & ASCII.LF & " "
       & "      </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "    "
       & "<query name='cleanup-recipe-test-run-group'>" & ASCII.LF & "       <comm"
       & "ent>Cleanup the test run group of all builds for the recipe.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_test_run_group WHERE "
       & "group_id IN" & ASCII.LF & "      (SELECT porion_test_run_group.id FROM p"
       & "orion_test_run_group" & ASCII.LF & "           INNER JOIN porion_build O"
       & "N porion_build.id = porion_test_run_group.build_id" & ASCII.LF & "      "
       & "        WHERE porion_build.recipe_id = :recipe_id)" & ASCII.LF & "      "
       & " </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "    <quer"
       & "y name='cleanup-recipe-last-build'>" & ASCII.LF & "       <comment>Clean"
       & "up the project last build references of a recipe.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_last_build WHERE reci"
       & "pe_id = :recipe_id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </que"
       & "ry>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-recipe-build'>" & ASCII.LF
       & "       <comment>Cleanup the project builds of a recipe.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_build WHERE recipe_id"
       & " = :recipe_id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF
       & ASCII.LF & "    <query name='cleanup-recipe-environment'>" & ASCII.LF & " "
       & "      <comment>Cleanup the project specific environment.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_environment WHERE rec"
       & "ipe_id = :recipe_id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </qu"
       & "ery>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-recipe-step'>" & ASCII.LF
       & "       <comment>Cleanup the project build recipe steps.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_recipe_step WHERE rec"
       & "ipe_id = :recipe_id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </qu"
       & "ery>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_4 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        List of project branches" & ASCII.LF
       & "    </description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Q"
       & "ueries.Branch_Info"" bean=""no"">" & ASCII.LF & "        <comment>Inform"
       & "ation about a project branch.</comment>" & ASCII.LF & "        <property"
       & " type='String' name=""name"">" & ASCII.LF & "            <comment>the br"
       & "anch name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & " "
       & "       <property type='Porion.Projects.Models.Branch_Status_Type' name="""
       & "branch_status"">" & ASCII.LF & "            <comment>the branch status.<"
       & "/comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <pro"
       & "perty type='String' name=""branch_tag"">" & ASCII.LF & "            <com"
       & "ment>the branch tag.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Integer' name=""recipe_count"">" & ASCII.LF & " "
       & "           <comment>the number of build recipes for this branch.</commen"
       & "t>" & ASCII.LF & "        </property>" & ASCII.LF & "    </class>" & ASCII.LF
       & ASCII.LF & "    <query name='branch-list'>" & ASCII.LF & "        <comme"
       & "nt>Get the list of project branch</comment>" & ASCII.LF & "        <sql>"
       & ASCII.LF & "            SELECT" & ASCII.LF & "            branch.name AS"
       & " name," & ASCII.LF & "            branch.status AS status," & ASCII.LF & " "
       & "           branch.tag AS tag," & ASCII.LF & "            COUNT(recipe.id"
       & ") AS recipe_count" & ASCII.LF & "            FROM porion_branch AS branc"
       & "h" & ASCII.LF & "            LEFT JOIN porion_recipe AS recipe ON recipe"
       & ".branch_id = branch.id" & ASCII.LF & "            WHERE branch.project_i"
       & "d = :project_id" & ASCII.LF & "            GROUP BY branch.id" & ASCII.LF
       & "        </sql>" & ASCII.LF & "        <sql-count>" & ASCII.LF & "       "
       & "     SELECT" & ASCII.LF & "            count(project.id)" & ASCII.LF & " "
       & "           FROM porion_project AS project" & ASCII.LF & "        </sql-c"
       & "ount>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "</query-map"
       & "ping>" & ASCII.LF;

   C_5 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "        List of "
       & "builds" & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF & "    "
       & "<query name='command-build-list'>" & ASCII.LF & "        <comment>Get th"
       & "e list of builds</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & " "
       & "           SELECT" & ASCII.LF & "            build.id AS id," & ASCII.LF
       & "            build.number AS number," & ASCII.LF & "            project.n"
       & "ame AS name," & ASCII.LF & "            build.pass_count AS pass_count," & ASCII.LF
       & "            build.fail_count AS fail_count" & ASCII.LF & "            FR"
       & "OM porion_build AS build" & ASCII.LF & "            INNER JOIN porion_pr"
       & "oject AS project ON build.project_id = project.id" & ASCII.LF & "       "
       & " </sql>" & ASCII.LF & "        <sql-count>" & ASCII.LF & "            SE"
       & "LECT" & ASCII.LF & "            count(build.id)" & ASCII.LF & "         "
       & "   FROM porion_build AS build" & ASCII.LF & "        </sql-count>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_6 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        List of builds" & ASCII.LF & " "
       & "   </description>" & ASCII.LF & " " & ASCII.LF & "    <class name=""Pori"
       & "on.Queries.Node_Info"" bean=""no"">" & ASCII.LF & "        <comment>Info"
       & "rmation about a build node.</comment>" & ASCII.LF & "        <property t"
       & "ype='String' name=""name"">" & ASCII.LF & "            <comment>the node"
       & " name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "     "
       & "   <property type='String' name=""login"">" & ASCII.LF & "            <c"
       & "omment>the node login name.</comment>" & ASCII.LF & "        </property>"
       & ASCII.LF & "        <property type='String' name=""os_name"">" & ASCII.LF
       & "            <comment>the node OS name.</comment>" & ASCII.LF & "        "
       & "</property>" & ASCII.LF & "        <property type='String' name=""os_ver"
       & "sion"">" & ASCII.LF & "            <comment>the node OS version.</commen"
       & "t>" & ASCII.LF & "        </property>" & ASCII.LF & "        <property t"
       & "ype='String' name=""cpu_type"">" & ASCII.LF & "            <comment>the "
       & "node CPU type.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='String' name=""repository_dir"">" & ASCII.LF & " "
       & "           <comment>the node repository dir.</comment>" & ASCII.LF & "  "
       & "      </property>" & ASCII.LF & "        <property type='Porion.Nodes.No"
       & "de_Type' name=""kind"">" & ASCII.LF & "            <comment>the node kin"
       & "d.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <"
       & "property type='Porion.Nodes.Node_Status_Type' name=""status"">" & ASCII.LF
       & "            <comment>the node status.</comment>" & ASCII.LF & "        <"
       & "/property>" & ASCII.LF & "        <property type='Integer' name=""recipe"
       & "_count"">" & ASCII.LF & "            <comment>the number of build recipe"
       & "s that use this node.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Integer' name=""build_count"">" & ASCII.LF & "  "
       & "          <comment>the number of builds for this node.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "    </class>" & ASCII.LF & ASCII.LF
       & "   <query name='node-list'>" & ASCII.LF & "        <comment>Get the list"
       & " of build nodes</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & "  "
       & "          SELECT" & ASCII.LF & "            node.name AS name," & ASCII.LF
       & "            node.login AS login," & ASCII.LF & "            node.os_name"
       & " AS os_name," & ASCII.LF & "            node.os_version AS os_version," & ASCII.LF
       & "            node.cpu_type AS cpu_type," & ASCII.LF & "            node.r"
       & "epository_dir AS repository_dir," & ASCII.LF & "            node.kind AS"
       & " kind," & ASCII.LF & "            node.status AS status," & ASCII.LF & " "
       & "           (SELECT COUNT(recipe.id) FROM porion_recipe AS recipe WHERE r"
       & "ecipe.node_id = node.id) AS recipe_count," & ASCII.LF & "            (SE"
       & "LECT COUNT(build.id) FROM porion_build AS build WHERE build.node_id = no"
       & "de.id) AS bld_count" & ASCII.LF & "            FROM porion_node AS node" & ASCII.LF
       & "            WHERE node.deleted = 0" & ASCII.LF & "            ORDER BY n"
       & "ode.name" & ASCII.LF & "        </sql>" & ASCII.LF & "   </query>" & ASCII.LF
       & ASCII.LF & "   <query name='project-node-list'>" & ASCII.LF & "        <"
       & "comment>Get the list of build nodes for a project</comment>" & ASCII.LF
       & "        <sql>" & ASCII.LF & "            SELECT" & ASCII.LF & "         "
       & "   node.name AS name," & ASCII.LF & "            node.login AS login," & ASCII.LF
       & "            node.os_name AS os_name," & ASCII.LF & "            node.os_"
       & "version AS os_version," & ASCII.LF & "            node.cpu_type AS cpu_t"
       & "ype," & ASCII.LF & "            node.repository_dir AS repository_dir," & ASCII.LF
       & "            node.kind AS kind," & ASCII.LF & "            node.status AS"
       & " status," & ASCII.LF & "            COUNT(distinct recipe.id) AS recipe_"
       & "count," & ASCII.LF & "            (SELECT COUNT(build.id) FROM porion_bu"
       & "ild AS build WHERE build.node_id = node.id AND build.project_id = :proje"
       & "ct_id) AS bld_count" & ASCII.LF & "            FROM porion_node AS node" & ASCII.LF
       & "            INNER JOIN porion_recipe AS recipe ON recipe.node_id = node."
       & "id" & ASCII.LF & "            WHERE node.deleted = 0 AND recipe.project_"
       & "id = :project_id" & ASCII.LF & "            GROUP BY node.id" & ASCII.LF
       & "            ORDER BY node.name" & ASCII.LF & "        </sql>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_7 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Informatio"
       & "n about branches on a project." & ASCII.LF & "    </description>" & ASCII.LF
       & ASCII.LF & "    <query name='project-branches'>" & ASCII.LF & "       <c"
       & "omment>Get a list of project branches.</comment>" & ASCII.LF & "       <"
       & "sql>" & ASCII.LF & "    SELECT" & ASCII.LF & "      branch.id," & ASCII.LF
       & "      branch.name," & ASCII.LF & "      branch.tag," & ASCII.LF & "     "
       & " branch.last_date," & ASCII.LF & "      build.create_date," & ASCII.LF & " "
       & "     (SELECT COUNT(*) FROM porion_build AS build WHERE build.branch_id ="
       & " branch.id) AS count" & ASCII.LF & "    FROM porion_branch AS branch" & ASCII.LF
       & "    LEFT JOIN porion_last_build AS last_build ON branch.id = last_build."
       & "branch_id" & ASCII.LF & "    LEFT JOIN porion_build AS build ON last_bui"
       & "ld.build_id = build.id" & ASCII.LF & "    WHERE branch.project_id = :pro"
       & "ject_id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF
       & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_8 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Informatio"
       & "n about branches on a project." & ASCII.LF & "    </description>" & ASCII.LF
       & ASCII.LF & "    <query name='project-last-build'>" & ASCII.LF & "       "
       & "<comment>Get a list of project branches.</comment>" & ASCII.LF & "      "
       & " <sql>" & ASCII.LF & "    SELECT" & ASCII.LF & "      MAX(build.number)" & ASCII.LF
       & "    FROM porion_build AS build" & ASCII.LF & "    WHERE build.project_id"
       & " = :project_id AND build.branch_id = :branch_id" & ASCII.LF & "       </"
       & "sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapp"
       & "ing>" & ASCII.LF;

   C_9 : aliased constant String := "<query-mapping package='Porion.Builds.Mod"
       & "els'>" & ASCII.LF & "    <description>" & ASCII.LF & "        Provide pr"
       & "oject build status" & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF
       & "    <class name=""Porion.Builds.Models.Build_Status"" bean=""yes"">" & ASCII.LF
       & "        <comment>Summary of information about last builds of a project.<"
       & "/comment>" & ASCII.LF & "        <property type='ADO.Identifier' name="""
       & "recipe_id"">" & ASCII.LF & "            <comment>the build recipe id.</c"
       & "omment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <prope"
       & "rty type='Porion.Rate_Type' name=""rate_factor"">" & ASCII.LF & "       "
       & "     <comment>the recipe rate factor.</comment>" & ASCII.LF & "        <"
       & "/property>" & ASCII.LF & "        <property type='Porion.Builds.Models.B"
       & "uild_Status_Type' name=""build_status"" not-null=""no"">" & ASCII.LF & " "
       & "           <comment>the last build status.</comment>" & ASCII.LF & "    "
       & "    </property>" & ASCII.LF & "        <property type='String' name=""bu"
       & "ild_tag"">" & ASCII.LF & "            <comment>the branch tag.</comment>"
       & ASCII.LF & "        </property>" & ASCII.LF & "        <property type='I"
       & "nteger' name=""build_number"">" & ASCII.LF & "            <comment>the b"
       & "uild number.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & " "
       & "       <property type='Integer' name=""pass_count"">" & ASCII.LF & "    "
       & "        <comment>the number of tests that succeeded.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Integer' name"
       & "=""fail_count"">" & ASCII.LF & "            <comment>the number of tests"
       & " that failed.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & " "
       & "       <property type='Integer' name=""timeout_count"">" & ASCII.LF & " "
       & "           <comment>the number of tests that timeout.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Nullable_Date"
       & "' name=""build_date"" not-null=""no"">" & ASCII.LF & "            <comme"
       & "nt>the build date.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "    </class>" & ASCII.LF & ASCII.LF & "    <query name='project-build-s"
       & "tatus'>" & ASCII.LF & "        <comment>Get the build status of every re"
       & "cipes of a project</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & " "
       & "         SELECT" & ASCII.LF & "          recipe.id," & ASCII.LF & "     "
       & "     recipe.rate_factor," & ASCII.LF & "          build.status," & ASCII.LF
       & "          COALESCE(build.tag, '')," & ASCII.LF & "          COALESCE(bui"
       & "ld.number, 0)," & ASCII.LF & "          COALESCE(build.pass_count, 0)," & ASCII.LF
       & "          COALESCE(build.fail_count, 0)," & ASCII.LF & "          COALES"
       & "CE(build.timeout_count, 0)," & ASCII.LF & "          build.finish_date" & ASCII.LF
       & "          FROM porion_recipe AS recipe" & ASCII.LF & "          LEFT JOI"
       & "N porion_last_build AS last_build ON last_build.recipe_id = recipe.id" & ASCII.LF
       & "          LEFT JOIN porion_build AS build ON last_build.build_id = build"
       & ".id" & ASCII.LF & "          WHERE recipe.project_id = :project_id AND r"
       & "ecipe.branch_id = :branch_id AND" & ASCII.LF & "             (build.id I"
       & "S NULL OR build.id IN (SELECT MAX(sb.build_id) FROM porion_last_build AS"
       & " sb WHERE sb.recipe_id = recipe.id))" & ASCII.LF & "        </sql>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_10 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        List the build queues" & ASCII.LF
       & "    </description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Q"
       & "ueries.Queue_Info"" bean=""yes"">" & ASCII.LF & "        <comment>Inform"
       & "ation about a build queue.</comment>" & ASCII.LF & "        <property ty"
       & "pe='ADO.Identifier' name=""id"">" & ASCII.LF & "            <comment>the"
       & " build queue id.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Integer' name=""order"">" & ASCII.LF & "        "
       & "    <comment>the build queue order.</comment>" & ASCII.LF & "        </p"
       & "roperty>" & ASCII.LF & "        <property type='Date' name=""creation_da"
       & "te"" not-null=""yes"">" & ASCII.LF & "            <comment>the date when"
       & " the recipe was inserted in the queue.</comment>" & ASCII.LF & "        "
       & "</property>" & ASCII.LF & "        <property type='Boolean' name=""build"
       & "ing"">" & ASCII.LF & "            <comment>true if the build is running."
       & "</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <pr"
       & "operty type='String' name=""project_name"">" & ASCII.LF & "            <"
       & "comment>the project name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Porion.Projects.Models.Project_Status_Type' name"
       & "=""project_status"">" & ASCII.LF & "            <comment>the project sta"
       & "tus.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "       "
       & " <property type='String' name=""branch_name"">" & ASCII.LF & "          "
       & "  <comment>the branch name.</comment>" & ASCII.LF & "        </property>"
       & ASCII.LF & "        <property type='String' name=""branch_tag"">" & ASCII.LF
       & "            <comment>the branch tag.</comment>" & ASCII.LF & "        </"
       & "property>" & ASCII.LF & "        <property type='Porion.Projects.Models."
       & "Branch_Status_Type' name=""branch_status"">" & ASCII.LF & "            <"
       & "comment>the branch status.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='ADO.Identifier' name=""recipe_id"">" & ASCII.LF
       & "            <comment>the build recipe id.</comment>" & ASCII.LF & "     "
       & "   </property>" & ASCII.LF & "        <property type='String' name=""rec"
       & "ipe_name"">" & ASCII.LF & "            <comment>the recipe name.</commen"
       & "t>" & ASCII.LF & "        </property>" & ASCII.LF & "        <property t"
       & "ype='Porion.Builds.Models.Config_Status_Type' name=""recipe_status"">" & ASCII.LF
       & "            <comment>the recipe status.</comment>" & ASCII.LF & "       "
       & " </property>" & ASCII.LF & "        <property type='Boolean' name=""main"
       & "_recipe"">" & ASCII.LF & "            <comment>whether this is the main "
       & "recipe.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "    "
       & "    <property type='String' name=""node_name"">" & ASCII.LF & "         "
       & "   <comment>the node name where the build is executed.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Porion.Nodes."
       & "Node_Status_Type' name=""node_status"">" & ASCII.LF & "            <comm"
       & "ent>the current node status.</comment>" & ASCII.LF & "        </property"
       & ">" & ASCII.LF & "    </class>" & ASCII.LF & ASCII.LF & "    <query name"
       & "='build-queue-list'>" & ASCII.LF & "        <comment>Get a description o"
       & "f the build queue</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & " "
       & "           SELECT" & ASCII.LF & "            queue.id AS id," & ASCII.LF
       & "            queue.`order` AS `order`," & ASCII.LF & "            queue.c"
       & "reate_date AS create_date," & ASCII.LF & "            queue.building AS "
       & "building," & ASCII.LF & "            project.name AS name," & ASCII.LF & " "
       & "           project.status AS status," & ASCII.LF & "            branch.n"
       & "ame AS branch_name," & ASCII.LF & "            branch.tag AS branch_tag,"
       & ASCII.LF & "            branch.status AS branch_status," & ASCII.LF & " "
       & "           recipe.id AS recipe_id," & ASCII.LF & "            recipe.nam"
       & "e AS recipe_name," & ASCII.LF & "            recipe.status AS recipe_sta"
       & "tus," & ASCII.LF & "            recipe.main_recipe AS main_recipe," & ASCII.LF
       & "            node.name AS node_name," & ASCII.LF & "            node.stat"
       & "us AS node_status" & ASCII.LF & "            FROM porion_build_queue AS "
       & "queue" & ASCII.LF & "            INNER JOIN porion_node AS node ON queue"
       & ".node_id = node.id" & ASCII.LF & "            INNER JOIN porion_recipe A"
       & "S recipe ON queue.recipe_id = recipe.id" & ASCII.LF & "            INNER"
       & " JOIN porion_project AS project ON recipe.project_id = project.id" & ASCII.LF
       & "            INNER JOIN porion_branch AS branch ON recipe.branch_id = bra"
       & "nch.id" & ASCII.LF & "            ORDER BY queue.`order` ASC, queue.crea"
       & "te_date ASC" & ASCII.LF & "        </sql>" & ASCII.LF & "        <sql-co"
       & "unt>" & ASCII.LF & "            SELECT" & ASCII.LF & "            count("
       & "queue.id)" & ASCII.LF & "            FROM porion_build_queue AS queue" & ASCII.LF
       & "        </sql-count>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF
       & "    <query name='project-build-queue-list'>" & ASCII.LF & "        <comm"
       & "ent>Get a description of the build queue for a given project</comment>" & ASCII.LF
       & "        <sql>" & ASCII.LF & "            SELECT" & ASCII.LF & "         "
       & "   queue.id AS id," & ASCII.LF & "            queue.`order` AS `order`," & ASCII.LF
       & "            queue.create_date AS create_date," & ASCII.LF & "           "
       & " queue.building AS building," & ASCII.LF & "            project.name AS "
       & "name," & ASCII.LF & "            project.status AS status," & ASCII.LF & " "
       & "           branch.name AS branch_name," & ASCII.LF & "            branch"
       & ".tag AS branch_tag," & ASCII.LF & "            branch.status AS branch_s"
       & "tatus," & ASCII.LF & "            recipe.id AS recipe_id," & ASCII.LF & " "
       & "           recipe.name AS recipe_name," & ASCII.LF & "            recipe"
       & ".status AS recipe_status," & ASCII.LF & "            recipe.main_recipe "
       & "AS main_recipe," & ASCII.LF & "            node.name AS node_name," & ASCII.LF
       & "            node.status AS node_status" & ASCII.LF & "            FROM p"
       & "orion_build_queue AS queue" & ASCII.LF & "            INNER JOIN porion_"
       & "node AS node ON queue.node_id = node.id" & ASCII.LF & "            INNER"
       & " JOIN porion_recipe AS recipe ON queue.recipe_id = recipe.id" & ASCII.LF
       & "            INNER JOIN porion_project AS project ON recipe.project_id = "
       & "project.id" & ASCII.LF & "            INNER JOIN porion_branch AS branch"
       & " ON recipe.branch_id = branch.id" & ASCII.LF & "            WHERE projec"
       & "t.id = :project_id" & ASCII.LF & "            ORDER BY queue.`order` ASC"
       & ", queue.create_date ASC" & ASCII.LF & "        </sql>" & ASCII.LF & "   "
       & " </query>" & ASCII.LF & ASCII.LF & "    <query name='node-build-queue-l"
       & "ist'>" & ASCII.LF & "        <comment>Get a description of the build que"
       & "ue for a given build node</comment>" & ASCII.LF & "        <sql>" & ASCII.LF
       & "            SELECT" & ASCII.LF & "            queue.id AS id," & ASCII.LF
       & "            queue.`order` AS `order`," & ASCII.LF & "            queue.c"
       & "reation_date AS create_date," & ASCII.LF & "            queue.building A"
       & "S building," & ASCII.LF & "            project.name AS name," & ASCII.LF
       & "            project.status AS status," & ASCII.LF & "            branch."
       & "name AS branch_name," & ASCII.LF & "            branch.tag AS branch_tag"
       & "," & ASCII.LF & "            branch.status AS branch_status," & ASCII.LF
       & "            recipe.id AS recipe_id," & ASCII.LF & "            recipe.na"
       & "me AS recipe_name," & ASCII.LF & "            recipe.status AS recipe_st"
       & "atus," & ASCII.LF & "            recipe.main_recipe AS main_recipe," & ASCII.LF
       & "            node.name AS node_name," & ASCII.LF & "            node.stat"
       & "us AS node_status" & ASCII.LF & "            FROM porion_build_queue AS "
       & "queue" & ASCII.LF & "            INNER JOIN porion_node AS node ON queue"
       & ".node_id = node.id" & ASCII.LF & "            INNER JOIN porion_recipe A"
       & "S recipe ON queue.recipe_id = recipe.id" & ASCII.LF & "            INNER"
       & " JOIN porion_project AS project ON recipe.project_id = project.id" & ASCII.LF
       & "            INNER JOIN porion_branch AS branch ON recipe.branch_id = bra"
       & "nch.id" & ASCII.LF & "            WHERE node.id = :node_id" & ASCII.LF & " "
       & "           ORDER BY queue.`order` ASC, queue.create_date ASC" & ASCII.LF
       & "        </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "</"
       & "query-mapping>" & ASCII.LF;

   C_11 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        List of builds" & ASCII.LF & " "
       & "   </description>" & ASCII.LF & " " & ASCII.LF & "    <class name=""Pori"
       & "on.Queries.Build_Info"" bean=""no"">" & ASCII.LF & "        <comment>Inf"
       & "ormation about a build.</comment>" & ASCII.LF & "        <property type="
       & "'String' name=""name"">" & ASCII.LF & "            <comment>the project "
       & "name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "      "
       & "  <property type='Porion.Projects.Models.Project_Status_Type' name=""pro"
       & "ject_status"">" & ASCII.LF & "            <comment>the project status.</"
       & "comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <prop"
       & "erty type='String' name=""branch_name"">" & ASCII.LF & "            <com"
       & "ment>the branch name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Porion.Projects.Models.Branch_Status_Type' name="
       & """branch_status"">" & ASCII.LF & "            <comment>the branch status"
       & ".</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <p"
       & "roperty type='String' name=""node_name"">" & ASCII.LF & "            <co"
       & "mment>the node name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='String' name=""recipe_name"">" & ASCII.LF & "   "
       & "         <comment>the recipe name.</comment>" & ASCII.LF & "        </pr"
       & "operty>" & ASCII.LF & "        <property type='Integer' name=""build_id"""
       & ">" & ASCII.LF & "            <comment>the build id.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Integer' name"
       & "=""build_number"">" & ASCII.LF & "            <comment>the build number."
       & "</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <pr"
       & "operty type='String' name=""build_tag"">" & ASCII.LF & "            <com"
       & "ment>the build tag.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Porion.Builds.Models.Build_Status_Type' name=""b"
       & "uild_status"">" & ASCII.LF & "            <comment>the last build status"
       & ".</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <p"
       & "roperty type='Date' name=""build_date"" not-null=""no"">" & ASCII.LF & " "
       & "           <comment>the build starting date.</comment>" & ASCII.LF & "  "
       & "      </property>" & ASCII.LF & "        <property type='Nullable_Date' "
       & "name=""finish_date"" not-null=""no"">" & ASCII.LF & "            <commen"
       & "t>the build ending date.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Porion.Millisecond_Type' name=""build_duration"""
       & " not-null=""yes"">" & ASCII.LF & "            <comment>the build duratio"
       & "n.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <"
       & "property type='Integer' name=""pass_count"">" & ASCII.LF & "            "
       & "<comment>the number of tests that succeeded.</comment>" & ASCII.LF & "  "
       & "      </property>" & ASCII.LF & "        <property type='Integer' name="""
       & "fail_count"">" & ASCII.LF & "            <comment>the number of tests th"
       & "at failed.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & " "
       & "       <property type='Integer' name=""timeout_count"">" & ASCII.LF & " "
       & "           <comment>the number of tests that timeout.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "    </class>" & ASCII.LF & ASCII.LF
       & "   <query name='build-list'>" & ASCII.LF & "        <comment>Get the lis"
       & "t of builds</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & "      "
       & "      SELECT" & ASCII.LF & "            project.name AS name," & ASCII.LF
       & "            project.status AS status," & ASCII.LF & "            branch."
       & "name AS branch_name," & ASCII.LF & "            branch.status AS branch_"
       & "status," & ASCII.LF & "            node.name AS node_name," & ASCII.LF & " "
       & "           recipe.name AS recipe_name," & ASCII.LF & "            build."
       & "id AS build_id," & ASCII.LF & "            build.number AS number," & ASCII.LF
       & "            build.tag AS tag," & ASCII.LF & "            build.status AS"
       & " build_status," & ASCII.LF & "            build.create_date AS build_dat"
       & "e," & ASCII.LF & "            build.finish_date AS finish_date," & ASCII.LF
       & "            build.build_duration AS build_duration," & ASCII.LF & "     "
       & "       build.pass_count AS pass_count," & ASCII.LF & "            build."
       & "fail_count AS fail_count," & ASCII.LF & "            build.timeout_count"
       & " AS timeout_count" & ASCII.LF & "            FROM porion_build AS build" & ASCII.LF
       & "            INNER JOIN porion_project AS project ON build.project_id = p"
       & "roject.id" & ASCII.LF & "            INNER JOIN porion_branch AS branch "
       & "ON branch.id = build.branch_id" & ASCII.LF & "            INNER JOIN por"
       & "ion_recipe AS recipe ON build.recipe_id = recipe.id" & ASCII.LF & "     "
       & "       INNER JOIN porion_node AS node ON build.node_id = node.id" & ASCII.LF
       & "            ORDER BY finish_date DESC" & ASCII.LF & "        </sql>" & ASCII.LF
       & "        <sql-count>" & ASCII.LF & "            SELECT" & ASCII.LF & "   "
       & "         count(build.id)" & ASCII.LF & "            FROM porion_build AS"
       & " build" & ASCII.LF & "        </sql-count>" & ASCII.LF & "    </query>" & ASCII.LF
       & ASCII.LF & "   <query name='project-last-build-list'>" & ASCII.LF & "   "
       & "     <comment>Get the list of builds</comment>" & ASCII.LF & "        <s"
       & "ql>" & ASCII.LF & "            SELECT" & ASCII.LF & "            project"
       & ".name AS name," & ASCII.LF & "            project.status AS status," & ASCII.LF
       & "            branch.name AS branch_name," & ASCII.LF & "            branc"
       & "h.status AS branch_status," & ASCII.LF & "            node.name AS node_"
       & "name," & ASCII.LF & "            recipe.name AS recipe_name," & ASCII.LF
       & "            build.id AS build_id," & ASCII.LF & "            build.numbe"
       & "r AS number," & ASCII.LF & "            build.tag AS tag," & ASCII.LF & " "
       & "           build.status AS build_status," & ASCII.LF & "            buil"
       & "d.create_date AS build_date," & ASCII.LF & "            build.finish_dat"
       & "e AS finish_date," & ASCII.LF & "            build.build_duration AS bui"
       & "ld_duration," & ASCII.LF & "            build.pass_count AS pass_count," & ASCII.LF
       & "            build.fail_count AS fail_count," & ASCII.LF & "            b"
       & "uild.timeout_count AS timeout_count" & ASCII.LF & "            FROM pori"
       & "on_last_build AS last_build" & ASCII.LF & "            INNER JOIN porion"
       & "_build AS build ON last_build.build_id = build.id" & ASCII.LF & "       "
       & "     INNER JOIN porion_project AS project ON build.project_id = project."
       & "id" & ASCII.LF & "            INNER JOIN porion_branch AS branch ON bran"
       & "ch.id = build.branch_id" & ASCII.LF & "            INNER JOIN porion_rec"
       & "ipe AS recipe ON build.recipe_id = recipe.id" & ASCII.LF & "            "
       & "INNER JOIN porion_node AS node ON build.node_id = node.id" & ASCII.LF & " "
       & "           WHERE project.id = :project_id" & ASCII.LF & "            ORD"
       & "ER BY finish_date DESC" & ASCII.LF & "        </sql>" & ASCII.LF & "    "
       & "</query>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_12 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        List of environment variables" & ASCII.LF
       & "    </description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Q"
       & "ueries.Environment_Info"" bean=""yes"">" & ASCII.LF & "        <comment>"
       & "Information about a project.</comment>" & ASCII.LF & "        <property "
       & "type='String' name=""name"">" & ASCII.LF & "            <comment>the env"
       & "ironment variable name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='String' name=""value"">" & ASCII.LF & "         "
       & "   <comment>the environment variable value.</comment>" & ASCII.LF & "   "
       & "     </property>" & ASCII.LF & "        <property type='String' name=""p"
       & "roject_name"">" & ASCII.LF & "            <comment>the optional project "
       & "name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "      "
       & "  <property type='String' name=""branch_name"">" & ASCII.LF & "         "
       & "   <comment>the optional branch name.</comment>" & ASCII.LF & "        <"
       & "/property>" & ASCII.LF & "        <property type='String' name=""recipe_"
       & "name"">" & ASCII.LF & "            <comment>the optional recipe name.</c"
       & "omment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <prope"
       & "rty type='String' name=""node_name"">" & ASCII.LF & "            <commen"
       & "t>the optional build node name.</comment>" & ASCII.LF & "        </prope"
       & "rty>" & ASCII.LF & "    </class>" & ASCII.LF & ASCII.LF & "    <query n"
       & "ame='environment-list'>" & ASCII.LF & "        <comment>Get the list of "
       & "environment variables</comment>" & ASCII.LF & "        <sql>" & ASCII.LF
       & "            SELECT" & ASCII.LF & "            env.name AS name," & ASCII.LF
       & "            env.value AS value," & ASCII.LF & "            COALESCE(proj"
       & "ect.name, '') AS project_name," & ASCII.LF & "            COALESCE(branc"
       & "h.name, '') AS branch_name," & ASCII.LF & "            COALESCE(recipe.n"
       & "ame, '') AS recipe_name," & ASCII.LF & "            COALESCE(node.name, "
       & "'') AS node_name" & ASCII.LF & "            FROM porion_environment AS e"
       & "nv" & ASCII.LF & "            LEFT JOIN porion_branch AS branch ON env.b"
       & "ranch_id = branch.id" & ASCII.LF & "            LEFT JOIN porion_project"
       & " AS project ON env.project_id = project.id" & ASCII.LF & "            LE"
       & "FT JOIN porion_node AS node ON env.node_id = node.id" & ASCII.LF & "    "
       & "        LEFT JOIN porion_recipe AS recipe ON env.recipe_id = recipe.id" & ASCII.LF
       & "            ORDER BY node_name, project_name, branch_name, recipe_name, "
       & "name" & ASCII.LF & "        </sql>" & ASCII.LF & "        <sql-count>" & ASCII.LF
       & "            SELECT" & ASCII.LF & "            count(env.id)" & ASCII.LF
       & "            FROM porion_environment AS env" & ASCII.LF & "        </sql-"
       & "count>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "    <query"
       & " name='project-environment-list'>" & ASCII.LF & "        <comment>Get th"
       & "e list of environment variables</comment>" & ASCII.LF & "        <sql>" & ASCII.LF
       & "            SELECT" & ASCII.LF & "            env.name AS name," & ASCII.LF
       & "            env.value AS value," & ASCII.LF & "            project.name "
       & "AS name," & ASCII.LF & "            COALESCE(branch.name, '') AS branch_"
       & "name," & ASCII.LF & "            COALESCE(recipe.name, '') AS recipe_nam"
       & "e," & ASCII.LF & "            COALESCE(node.name, '') AS node_name" & ASCII.LF
       & "            FROM porion_environment AS env" & ASCII.LF & "            LE"
       & "FT JOIN porion_branch AS branch ON env.branch_id = branch.id" & ASCII.LF
       & "            LEFT JOIN porion_project AS project ON env.project_id = proj"
       & "ect.id" & ASCII.LF & "            LEFT JOIN porion_node AS node ON env.n"
       & "ode_id = node.id" & ASCII.LF & "            WHERE env.project_id = :proj"
       & "ect_id OR env.project_id IS NULL" & ASCII.LF & "        </sql>" & ASCII.LF
       & "        <sql-count>" & ASCII.LF & "            SELECT" & ASCII.LF & "   "
       & "         count(env.id)" & ASCII.LF & "            FROM porion_environmen"
       & "t AS env" & ASCII.LF & "            WHERE env.project_id = :project_id O"
       & "R env.project_id IS NULL" & ASCII.LF & "        </sql-count>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_13 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        List of projects" & ASCII.LF & " "
       & "   </description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Qu"
       & "eries.Project_Info"" bean=""yes"">" & ASCII.LF & "        <comment>Infor"
       & "mation about a project.</comment>" & ASCII.LF & "        <property type="
       & "'String' name=""name"">" & ASCII.LF & "            <comment>the project "
       & "name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "      "
       & "  <property type='Porion.Projects.Models.Project_Status_Type' name=""pro"
       & "ject_status"">" & ASCII.LF & "            <comment>the project status.</"
       & "comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <prop"
       & "erty type='Porion.Permille_Type' name=""build_progress"">" & ASCII.LF & " "
       & "           <comment>the build progress (how much pending build have been"
       & " made).</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "    "
       & "    <property type='Porion.Permille_Type' name=""build_rate"">" & ASCII.LF
       & "            <comment>the build success rate (how much success on builds)"
       & ".</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <p"
       & "roperty type='Porion.Permille_Type' name=""pass_rate"">" & ASCII.LF & " "
       & "           <comment>the build test success rate (how much success on uni"
       & "t tests).</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "  "
       & "      <property type='Porion.Permille_Type' name=""failure_rate"">" & ASCII.LF
       & "            <comment>the build test failure rate (how much failure on un"
       & "it tests).</comment>" & ASCII.LF & "        </property>" & ASCII.LF & " "
       & "       <property type='Porion.Permille_Type' name=""timeout_rate"">" & ASCII.LF
       & "            <comment>the build test timeout rate (how much timeout on un"
       & "it tests).</comment>" & ASCII.LF & "        </property>" & ASCII.LF & " "
       & "       <property type='String' name=""branch_name"">" & ASCII.LF & "    "
       & "        <comment>the branch name.</comment>" & ASCII.LF & "        </pro"
       & "perty>" & ASCII.LF & "        <property type='String' name=""branch_tag"""
       & ">" & ASCII.LF & "            <comment>the branch tag.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Porion.Projec"
       & "ts.Models.Branch_Status_Type' name=""branch_status"">" & ASCII.LF & "   "
       & "         <comment>the branch status.</comment>" & ASCII.LF & "        </"
       & "property>" & ASCII.LF & "        <property type='Nullable_Date' name=""b"
       & "uild_date"" not-null=""no"">" & ASCII.LF & "            <comment>the bui"
       & "ld date.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "   "
       & "     <property type='Porion.Builds.Models.Build_Status_Type' name=""buil"
       & "d_status"">" & ASCII.LF & "            <comment>the last build status.</"
       & "comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <prop"
       & "erty type='String' name=""build_tag"">" & ASCII.LF & "            <comme"
       & "nt>the build tag.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Integer' name=""build_number"">" & ASCII.LF & " "
       & "           <comment>the build number.</comment>" & ASCII.LF & "        <"
       & "/property>" & ASCII.LF & "        <property type='Integer' name=""pass_c"
       & "ount"">" & ASCII.LF & "            <comment>the number of tests that suc"
       & "ceeded.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "    "
       & "    <property type='Integer' name=""fail_count"">" & ASCII.LF & "       "
       & "     <comment>the number of tests that failed.</comment>" & ASCII.LF & " "
       & "       </property>" & ASCII.LF & "        <property type='Integer' name="
       & """timeout_count"">" & ASCII.LF & "            <comment>the number of tes"
       & "ts that timeout.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "    </class>" & ASCII.LF & ASCII.LF & "    <query name='project-list'>" & ASCII.LF
       & "        <comment>Get the list of projects</comment>" & ASCII.LF & "     "
       & "   <sql>" & ASCII.LF & "            SELECT" & ASCII.LF & "            pr"
       & "oject.name AS name," & ASCII.LF & "            project.status AS status,"
       & ASCII.LF & "            project.build_progress AS build_progress," & ASCII.LF
       & "            project.build_rate AS build_rate," & ASCII.LF & "           "
       & " project.pass_rate AS pass_rate," & ASCII.LF & "            project.fail"
       & "_rate AS fail_rate," & ASCII.LF & "            project.timeout_rate AS t"
       & "imeout_rate," & ASCII.LF & "            COALESCE(branch.name, '') AS bra"
       & "nch_name," & ASCII.LF & "            COALESCE(branch.tag, '') AS branch_"
       & "tag," & ASCII.LF & "            COALESCE(branch.status, 0) AS branch_sta"
       & "tus," & ASCII.LF & "            build.finish_date AS build_date," & ASCII.LF
       & "            COALESCE(build.status, 0) AS build_status," & ASCII.LF & "  "
       & "          COALESCE(build.tag, '') AS build_tag," & ASCII.LF & "         "
       & "   COALESCE(build.number, 0) AS build_number," & ASCII.LF & "           "
       & " COALESCE(build.pass_count, 0) AS pass_count," & ASCII.LF & "           "
       & " COALESCE(build.fail_count, 0) AS fail_count," & ASCII.LF & "           "
       & " COALESCE(build.timeout_count, 0) AS timeout_count" & ASCII.LF & "      "
       & "      FROM porion_project AS project" & ASCII.LF & "            LEFT JOI"
       & "N porion_branch AS branch ON project.id = branch.project_id AND branch.s"
       & "tatus != 0" & ASCII.LF & "            LEFT JOIN porion_last_build AS las"
       & "t_build ON last_build.branch_id = branch.id AND last_build.last_build = "
       & "1" & ASCII.LF & "            LEFT JOIN porion_build AS build ON last_bui"
       & "ld.build_id = build.id" & ASCII.LF & "        </sql>" & ASCII.LF & "    "
       & "    <sql-count>" & ASCII.LF & "            SELECT" & ASCII.LF & "       "
       & "     count(project.id)" & ASCII.LF & "            FROM porion_project AS"
       & " project" & ASCII.LF & "        </sql-count>" & ASCII.LF & "    </query>"
       & ASCII.LF & ASCII.LF & "    <query name='project-dependency-list'>" & ASCII.LF
       & "        <comment>Get the list of projects that another project depend on"
       & "</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & "            SELEC"
       & "T" & ASCII.LF & "            project.name AS name," & ASCII.LF & "      "
       & "      project.status AS status," & ASCII.LF & "            project.build"
       & "_progress AS build_progress," & ASCII.LF & "            project.build_ra"
       & "te AS build_rate," & ASCII.LF & "            project.pass_rate AS pass_r"
       & "ate," & ASCII.LF & "            project.fail_rate AS fail_rate," & ASCII.LF
       & "            project.timeout_rate AS timeout_rate," & ASCII.LF & "       "
       & "     COALESCE(branch.name, '') AS branch_name," & ASCII.LF & "          "
       & "  COALESCE(branch.tag, '') AS branch_tag," & ASCII.LF & "            COA"
       & "LESCE(branch.status, 0) AS branch_status," & ASCII.LF & "            bui"
       & "ld.finish_date AS build_date," & ASCII.LF & "            COALESCE(build."
       & "status, 0) AS build_status," & ASCII.LF & "            COALESCE(build.ta"
       & "g, '') AS build_tag," & ASCII.LF & "            COALESCE(build.number, 0"
       & ") AS build_number," & ASCII.LF & "            COALESCE(build.pass_count,"
       & " 0) AS pass_count," & ASCII.LF & "            COALESCE(build.fail_count,"
       & " 0) AS fail_count," & ASCII.LF & "            COALESCE(build.timeout_cou"
       & "nt, 0) AS timeout_count" & ASCII.LF & "            FROM porion_dependenc"
       & "y AS dependency" & ASCII.LF & "            INNER JOIN porion_project AS "
       & "project ON dependency.project_id = project.id" & ASCII.LF & "           "
       & " LEFT JOIN porion_branch AS branch ON project.id = branch.project_id AND"
       & " branch.status != 0" & ASCII.LF & "            LEFT JOIN porion_last_bui"
       & "ld AS last_build ON last_build.branch_id = branch.id AND last_build.last"
       & "_build = 1" & ASCII.LF & "            LEFT JOIN porion_build AS build ON"
       & " last_build.build_id = build.id" & ASCII.LF & "            WHERE depende"
       & "ncy.owner_id = :project_id AND" & ASCII.LF & "            (build.id IS N"
       & "ULL OR build.id IN (SELECT MAX(sb.build_id) FROM porion_last_build AS sb"
       & ASCII.LF & "                INNER JOIN porion_branch AS br ON sb.branch_"
       & "id = br.id WHERE br.project_id = project.id))" & ASCII.LF & "        </s"
       & "ql>" & ASCII.LF & "        <sql-count>" & ASCII.LF & "            SELECT"
       & ASCII.LF & "            count(project.id)" & ASCII.LF & "            FRO"
       & "M porion_project AS project" & ASCII.LF & "        </sql-count>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_14 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        List the tests" & ASCII.LF & " "
       & "   </description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Qu"
       & "eries.Test_Info"" bean=""yes"">" & ASCII.LF & "        <comment>Informat"
       & "ion about a test.</comment>" & ASCII.LF & "        <property type='ADO.I"
       & "dentifier' name=""id"">" & ASCII.LF & "            <comment>the test gro"
       & "up id.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "     "
       & "   <property type='String' name=""group_name"">" & ASCII.LF & "         "
       & "   <comment>the test group name.</comment>" & ASCII.LF & "        </prop"
       & "erty>" & ASCII.LF & "        <property type='ADO.Identifier' name=""test"
       & "_id"">" & ASCII.LF & "            <comment>the test id.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='String' name="
       & """test_name"">" & ASCII.LF & "            <comment>the test name.</comme"
       & "nt>" & ASCII.LF & "        </property>" & ASCII.LF & "        <property "
       & "type='Integer' name=""test_pass_count"">" & ASCII.LF & "            <com"
       & "ment>the number of times the test passed.</comment>" & ASCII.LF & "     "
       & "   </property>" & ASCII.LF & "        <property type='Integer' name=""te"
       & "st_fail_count"">" & ASCII.LF & "            <comment>the number of times"
       & " the test failed.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Integer' name=""test_timeout_count"">" & ASCII.LF
       & "            <comment>the number of times the test timed out.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Porion.Micros"
       & "econd_Type' name=""test_duration"">" & ASCII.LF & "            <comment>"
       & "the test duration.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Porion.XUnit.Models.Test_Status_Type' name=""tes"
       & "t_status"">" & ASCII.LF & "            <comment>the test status.</commen"
       & "t>" & ASCII.LF & "        </property>" & ASCII.LF & "    </class>" & ASCII.LF
       & ASCII.LF & "    <query name='build-test-list'>" & ASCII.LF & "        <c"
       & "omment>Get the list of tests for a build</comment>" & ASCII.LF & "      "
       & "  <sql>" & ASCII.LF & "            SELECT" & ASCII.LF & "            grp"
       & ".id AS id," & ASCII.LF & "            grp.name AS grp_name," & ASCII.LF
       & "            test.id AS tid," & ASCII.LF & "            test.name AS test"
       & "_name," & ASCII.LF & "            test.total_pass_count AS pass_count," & ASCII.LF
       & "            test.total_fail_count AS fail_count," & ASCII.LF & "        "
       & "    test.total_timeout_count AS timeout_count," & ASCII.LF & "          "
       & "  run.duration AS duration," & ASCII.LF & "            run.status AS sta"
       & "tus" & ASCII.LF & "            FROM porion_test_run_group AS rgrp" & ASCII.LF
       & "            INNER JOIN porion_test_group AS grp ON rgrp.group_id = grp.i"
       & "d" & ASCII.LF & "            INNER JOIN porion_test_run AS run ON run.gr"
       & "oup_id = rgrp.id" & ASCII.LF & "            INNER JOIN porion_test AS te"
       & "st ON run.test_id = test.id" & ASCII.LF & "            WHERE rgrp.build_"
       & "id = :build_id" & ASCII.LF & "        </sql>" & ASCII.LF & "    </query>"
       & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_15 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        Stats for the builds" & ASCII.LF
       & "    </description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Q"
       & "ueries.Build_Stat"" bean=""yes"">" & ASCII.LF & "        <comment>Statis"
       & "tics about a list of builds.</comment>" & ASCII.LF & "        <property "
       & "type='Porion.Builds.Models.Build_Status_Type' name=""build_status"">" & ASCII.LF
       & "            <comment>the build status.</comment>" & ASCII.LF & "        "
       & "</property>" & ASCII.LF & "        <property type='Natural' name=""count"
       & """>" & ASCII.LF & "            <comment>the number of builds.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Natural' name"
       & "=""pass_count"">" & ASCII.LF & "            <comment>the total number of"
       & " tests that passed.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Natural' name=""fail_count"">" & ASCII.LF & "   "
       & "         <comment>the total number of tests that failed.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Natural' name"
       & "=""timeout_count"">" & ASCII.LF & "            <comment>the total number"
       & " of tests that timeout.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Natural' name=""test_duration"">" & ASCII.LF & " "
       & "           <comment>the total duration of all tests.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Porion.Millis"
       & "econd_Type' name=""build_duration"" not-null=""yes"">" & ASCII.LF & "   "
       & "         <comment>the total build duration.</comment>" & ASCII.LF & "   "
       & "     </property>" & ASCII.LF & "        <property type='Porion.Milliseco"
       & "nd_Type' name=""sys_time"" not-null=""yes"">" & ASCII.LF & "            "
       & "<comment>the total system time.</comment>" & ASCII.LF & "        </prope"
       & "rty>" & ASCII.LF & "        <property type='Porion.Millisecond_Type' nam"
       & "e=""user_time"" not-null=""yes"">" & ASCII.LF & "            <comment>th"
       & "e total user time.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "    </class>" & ASCII.LF & ASCII.LF & "    <query name='stat-builds'>" & ASCII.LF
       & "        <comment>Statistics about the last project builds</comment>" & ASCII.LF
       & "        <sql>" & ASCII.LF & "          SELECT" & ASCII.LF & "          b"
       & "uild.status AS status," & ASCII.LF & "          COUNT(build.id) AS cnt," & ASCII.LF
       & "          SUM(build.pass_count) AS pass_count," & ASCII.LF & "          "
       & "SUM(build.fail_count) AS fail_count," & ASCII.LF & "          SUM(build."
       & "timeout_count) AS timeout_count," & ASCII.LF & "          SUM(build.test"
       & "_duration) AS test_duration," & ASCII.LF & "          SUM(build.build_du"
       & "ration) AS build_duration," & ASCII.LF & "          SUM(build.sys_time) "
       & "AS sys_time," & ASCII.LF & "          SUM(build.user_time) AS user_time" & ASCII.LF
       & "          FROM porion_last_build AS last_build" & ASCII.LF & "          "
       & "INNER JOIN porion_build AS build ON last_build.build_id = build.id" & ASCII.LF
       & "          WHERE last_build.last_build = 1" & ASCII.LF & "          GROUP"
       & " BY build.status" & ASCII.LF & "        </sql>" & ASCII.LF & "    </quer"
       & "y> " & ASCII.LF & ASCII.LF & "    <query name='stat-project-builds'>" & ASCII.LF
       & "        <comment>Stats about the last project builds</comment>" & ASCII.LF
       & "        <sql>" & ASCII.LF & "          SELECT" & ASCII.LF & "          b"
       & "uild.status AS status," & ASCII.LF & "          COUNT(build.id) AS cnt," & ASCII.LF
       & "          SUM(build.pass_count) AS pass_count," & ASCII.LF & "          "
       & "SUM(build.fail_count) AS fail_count," & ASCII.LF & "          SUM(build."
       & "timeout_count) AS timeout_count," & ASCII.LF & "          SUM(build.test"
       & "_duration) AS test_duration," & ASCII.LF & "          SUM(build.build_du"
       & "ration) AS build_duration," & ASCII.LF & "          SUM(build.sys_time) "
       & "AS sys_time," & ASCII.LF & "          SUM(build.user_time) AS user_time" & ASCII.LF
       & "          FROM porion_last_build AS last_build" & ASCII.LF & "          "
       & "INNER JOIN porion_build AS build ON last_build.build_id = build.id" & ASCII.LF
       & "          WHERE last_build.last_build = 1 AND build.project_id = :projec"
       & "t_id" & ASCII.LF & "          GROUP BY build.status" & ASCII.LF & "     "
       & "   </sql>" & ASCII.LF & "    </query> " & ASCII.LF & ASCII.LF & "</quer"
       & "y-mapping>" & ASCII.LF;

   C_16 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        Stats with the build metrics" & ASCII.LF
       & "    </description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Q"
       & "ueries.Metric_Stat"" bean=""yes"">" & ASCII.LF & "        <comment>Stati"
       & "stics with build metrics.</comment>" & ASCII.LF & "        <property typ"
       & "e='Porion.Metrics.Metric_Type' name=""kind"">" & ASCII.LF & "           "
       & " <comment>the metric type.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='String' name=""name"">" & ASCII.LF & "          "
       & "  <comment>the metric logical name.</comment>" & ASCII.LF & "        </p"
       & "roperty>" & ASCII.LF & "        <property type='String' name=""label"">" & ASCII.LF
       & "            <comment>the metric label.</comment>" & ASCII.LF & "        "
       & "</property>" & ASCII.LF & "        <property type='Integer' name=""sum_v"
       & "alue"">" & ASCII.LF & "            <comment>the sum of metric value.</co"
       & "mment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <proper"
       & "ty type='Integer' name=""max_value"">" & ASCII.LF & "            <commen"
       & "t>the max metric value.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Integer' name=""count"">" & ASCII.LF & "        "
       & "    <comment>the number of metric.</comment>" & ASCII.LF & "        </pr"
       & "operty>" & ASCII.LF & "    </class>" & ASCII.LF & ASCII.LF & "    <quer"
       & "y name='stat-metrics'>" & ASCII.LF & "        <comment>Statistics about "
       & "the last project build metrics (all projects)</comment>" & ASCII.LF & " "
       & "       <sql>" & ASCII.LF & "          SELECT" & ASCII.LF & "          me"
       & "tric.metric," & ASCII.LF & "          metric.name," & ASCII.LF & "      "
       & "    metric.label," & ASCII.LF & "          SUM(mb.value) AS value," & ASCII.LF
       & "          MAX(mb.value) AS max_value," & ASCII.LF & "          COUNT(mb."
       & "id) AS CNT" & ASCII.LF & "          FROM porion_last_build AS last_build"
       & ASCII.LF & "          INNER JOIN porion_build_metric AS mb ON mb.build_i"
       & "d = last_build.build_id" & ASCII.LF & "          INNER JOIN porion_metri"
       & "c AS metric ON mb.metric_id = metric.id" & ASCII.LF & "          WHERE l"
       & "ast_build.status = 2 AND last_build.last_build = 1" & ASCII.LF & "      "
       & "    GROUP BY metric.name" & ASCII.LF & "        </sql>" & ASCII.LF & "  "
       & "  </query> " & ASCII.LF & ASCII.LF & "    <query name='stat-project-met"
       & "rics'>" & ASCII.LF & "        <comment>Statistics about the last project"
       & " build metrics (specific project)</comment>" & ASCII.LF & "        <sql>"
       & ASCII.LF & "          SELECT" & ASCII.LF & "          metric.metric," & ASCII.LF
       & "          metric.name," & ASCII.LF & "          metric.label," & ASCII.LF
       & "          SUM(mb.value) AS value," & ASCII.LF & "          MAX(mb.value)"
       & " AS max_value," & ASCII.LF & "          COUNT(mb.id) AS CNT" & ASCII.LF
       & "          FROM porion_last_build AS last_build" & ASCII.LF & "          "
       & "INNER JOIN porion_build AS build ON last_build.build_id = build.id" & ASCII.LF
       & "          INNER JOIN porion_build_metric AS mb ON mb.build_id = last_bui"
       & "ld.build_id" & ASCII.LF & "          INNER JOIN porion_metric AS metric "
       & "ON mb.metric_id = metric.id" & ASCII.LF & "          WHERE last_build.st"
       & "atus = 2 AND last_build.last_build = 1" & ASCII.LF & "          AND buil"
       & "d.project_id = :project_id" & ASCII.LF & "          GROUP BY metric.name"
       & ASCII.LF & "        </sql>" & ASCII.LF & "    </query> " & ASCII.LF & ASCII.LF
       & "</query-mapping>" & ASCII.LF;


   type Content_List_Array is array (Natural range <>) of access constant String;
   Contents : constant Content_List_Array := (
      C_0'Access, C_1'Access, C_2'Access, C_3'Access, C_4'Access, C_5'Access,
      C_6'Access, C_7'Access, C_8'Access, C_9'Access, C_10'Access, C_11'Access,
      C_12'Access, C_13'Access, C_14'Access, C_15'Access, C_16'Access);

   function Get_Content (Name : String) return access constant String is
      H : constant Natural := Hash (Name);
   begin
      return (if Names (H).all = Name then Contents (H) else null);
   end Get_Content;

end Porion.Resources.Queries;
