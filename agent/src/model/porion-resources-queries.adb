-- Advanced Resource Embedder 1.1.0
with Interfaces; use Interfaces;

package body Porion.Resources.Queries is
   function Hash (S : String) return Natural;

   P : constant array (0 .. 1) of Natural :=
     (1, 11);

   T1 : constant array (0 .. 1) of Unsigned_8 :=
     (8, 10);

   T2 : constant array (0 .. 1) of Unsigned_8 :=
     (6, 10);

   G : constant array (0 .. 18) of Unsigned_8 :=
     (0, 0, 0, 0, 0, 0, 0, 1, 6, 0, 0, 0, 1, 5, 1, 0, 6, 4, 2);

   function Hash (S : String) return Natural is
      F : constant Natural := S'First - 1;
      L : constant Natural := S'Length;
      F1, F2 : Natural := 0;
      J : Natural;
   begin
      for K in P'Range loop
         exit when L < P (K);
         J  := Character'Pos (S (P (K) + F));
         F1 := (F1 + Natural (T1 (K)) * J) mod 19;
         F2 := (F2 + Natural (T2 (K)) * J) mod 19;
      end loop;
      return (Natural (G (F1)) + Natural (G (F2))) mod 9;
   end Hash;

   C_0 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Queries to cleanup a "
       & "project" & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF & "    <query nam"
       & "e='cleanup-project-build-step'>" & ASCII.LF & "       <comment>Cleanup the buil"
       & "d steps of a project.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    DELE"
       & "TE FROM porion_build_step WHERE build_id IN" & ASCII.LF & "      (SELECT id FRO"
       & "M porion_build WHERE project_id = :project_id)" & ASCII.LF & "       </sql>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-project-test-r"
       & "un'>" & ASCII.LF & "       <comment>Cleanup the test run of a project.</comment"
       & ">" & ASCII.LF & "       <sql>" & ASCII.LF & "    DELETE FROM porion_test_run WHERE "
       & "group_id IN" & ASCII.LF & "      (SELECT porion_test_run_group.id FROM porion_t"
       & "est_run_group INNER JOIN porion_test_group ON" & ASCII.LF & "           porion_"
       & "test_run_group.group_id = porion_test_group.id" & ASCII.LF & "                W"
       & "HERE porion_test_group.project_id = :project_id)" & ASCII.LF & "       </sql>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-project-test-r"
       & "un-group'>" & ASCII.LF & "       <comment>Cleanup the test run group of a proje"
       & "ct.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    DELETE FROM porion_tes"
       & "t_run_group WHERE group_id IN" & ASCII.LF & "      (SELECT id FROM porion_test_"
       & "group WHERE porion_test_group.project_id = :project_id)" & ASCII.LF & "       <"
       & "/sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "    <query name='clean"
       & "up-project-test'>" & ASCII.LF & "       <comment>Cleanup the test of a project."
       & "</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    DELETE FROM porion_test W"
       & "HERE group_id IN" & ASCII.LF & "      (SELECT id FROM porion_test_group WHERE p"
       & "orion_test_group.project_id = :project_id)" & ASCII.LF & "       </sql>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-project-test-g"
       & "roup'>" & ASCII.LF & "       <comment>Cleanup the test group of a project.</com"
       & "ment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    DELETE FROM porion_test_group "
       & "WHERE porion_test_group.project_id = :project_id" & ASCII.LF & "       </sql>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "    <query name='cleanup-project-last-b"
       & "uild'>" & ASCII.LF & "       <comment>Cleanup the project last build references"
       & " of a project.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    DELETE FROM"
       & " porion_last_build WHERE build_config_id IN" & ASCII.LF & "      (SELECT id FRO"
       & "M porion_build_config WHERE project_id = :project_id)" & ASCII.LF & "       </s"
       & "ql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "    <query name='cleanup"
       & "-project-build'>" & ASCII.LF & "       <comment>Cleanup the project builds.</co"
       & "mment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    DELETE FROM porion_build WHER"
       & "E project_id = :project_id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>"
       & ASCII.LF & ASCII.LF & "    <query name='cleanup-project-environment'>" & ASCII.LF
       & "       <comment>Cleanup the project specific environment.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_environment WHERE build_conf"
       & "ig_id IN" & ASCII.LF & "      (SELECT id FROM porion_build_config WHERE project"
       & "_id = :project_id)" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF
       & ASCII.LF & "    <query name='cleanup-project-build-config-step'>" & ASCII.LF
       & "       <comment>Cleanup the project build config of a project.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_build_config_step WHERE buil"
       & "d_config_id IN" & ASCII.LF & "      (SELECT id FROM porion_build_config WHERE p"
       & "roject_id = :project_id)" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF
       & ASCII.LF & "    <query name='cleanup-project-build-config'>" & ASCII.LF & "    "
       & "   <comment>Cleanup the project build config of a project.</comment>" & ASCII.LF
       & "       <sql>" & ASCII.LF & "    DELETE FROM porion_build_config WHERE project_i"
       & "d = :project_id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF
       & ASCII.LF & "    <query name='cleanup-project-branch'>" & ASCII.LF & "       <co"
       & "mment>Cleanup the project branch of a project.</comment>" & ASCII.LF & "       "
       & "<sql>" & ASCII.LF & "    DELETE FROM porion_branch WHERE project_id = :project_"
       & "id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF
       & "</query-mapping>" & ASCII.LF;

   C_1 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        List of project branches" & ASCII.LF & "  "
       & "  </description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Queries.Br"
       & "anch_Info"" bean=""no"">" & ASCII.LF & "        <comment>Information about a pr"
       & "oject branch.</comment>" & ASCII.LF & "        <property type='String' name=""n"
       & "ame"">" & ASCII.LF & "            <comment>the branch name.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Porion.Projects.Mode"
       & "ls.Branch_Status_Type' name=""branch_status"">" & ASCII.LF & "            <comm"
       & "ent>the branch status.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='String' name=""branch_tag"">" & ASCII.LF & "           "
       & " <comment>the branch tag.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Integer' name=""config_count"">" & ASCII.LF & "        "
       & "    <comment>the number of build config for this branch.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "    </class>" & ASCII.LF & ASCII.LF & "    <que"
       & "ry name='branch-list'>" & ASCII.LF & "        <comment>Get the list of project "
       & "branch</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & "            SELECT" & ASCII.LF
       & "            branch.name AS name," & ASCII.LF & "            branch.status AS st"
       & "atus," & ASCII.LF & "            branch.tag AS tag," & ASCII.LF & "            COUN"
       & "T(build_config.id) AS config_count" & ASCII.LF & "            FROM porion_branc"
       & "h AS branch" & ASCII.LF & "            LEFT JOIN porion_build_config AS build_c"
       & "onfig ON build_config.branch_id = branch.id" & ASCII.LF & "            WHERE br"
       & "anch.project_id = :project_id" & ASCII.LF & "            GROUP BY branch.id" & ASCII.LF
       & "        </sql>" & ASCII.LF & "        <sql-count>" & ASCII.LF & "            SELECT"
       & ASCII.LF & "            count(project.id)" & ASCII.LF & "            FROM porio"
       & "n_project AS project" & ASCII.LF & "        </sql-count>" & ASCII.LF & "    </query"
       & ">" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_2 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        List of builds" & ASCII.LF & "    </descri"
       & "ption>" & ASCII.LF & " " & ASCII.LF & "    <class name=""Porion.Queries.Build_Info"""
       & " bean=""no"">" & ASCII.LF & "        <comment>Information about a build.</comme"
       & "nt>" & ASCII.LF & "        <property type='String' name=""name"">" & ASCII.LF & "  "
       & "          <comment>the project name.</comment>" & ASCII.LF & "        </propert"
       & "y>" & ASCII.LF & "        <property type='Porion.Projects.Models.Project_Status"
       & "_Type' name=""project_status"">" & ASCII.LF & "            <comment>the project"
       & " status.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <prope"
       & "rty type='String' name=""branch_name"">" & ASCII.LF & "            <comment>the"
       & " branch name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <"
       & "property type='Porion.Projects.Models.Branch_Status_Type' name=""branch_sta"
       & "tus"">" & ASCII.LF & "            <comment>the branch status.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='String' name=""confi"
       & "g_name"">" & ASCII.LF & "            <comment>the config name.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Integer' name=""buil"
       & "d_id"">" & ASCII.LF & "            <comment>the build id.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Integer' name=""buil"
       & "d_number"">" & ASCII.LF & "            <comment>the build number.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='String' name=""build"
       & "_tag"">" & ASCII.LF & "            <comment>the build tag.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Porion.Builds.Models"
       & ".Build_Status_Type' name=""build_status"">" & ASCII.LF & "            <comment>"
       & "the last build status.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Date' name=""build_date"" not-null=""no"">" & ASCII.LF
       & "            <comment>the build starting date.</comment>" & ASCII.LF & "        "
       & "</property>" & ASCII.LF & "        <property type='Nullable_Date' name=""finish"
       & "_date"" not-null=""no"">" & ASCII.LF & "            <comment>the build ending d"
       & "ate.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <property "
       & "type='Integer' name=""pass_count"">" & ASCII.LF & "            <comment>the num"
       & "ber of tests that succeeded.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "        <property type='Integer' name=""fail_count"">" & ASCII.LF & "          "
       & "  <comment>the number of tests that failed.</comment>" & ASCII.LF & "        </"
       & "property>" & ASCII.LF & "        <property type='Integer' name=""timeout_count"""
       & ">" & ASCII.LF & "            <comment>the number of tests that timeout.</commen"
       & "t>" & ASCII.LF & "        </property>" & ASCII.LF & "    </class>" & ASCII.LF & ASCII.LF
       & "   <query name='build-list'>" & ASCII.LF & "        <comment>Get the list of bu"
       & "ilds</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & "            SELECT" & ASCII.LF
       & "            project.name AS name," & ASCII.LF & "            project.status AS "
       & "status," & ASCII.LF & "            branch.name AS branch_name," & ASCII.LF & "     "
       & "       branch.status AS branch_status," & ASCII.LF & "            config.name A"
       & "S config_name," & ASCII.LF & "            build.id AS build_id," & ASCII.LF & "    "
       & "        build.number AS number," & ASCII.LF & "            build.tag AS tag," & ASCII.LF
       & "            build.status AS build_status," & ASCII.LF & "            build.crea"
       & "te_date AS build_date," & ASCII.LF & "            build.finish_date AS finish_d"
       & "ate," & ASCII.LF & "            build.pass_count AS pass_count," & ASCII.LF & "    "
       & "        build.fail_count AS fail_count," & ASCII.LF & "            build.timeou"
       & "t_count AS timeout_count" & ASCII.LF & "            FROM porion_build AS build" & ASCII.LF
       & "            INNER JOIN porion_project AS project ON build.project_id = proj"
       & "ect.id" & ASCII.LF & "            INNER JOIN porion_branch AS branch ON branch."
       & "id = build.branch_id" & ASCII.LF & "            INNER JOIN porion_build_config "
       & "AS config ON build.build_config_id = config.id" & ASCII.LF & "            ORDER"
       & " BY finish_date DESC" & ASCII.LF & "        </sql>" & ASCII.LF & "        <sql-coun"
       & "t>" & ASCII.LF & "            SELECT" & ASCII.LF & "            count(build.id)" & ASCII.LF
       & "            FROM porion_build AS build" & ASCII.LF & "        </sql-count>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "   <query name='project-last-build-list"
       & "'>" & ASCII.LF & "        <comment>Get the list of builds</comment>" & ASCII.LF
       & "        <sql>" & ASCII.LF & "            SELECT" & ASCII.LF & "            project."
       & "name AS name," & ASCII.LF & "            project.status AS status," & ASCII.LF & " "
       & "           branch.name AS branch_name," & ASCII.LF & "            branch.status"
       & " AS branch_status," & ASCII.LF & "            config.name AS config_name," & ASCII.LF
       & "            build.id AS build_id," & ASCII.LF & "            build.number AS nu"
       & "mber," & ASCII.LF & "            build.tag AS tag," & ASCII.LF & "            build"
       & ".status AS build_status," & ASCII.LF & "            build.create_date AS build_"
       & "date," & ASCII.LF & "            build.finish_date AS finish_date," & ASCII.LF & " "
       & "           build.pass_count AS pass_count," & ASCII.LF & "            build.fai"
       & "l_count AS fail_count," & ASCII.LF & "            build.timeout_count AS timeou"
       & "t_count" & ASCII.LF & "            FROM porion_last_build AS last_build" & ASCII.LF
       & "            INNER JOIN porion_build AS build ON last_build.build_id = build"
       & ".id" & ASCII.LF & "            INNER JOIN porion_project AS project ON build.pr"
       & "oject_id = project.id" & ASCII.LF & "            INNER JOIN porion_branch AS br"
       & "anch ON branch.id = build.branch_id" & ASCII.LF & "            INNER JOIN porio"
       & "n_build_config AS config ON build.build_config_id = config.id" & ASCII.LF & "  "
       & "          WHERE project.id = :project_id" & ASCII.LF & "            ORDER BY fi"
       & "nish_date DESC" & ASCII.LF & "        </sql>" & ASCII.LF & "    </query>" & ASCII.LF
       & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_3 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "        List of builds" & ASCII.LF
       & "    </description>" & ASCII.LF & ASCII.LF & "    <query name='command-build-li"
       & "st'>" & ASCII.LF & "        <comment>Get the list of builds</comment>" & ASCII.LF
       & "        <sql>" & ASCII.LF & "            SELECT" & ASCII.LF & "            build.id"
       & " AS id," & ASCII.LF & "            build.number AS number," & ASCII.LF & "         "
       & "   project.name AS name," & ASCII.LF & "            build.pass_count AS pass_co"
       & "unt," & ASCII.LF & "            build.fail_count AS fail_count" & ASCII.LF & "     "
       & "       FROM porion_build AS build" & ASCII.LF & "            INNER JOIN porion_"
       & "project AS project ON build.project_id = project.id" & ASCII.LF & "        </sq"
       & "l>" & ASCII.LF & "        <sql-count>" & ASCII.LF & "            SELECT" & ASCII.LF
       & "            count(build.id)" & ASCII.LF & "            FROM porion_build AS bui"
       & "ld" & ASCII.LF & "        </sql-count>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF
       & "</query-mapping>" & ASCII.LF;

   C_4 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "        List of nodes" & ASCII.LF
       & "    </description>" & ASCII.LF & ASCII.LF & "    <query name='command-node-lis"
       & "t'>" & ASCII.LF & "        <comment>Get the list of nodes</comment>" & ASCII.LF
       & "        <sql>" & ASCII.LF & "            SELECT" & ASCII.LF & "            node.id "
       & "AS id," & ASCII.LF & "            node.name AS name" & ASCII.LF & "            FROM"
       & " porion_node AS node" & ASCII.LF & "        </sql>" & ASCII.LF & "        <sql-coun"
       & "t>" & ASCII.LF & "            SELECT" & ASCII.LF & "            count(node.id)" & ASCII.LF
       & "            FROM porion_node AS node" & ASCII.LF & "        </sql-count>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_5 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        List of projects" & ASCII.LF & "    </desc"
       & "ription>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Queries.Project_In"
       & "fo"" bean=""no"">" & ASCII.LF & "        <comment>Information about a project.<"
       & "/comment>" & ASCII.LF & "        <property type='String' name=""name"">" & ASCII.LF
       & "            <comment>the project name.</comment>" & ASCII.LF & "        </prope"
       & "rty>" & ASCII.LF & "        <property type='Porion.Projects.Models.Project_Stat"
       & "us_Type' name=""project_status"">" & ASCII.LF & "            <comment>the proje"
       & "ct status.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <pro"
       & "perty type='String' name=""branch_name"">" & ASCII.LF & "            <comment>t"
       & "he branch name.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "       "
       & " <property type='String' name=""branch_tag"">" & ASCII.LF & "            <comme"
       & "nt>the branch tag.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "    "
       & "    <property type='Porion.Projects.Models.Branch_Status_Type' name=""branc"
       & "h_status"">" & ASCII.LF & "            <comment>the branch status.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Nullable_Date' name="
       & """build_date"" not-null=""no"">" & ASCII.LF & "            <comment>the build d"
       & "ate.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <property "
       & "type='Porion.Builds.Models.Build_Status_Type' name=""build_status"">" & ASCII.LF
       & "            <comment>the last build status.</comment>" & ASCII.LF & "        </"
       & "property>" & ASCII.LF & "        <property type='String' name=""build_tag"">" & ASCII.LF
       & "            <comment>the build tag.</comment>" & ASCII.LF & "        </property"
       & ">" & ASCII.LF & "        <property type='Integer' name=""pass_count"">" & ASCII.LF
       & "            <comment>the number of tests that succeeded.</comment>" & ASCII.LF
       & "        </property>" & ASCII.LF & "        <property type='Integer' name=""fail"
       & "_count"">" & ASCII.LF & "            <comment>the number of tests that failed.<"
       & "/comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <property type="
       & "'Integer' name=""timeout_count"">" & ASCII.LF & "            <comment>the numbe"
       & "r of tests that timeout.</comment>" & ASCII.LF & "        </property>" & ASCII.LF
       & "    </class>" & ASCII.LF & ASCII.LF & "    <query name='project-list'>" & ASCII.LF
       & "        <comment>Get the list of projects</comment>" & ASCII.LF & "        <sql"
       & ">" & ASCII.LF & "            SELECT" & ASCII.LF & "            project.name AS name"
       & "," & ASCII.LF & "            project.status AS status," & ASCII.LF & "            C"
       & "OALESCE(branch.name, '') AS branch_name," & ASCII.LF & "            COALESCE(br"
       & "anch.tag, '') AS branch_tag," & ASCII.LF & "            COALESCE(branch.status,"
       & " 0) AS branch_status," & ASCII.LF & "            build.finish_date AS build_dat"
       & "e," & ASCII.LF & "            COALESCE(build.status, 0) AS build_status," & ASCII.LF
       & "            COALESCE(build.tag, '') AS build_tag," & ASCII.LF & "            CO"
       & "ALESCE(build.pass_count, 0) AS pass_count," & ASCII.LF & "            COALESCE("
       & "build.fail_count, 0) AS fail_count," & ASCII.LF & "            COALESCE(build.t"
       & "imeout_count, 0) AS timeout_count" & ASCII.LF & "            FROM porion_projec"
       & "t AS project" & ASCII.LF & "            LEFT JOIN porion_branch AS branch ON pr"
       & "oject.id = branch.project_id AND branch.status != 0" & ASCII.LF & "            "
       & "LEFT JOIN porion_last_build AS last_build ON last_build.branch_id = branch."
       & "id" & ASCII.LF & "            LEFT JOIN porion_build AS build ON last_build.bui"
       & "ld_id = build.id" & ASCII.LF & "        </sql>" & ASCII.LF & "        <sql-count>" & ASCII.LF
       & "            SELECT" & ASCII.LF & "            count(project.id)" & ASCII.LF & "    "
       & "        FROM porion_project AS project" & ASCII.LF & "        </sql-count>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_6 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Information about bra"
       & "nches on a project." & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF & "  "
       & "  <query name='project-branches'>" & ASCII.LF & "       <comment>Get a list of "
       & "project branches.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    SELECT" & ASCII.LF
       & "      branch.id," & ASCII.LF & "      branch.name," & ASCII.LF & "      branch.tag,"
       & ASCII.LF & "      branch.last_date," & ASCII.LF & "      build.create_date," & ASCII.LF
       & "      (SELECT COUNT(*) FROM porion_build AS build WHERE build.branch_id = b"
       & "ranch.id) AS count" & ASCII.LF & "    FROM porion_branch AS branch" & ASCII.LF & " "
       & "   LEFT JOIN porion_last_build AS last_build ON branch.id = last_build.bran"
       & "ch_id" & ASCII.LF & "    LEFT JOIN porion_build AS build ON last_build.build_id"
       & " = build.id" & ASCII.LF & "    WHERE branch.project_id = :project_id" & ASCII.LF
       & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "</query-mappin"
       & "g>" & ASCII.LF;

   C_7 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Information about bra"
       & "nches on a project." & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF & "  "
       & "  <query name='project-last-build'>" & ASCII.LF & "       <comment>Get a list o"
       & "f project branches.</comment>" & ASCII.LF & "       <sql>" & ASCII.LF & "    SELECT"
       & ASCII.LF & "      MAX(build.number)" & ASCII.LF & "    FROM porion_build AS bui"
       & "ld" & ASCII.LF & "    WHERE build.project_id = :project_id AND build.branch_id "
       & "= :branch_id" & ASCII.LF & "       </sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF
       & "</query-mapping>" & ASCII.LF;

   C_8 : aliased constant String := "<query-mapping package='Porion.Queries'>" & ASCII.LF
       & "    <description>" & ASCII.LF & "        Stats for the builds" & ASCII.LF & "    </"
       & "description>" & ASCII.LF & ASCII.LF & "    <class name=""Porion.Queries.Build_"
       & "Stat"" bean=""no"">" & ASCII.LF & "        <comment>Information about a build.<"
       & "/comment>" & ASCII.LF & "        <property type='Porion.Builds.Models.Build_Sta"
       & "tus_Type' name=""build_status"">" & ASCII.LF & "            <comment>the build "
       & "status.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "        <proper"
       & "ty type='Natural' name=""count"">" & ASCII.LF & "            <comment>the numbe"
       & "r of builds.</comment>" & ASCII.LF & "        </property>" & ASCII.LF & "    </clas"
       & "s>" & ASCII.LF & ASCII.LF & "    <query name='stat-project-config-status'>" & ASCII.LF
       & "        <comment>Project build config status for a dashboard</comment>" & ASCII.LF
       & "        <sql>" & ASCII.LF & "          SELECT" & ASCII.LF & "          build.status"
       & "," & ASCII.LF & "          count(build.id)" & ASCII.LF & "          FROM porion_bui"
       & "ld_config AS config" & ASCII.LF & "          LEFT JOIN porion_last_build AS bui"
       & "ld on build.build_config_id = config.id" & ASCII.LF & "          WHERE build.pr"
       & "oject_id = :project_id" & ASCII.LF & "          GROUP BY build.status" & ASCII.LF
       & "        </sql>" & ASCII.LF & "    </query> " & ASCII.LF & ASCII.LF & "    <query n"
       & "ame='stat-project-build-status'>" & ASCII.LF & "        <comment>Project build "
       & "status for a dashboard</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & "      "
       & "    SELECT" & ASCII.LF & "          build.status," & ASCII.LF & "          count(bu"
       & "ild.id)" & ASCII.LF & "          FROM porion_build AS build" & ASCII.LF & "        "
       & "  WHERE build.project_id = :project_id" & ASCII.LF & "          GROUP BY build."
       & "status" & ASCII.LF & "        </sql>" & ASCII.LF & "    </query> " & ASCII.LF & ASCII.LF
       & "</query-mapping>" & ASCII.LF;


   type Content_List_Array is array (Natural range <>) of access constant String;
   Contents : constant Content_List_Array := (
      C_0'Access, C_1'Access, C_2'Access, C_3'Access, C_4'Access, C_5'Access,
      C_6'Access, C_7'Access, C_8'Access);

   function Get_Content (Name : String) return access constant String is
      H : constant Natural := Hash (Name);
   begin
      return (if Names (H).all = Name then Contents (H) else null);
   end Get_Content;

end Porion.Resources.Queries;
