--  Advanced Resource Embedder 1.2.0
with Interfaces; use Interfaces;

package body Porion.Resources.Queries is
   function Hash (S : String) return Natural;

   P : constant array (0 .. 2) of Natural :=
     (1, 9, 10);

   T1 : constant array (0 .. 2) of Unsigned_8 :=
     (4, 19, 18);

   T2 : constant array (0 .. 2) of Unsigned_8 :=
     (4, 6, 5);

   G : constant array (0 .. 20) of Unsigned_8 :=
     (0, 0, 0, 3, 0, 1, 7, 0, 0, 8, 6, 4, 9, 0, 0, 0, 0, 2, 0, 5, 0);

   function Hash (S : String) return Natural is
      F : constant Natural := S'First - 1;
      L : constant Natural := S'Length;
      F1, F2 : Natural := 0;
      J : Natural;
   begin
      for K in P'Range loop
         exit when L < P (K);
         J  := Character'Pos (S (P (K) + F));
         F1 := (F1 + Natural (T1 (K)) * J) mod 21;
         F2 := (F2 + Natural (T2 (K)) * J) mod 21;
      end loop;
      return (Natural (G (F1)) + Natural (G (F2))) mod 10;
   end Hash;

   C_0 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Queries to"
       & " cleanup a project" & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF
       & "    <query name='cleanup-project-build-step'>" & ASCII.LF & "       <com"
       & "ment>Cleanup the build steps of a project.</comment>" & ASCII.LF & "    "
       & "   <sql>" & ASCII.LF & "    DELETE FROM porion_build_step WHERE build_id"
       & " IN" & ASCII.LF & "      (SELECT id FROM porion_build WHERE project_id ="
       & " :project_id)" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF
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
       & "ry>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-project-build-co"
       & "nfig-step'>" & ASCII.LF & "       <comment>Cleanup the project build con"
       & "fig of a project.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & " "
       & "   DELETE FROM porion_recipe_step WHERE recipe_id IN" & ASCII.LF & "    "
       & "  (SELECT id FROM porion_recipe WHERE project_id = :project_id)" & ASCII.LF
       & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "   "
       & " <query name='cleanup-project-build-config'>" & ASCII.LF & "       <comm"
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

   C_1 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
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

   C_2 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
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
       & "roperty type='String' name=""recipe_name"">" & ASCII.LF & "            <"
       & "comment>the recipe name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Integer' name=""build_id"">" & ASCII.LF & "     "
       & "       <comment>the build id.</comment>" & ASCII.LF & "        </propert"
       & "y>" & ASCII.LF & "        <property type='Integer' name=""build_number"""
       & ">" & ASCII.LF & "            <comment>the build number.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='String' name="
       & """build_tag"">" & ASCII.LF & "            <comment>the build tag.</comme"
       & "nt>" & ASCII.LF & "        </property>" & ASCII.LF & "        <property "
       & "type='Porion.Builds.Models.Build_Status_Type' name=""build_status"">" & ASCII.LF
       & "            <comment>the last build status.</comment>" & ASCII.LF & "   "
       & "     </property>" & ASCII.LF & "        <property type='Date' name=""bui"
       & "ld_date"" not-null=""no"">" & ASCII.LF & "            <comment>the build"
       & " starting date.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Nullable_Date' name=""finish_date"" not-null=""n"
       & "o"">" & ASCII.LF & "            <comment>the build ending date.</comment"
       & ">" & ASCII.LF & "        </property>" & ASCII.LF & "        <property ty"
       & "pe='Integer' name=""pass_count"">" & ASCII.LF & "            <comment>th"
       & "e number of tests that succeeded.</comment>" & ASCII.LF & "        </pro"
       & "perty>" & ASCII.LF & "        <property type='Integer' name=""fail_count"
       & """>" & ASCII.LF & "            <comment>the number of tests that failed."
       & "</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <pr"
       & "operty type='Integer' name=""timeout_count"">" & ASCII.LF & "           "
       & " <comment>the number of tests that timeout.</comment>" & ASCII.LF & "   "
       & "     </property>" & ASCII.LF & "    </class>" & ASCII.LF & ASCII.LF & " "
       & "  <query name='build-list'>" & ASCII.LF & "        <comment>Get the list"
       & " of builds</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & "       "
       & "     SELECT" & ASCII.LF & "            project.name AS name," & ASCII.LF
       & "            project.status AS status," & ASCII.LF & "            branch."
       & "name AS branch_name," & ASCII.LF & "            branch.status AS branch_"
       & "status," & ASCII.LF & "            recipe.name AS recipe_name," & ASCII.LF
       & "            build.id AS build_id," & ASCII.LF & "            build.numbe"
       & "r AS number," & ASCII.LF & "            build.tag AS tag," & ASCII.LF & " "
       & "           build.status AS build_status," & ASCII.LF & "            buil"
       & "d.create_date AS build_date," & ASCII.LF & "            build.finish_dat"
       & "e AS finish_date," & ASCII.LF & "            build.pass_count AS pass_co"
       & "unt," & ASCII.LF & "            build.fail_count AS fail_count," & ASCII.LF
       & "            build.timeout_count AS timeout_count" & ASCII.LF & "        "
       & "    FROM porion_build AS build" & ASCII.LF & "            INNER JOIN por"
       & "ion_project AS project ON build.project_id = project.id" & ASCII.LF & " "
       & "           INNER JOIN porion_branch AS branch ON branch.id = build.branc"
       & "h_id" & ASCII.LF & "            INNER JOIN porion_recipe AS recipe ON bu"
       & "ild.recipe_id = recipe.id" & ASCII.LF & "            ORDER BY finish_dat"
       & "e DESC" & ASCII.LF & "        </sql>" & ASCII.LF & "        <sql-count>" & ASCII.LF
       & "            SELECT" & ASCII.LF & "            count(build.id)" & ASCII.LF
       & "            FROM porion_build AS build" & ASCII.LF & "        </sql-coun"
       & "t>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "   <query name"
       & "='project-last-build-list'>" & ASCII.LF & "        <comment>Get the list"
       & " of builds</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & "       "
       & "     SELECT" & ASCII.LF & "            project.name AS name," & ASCII.LF
       & "            project.status AS status," & ASCII.LF & "            branch."
       & "name AS branch_name," & ASCII.LF & "            branch.status AS branch_"
       & "status," & ASCII.LF & "            recipe.name AS recipe_name," & ASCII.LF
       & "            build.id AS build_id," & ASCII.LF & "            build.numbe"
       & "r AS number," & ASCII.LF & "            build.tag AS tag," & ASCII.LF & " "
       & "           build.status AS build_status," & ASCII.LF & "            buil"
       & "d.create_date AS build_date," & ASCII.LF & "            build.finish_dat"
       & "e AS finish_date," & ASCII.LF & "            build.pass_count AS pass_co"
       & "unt," & ASCII.LF & "            build.fail_count AS fail_count," & ASCII.LF
       & "            build.timeout_count AS timeout_count" & ASCII.LF & "        "
       & "    FROM porion_last_build AS last_build" & ASCII.LF & "            INNE"
       & "R JOIN porion_build AS build ON last_build.build_id = build.id" & ASCII.LF
       & "            INNER JOIN porion_project AS project ON build.project_id = p"
       & "roject.id" & ASCII.LF & "            INNER JOIN porion_branch AS branch "
       & "ON branch.id = build.branch_id" & ASCII.LF & "            INNER JOIN por"
       & "ion_recipe AS recipe ON build.recipe_id = config.id" & ASCII.LF & "     "
       & "       WHERE project.id = :project_id" & ASCII.LF & "            ORDER B"
       & "Y finish_date DESC" & ASCII.LF & "        </sql>" & ASCII.LF & "    </qu"
       & "ery>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_3 : aliased constant String := "<query-mapping package='Porion.Projects.M"
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

   C_4 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
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
       & "id" & ASCII.LF & "            WHERE node.deleted = 0 AND config.project_"
       & "id = :project_id" & ASCII.LF & "            GROUP BY node.id" & ASCII.LF
       & "            ORDER BY node.name" & ASCII.LF & "        </sql>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_5 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        List of projects" & ASCII.LF & " "
       & "   </description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Qu"
       & "eries.Project_Info"" bean=""yes"">" & ASCII.LF & "        <comment>Infor"
       & "mation about a project.</comment>" & ASCII.LF & "        <property type="
       & "'String' name=""name"">" & ASCII.LF & "            <comment>the project "
       & "name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "      "
       & "  <property type='Porion.Projects.Models.Project_Status_Type' name=""pro"
       & "ject_status"">" & ASCII.LF & "            <comment>the project status.</"
       & "comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <prop"
       & "erty type='String' name=""branch_name"">" & ASCII.LF & "            <com"
       & "ment>the branch name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='String' name=""branch_tag"">" & ASCII.LF & "    "
       & "        <comment>the branch tag.</comment>" & ASCII.LF & "        </prop"
       & "erty>" & ASCII.LF & "        <property type='Porion.Projects.Models.Bran"
       & "ch_Status_Type' name=""branch_status"">" & ASCII.LF & "            <comm"
       & "ent>the branch status.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Nullable_Date' name=""build_date"" not-null=""no"
       & """>" & ASCII.LF & "            <comment>the build date.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Porion.Builds"
       & ".Models.Build_Status_Type' name=""build_status"">" & ASCII.LF & "       "
       & "     <comment>the last build status.</comment>" & ASCII.LF & "        </"
       & "property>" & ASCII.LF & "        <property type='String' name=""build_ta"
       & "g"">" & ASCII.LF & "            <comment>the build tag.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Integer' name"
       & "=""pass_count"">" & ASCII.LF & "            <comment>the number of tests"
       & " that succeeded.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Integer' name=""fail_count"">" & ASCII.LF & "   "
       & "         <comment>the number of tests that failed.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Integer' name"
       & "=""timeout_count"">" & ASCII.LF & "            <comment>the number of te"
       & "sts that timeout.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "    </class>" & ASCII.LF & ASCII.LF & "    <query name='project-list'>" & ASCII.LF
       & "        <comment>Get the list of projects</comment>" & ASCII.LF & "     "
       & "   <sql>" & ASCII.LF & "            SELECT" & ASCII.LF & "            pr"
       & "oject.name AS name," & ASCII.LF & "            project.status AS status,"
       & ASCII.LF & "            COALESCE(branch.name, '') AS branch_name," & ASCII.LF
       & "            COALESCE(branch.tag, '') AS branch_tag," & ASCII.LF & "     "
       & "       COALESCE(branch.status, 0) AS branch_status," & ASCII.LF & "     "
       & "       build.finish_date AS build_date," & ASCII.LF & "            COALE"
       & "SCE(build.status, 0) AS build_status," & ASCII.LF & "            COALESC"
       & "E(build.tag, '') AS build_tag," & ASCII.LF & "            COALESCE(build"
       & ".pass_count, 0) AS pass_count," & ASCII.LF & "            COALESCE(build"
       & ".fail_count, 0) AS fail_count," & ASCII.LF & "            COALESCE(build"
       & ".timeout_count, 0) AS timeout_count" & ASCII.LF & "            FROM pori"
       & "on_project AS project" & ASCII.LF & "            LEFT JOIN porion_branch"
       & " AS branch ON project.id = branch.project_id AND branch.status != 0" & ASCII.LF
       & "            LEFT JOIN porion_last_build AS last_build ON last_build.bran"
       & "ch_id = branch.id" & ASCII.LF & "            LEFT JOIN porion_build AS b"
       & "uild ON last_build.build_id = build.id" & ASCII.LF & "        </sql>" & ASCII.LF
       & "        <sql-count>" & ASCII.LF & "            SELECT" & ASCII.LF & "   "
       & "         count(project.id)" & ASCII.LF & "            FROM porion_projec"
       & "t AS project" & ASCII.LF & "        </sql-count>" & ASCII.LF & "    </qu"
       & "ery>" & ASCII.LF & ASCII.LF & "    <query name='project-dependency-list"
       & "'>" & ASCII.LF & "        <comment>Get the list of projects that another"
       & " project depend on</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & " "
       & "           SELECT" & ASCII.LF & "            project.name AS name," & ASCII.LF
       & "            project.status AS status," & ASCII.LF & "            COALESC"
       & "E(branch.name, '') AS branch_name," & ASCII.LF & "            COALESCE(b"
       & "ranch.tag, '') AS branch_tag," & ASCII.LF & "            COALESCE(branch"
       & ".status, 0) AS branch_status," & ASCII.LF & "            build.finish_da"
       & "te AS build_date," & ASCII.LF & "            COALESCE(build.status, 0) A"
       & "S build_status," & ASCII.LF & "            COALESCE(build.tag, '') AS bu"
       & "ild_tag," & ASCII.LF & "            COALESCE(build.pass_count, 0) AS pas"
       & "s_count," & ASCII.LF & "            COALESCE(build.fail_count, 0) AS fai"
       & "l_count," & ASCII.LF & "            COALESCE(build.timeout_count, 0) AS "
       & "timeout_count" & ASCII.LF & "            FROM porion_dependency AS depen"
       & "dency" & ASCII.LF & "            INNER JOIN porion_project AS project ON"
       & " dependency.project_id = project.id" & ASCII.LF & "            LEFT JOIN"
       & " porion_branch AS branch ON project.id = branch.project_id AND branch.st"
       & "atus != 0" & ASCII.LF & "            LEFT JOIN porion_last_build AS last"
       & "_build ON last_build.branch_id = branch.id" & ASCII.LF & "            LE"
       & "FT JOIN porion_build AS build ON last_build.build_id = build.id" & ASCII.LF
       & "            WHERE dependency.owner_id = :project_id" & ASCII.LF & "     "
       & "   </sql>" & ASCII.LF & "        <sql-count>" & ASCII.LF & "            "
       & "SELECT" & ASCII.LF & "            count(project.id)" & ASCII.LF & "     "
       & "       FROM porion_project AS project" & ASCII.LF & "        </sql-count"
       & ">" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapping"
       & ">" & ASCII.LF;

   C_6 : aliased constant String := "<query-mapping package='Porion.Projects.M"
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

   C_7 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Informatio"
       & "n about branches on a project." & ASCII.LF & "    </description>" & ASCII.LF
       & ASCII.LF & "    <query name='project-last-build'>" & ASCII.LF & "       "
       & "<comment>Get a list of project branches.</comment>" & ASCII.LF & "      "
       & " <sql>" & ASCII.LF & "    SELECT" & ASCII.LF & "      MAX(build.number)" & ASCII.LF
       & "    FROM porion_build AS build" & ASCII.LF & "    WHERE build.project_id"
       & " = :project_id AND build.branch_id = :branch_id" & ASCII.LF & "       </"
       & "sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapp"
       & "ing>" & ASCII.LF;

   C_8 : aliased constant String := "<query-mapping package='Porion.Builds.Mod"
       & "els'>" & ASCII.LF & "    <description>" & ASCII.LF & "        Provide pr"
       & "oject build status" & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF
       & "    <class name=""Porion.Builds.Models.Build_Status"" bean=""yes"">" & ASCII.LF
       & "        <comment>Summary of information about last builds of a project.<"
       & "/comment>" & ASCII.LF & "        <property type='ADO.Identifier' name="""
       & "recipe_id"">" & ASCII.LF & "            <comment>the build recipe id.</c"
       & "omment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <prope"
       & "rty type='Porion.Builds.Models.Build_Status_Type' name=""build_status"">"
       & ASCII.LF & "            <comment>the last build status.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='String' name="
       & """build_tag"">" & ASCII.LF & "            <comment>the branch tag.</comm"
       & "ent>" & ASCII.LF & "        </property>" & ASCII.LF & "        <property"
       & " type='Integer' name=""build_number"">" & ASCII.LF & "            <comme"
       & "nt>the build number.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Integer' name=""pass_count"">" & ASCII.LF & "   "
       & "         <comment>the number of tests that succeeded.</comment>" & ASCII.LF
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
       & "     build.status," & ASCII.LF & "          build.tag," & ASCII.LF & "  "
       & "        build.number," & ASCII.LF & "          build.pass_count," & ASCII.LF
       & "          build.fail_count," & ASCII.LF & "          build.timeout_count"
       & "," & ASCII.LF & "          build.finish_date" & ASCII.LF & "          FR"
       & "OM porion_recipe AS recipe" & ASCII.LF & "          INNER JOIN porion_la"
       & "st_build AS last_build ON last_build.recipe_id = recipe.id" & ASCII.LF & " "
       & "         INNER JOIN porion_build AS build ON last_build.build_id = build"
       & ".id" & ASCII.LF & "          WHERE recipe.project_id = 1 AND" & ASCII.LF
       & "             build.id IN (SELECT MAX(sb.build_id) FROM porion_last_build"
       & " AS sb WHERE sb.recipe_id = recipe.id)" & ASCII.LF & "        </sql>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_9 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        Stats for the builds" & ASCII.LF
       & "    </description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Q"
       & "ueries.Build_Stat"" bean=""no"">" & ASCII.LF & "        <comment>Informa"
       & "tion about a build.</comment>" & ASCII.LF & "        <property type='Por"
       & "ion.Builds.Models.Build_Status_Type' name=""build_status"">" & ASCII.LF
       & "            <comment>the build status.</comment>" & ASCII.LF & "        "
       & "</property>" & ASCII.LF & "        <property type='Natural' name=""count"
       & """>" & ASCII.LF & "            <comment>the number of builds.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "    </class>" & ASCII.LF & ASCII.LF
       & "    <query name='stat-project-config-status'>" & ASCII.LF & "        <co"
       & "mment>Project build recipes status for a dashboard</comment>" & ASCII.LF
       & "        <sql>" & ASCII.LF & "          SELECT" & ASCII.LF & "          b"
       & "uild.status," & ASCII.LF & "          count(build.id)" & ASCII.LF & "   "
       & "       FROM porion_recipe AS recipe" & ASCII.LF & "          LEFT JOIN p"
       & "orion_last_build AS build on build.recipe_id = recipe.id" & ASCII.LF & " "
       & "         WHERE build.project_id = :project_id" & ASCII.LF & "          G"
       & "ROUP BY build.status" & ASCII.LF & "        </sql>" & ASCII.LF & "    </"
       & "query> " & ASCII.LF & ASCII.LF & "    <query name='stat-project-build-s"
       & "tatus'>" & ASCII.LF & "        <comment>Project build status for a dashb"
       & "oard</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & "          SEL"
       & "ECT" & ASCII.LF & "          build.status," & ASCII.LF & "          coun"
       & "t(build.id)" & ASCII.LF & "          FROM porion_build AS build" & ASCII.LF
       & "          WHERE build.project_id = :project_id" & ASCII.LF & "          "
       & "GROUP BY build.status" & ASCII.LF & "        </sql>" & ASCII.LF & "    <"
       & "/query> " & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;


   type Content_List_Array is array (Natural range <>) of access constant String;
   Contents : constant Content_List_Array := (
      C_0'Access, C_1'Access, C_2'Access, C_3'Access, C_4'Access, C_5'Access,
      C_6'Access, C_7'Access, C_8'Access, C_9'Access);

   function Get_Content (Name : String) return access constant String is
      H : constant Natural := Hash (Name);
   begin
      return (if Names (H).all = Name then Contents (H) else null);
   end Get_Content;

end Porion.Resources.Queries;
