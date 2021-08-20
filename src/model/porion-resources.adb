--  Advanced Resource Embedder 1.2.0
with Interfaces; use Interfaces;

package body Porion.Resources is
   function Hash (S : String) return Natural;

   P : constant array (0 .. 1) of Natural :=
     (1, 11);

   T1 : constant array (0 .. 1) of Unsigned_8 :=
     (10, 7);

   T2 : constant array (0 .. 1) of Unsigned_8 :=
     (5, 5);

   G : constant array (0 .. 11) of Unsigned_8 :=
     (0, 2, 0, 0, 0, 0, 2, 4, 0, 0, 0, 1);

   function Hash (S : String) return Natural is
      F : constant Natural := S'First - 1;
      L : constant Natural := S'Length;
      F1, F2 : Natural := 0;
      J : Natural;
   begin
      for K in P'Range loop
         exit when L < P (K);
         J  := Character'Pos (S (P (K) + F));
         F1 := (F1 + Natural (T1 (K)) * J) mod 12;
         F2 := (F2 + Natural (T2 (K)) * J) mod 12;
      end loop;
      return (Natural (G (F1)) + Natural (G (F2))) mod 5;
   end Hash;

   C_0 : aliased constant String := "<query-mapping package='Porion.Projects.M"
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

   C_1 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "        List of "
       & "nodes" & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF & "    <"
       & "query name='command-node-list'>" & ASCII.LF & "        <comment>Get the "
       & "list of nodes</comment>" & ASCII.LF & "        <sql>" & ASCII.LF & "    "
       & "        SELECT" & ASCII.LF & "            node.id AS id," & ASCII.LF & " "
       & "           node.name AS name" & ASCII.LF & "            FROM porion_node"
       & " AS node" & ASCII.LF & "        </sql>" & ASCII.LF & "        <sql-count"
       & ">" & ASCII.LF & "            SELECT" & ASCII.LF & "            count(nod"
       & "e.id)" & ASCII.LF & "            FROM porion_node AS node" & ASCII.LF & " "
       & "       </sql-count>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF
       & "</query-mapping>" & ASCII.LF;

   C_2 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "        List of "
       & "projects" & ASCII.LF & "    </description>" & ASCII.LF & ASCII.LF & "  "
       & "  <query name='command-project-list'>" & ASCII.LF & "        <comment>Ge"
       & "t the list of projects</comment>" & ASCII.LF & "        <sql>" & ASCII.LF
       & "            SELECT" & ASCII.LF & "            project.id AS id," & ASCII.LF
       & "            project.name AS name," & ASCII.LF & "            project.sta"
       & "tus AS status," & ASCII.LF & "            COUNT(branch.id) AS branch_cou"
       & "nt," & ASCII.LF & "            (SELECT COUNT(build.id) FROM porion_build"
       & " AS build WHERE build.project_id = project.id) AS build_count " & ASCII.LF
       & "            FROM porion_project AS project" & ASCII.LF & "            LE"
       & "FT JOIN porion_branch AS branch ON project.id = branch.project_id" & ASCII.LF
       & "            GROUP BY project.id" & ASCII.LF & "        </sql>" & ASCII.LF
       & "        <sql-count>" & ASCII.LF & "            SELECT" & ASCII.LF & "   "
       & "         count(project.id)" & ASCII.LF & "            FROM porion_projec"
       & "t AS project" & ASCII.LF & "        </sql-count>" & ASCII.LF & "    </qu"
       & "ery>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_3 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Informatio"
       & "n about branches on a project." & ASCII.LF & "    </description>" & ASCII.LF
       & ASCII.LF & "    <query name='project-branches'>" & ASCII.LF & "       <c"
       & "omment>Get a list of project branches.</comment>" & ASCII.LF & "       <"
       & "sql>" & ASCII.LF & "    SELECT" & ASCII.LF & "      branch.id," & ASCII.LF
       & "      branch.name," & ASCII.LF & "      branch.tag," & ASCII.LF & "     "
       & " branch.last_date," & ASCII.LF & "      build.create_date," & ASCII.LF & " "
       & "     (SELECT COUNT(*) FROM porion_build AS build WHERE build.branch_id ="
       & " branch.id) AS count" & ASCII.LF & "    FROM porion_branch AS branch" & ASCII.LF
       & "    LEFT JOIN porion_build AS build ON branch.last_build_id = build.id" & ASCII.LF
       & "    WHERE branch.project_id = :project_id" & ASCII.LF & "       </sql>" & ASCII.LF
       & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapping>" & ASCII.LF;

   C_4 : aliased constant String := "<query-mapping package='Porion.Projects.M"
       & "odels'>" & ASCII.LF & "    <description>" & ASCII.LF & "      Informatio"
       & "n about branches on a project." & ASCII.LF & "    </description>" & ASCII.LF
       & ASCII.LF & "    <query name='project-last-build'>" & ASCII.LF & "       "
       & "<comment>Get a list of project branches.</comment>" & ASCII.LF & "      "
       & " <sql>" & ASCII.LF & "    SELECT" & ASCII.LF & "      MAX(build.number)" & ASCII.LF
       & "    FROM porion_build AS build" & ASCII.LF & "    WHERE build.project_id"
       & " = :project_id AND build.branch_id = :branch_id" & ASCII.LF & "       </"
       & "sql>" & ASCII.LF & "    </query>" & ASCII.LF & ASCII.LF & "</query-mapp"
       & "ing>" & ASCII.LF;


   type Content_List_Array is array (Natural range <>) of access constant String;
   Contents : constant Content_List_Array := (
      C_0'Access, C_1'Access, C_2'Access, C_3'Access, C_4'Access);

   function Get_Content (Name : String) return access constant String is
      H : constant Natural := Hash (Name);
   begin
      return (if Names (H).all = Name then Contents (H) else null);
   end Get_Content;

end Porion.Resources;
