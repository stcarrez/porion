-- Advanced Resource Embedder 1.1.0
with Interfaces; use Interfaces;

package body Porion.Resources.Schema is
   function Hash (S : String) return Natural;

   P : constant array (0 .. 0) of Natural :=
     (0 .. 0 => 1);

   T1 : constant array (0 .. 0) of Unsigned_8 :=
     (0 .. 0 => 3);

   T2 : constant array (0 .. 0) of Unsigned_8 :=
     (0 .. 0 => 1);

   G : constant array (0 .. 3) of Unsigned_8 :=
     (0, 0, 0, 0);

   function Hash (S : String) return Natural is
      F : constant Natural := S'First - 1;
      L : constant Natural := S'Length;
      F1, F2 : Natural := 0;
      J : Natural;
   begin
      for K in P'Range loop
         exit when L < P (K);
         J  := Character'Pos (S (P (K) + F));
         F1 := (F1 + Natural (T1 (K)) * J) mod 4;
         F2 := (F2 + Natural (T2 (K)) * J) mod 4;
      end loop;
      return (Natural (G (F1)) + Natural (G (F2))) mod 1;
   end Hash;

   L_0   : aliased constant String := "pragma synchronous=OFF";
   L_1   : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_audit_fiel"
       & "d ( `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, `name` VARCHAR(255) NO"
       & "T NULL, `entity_type` INTEGER NOT NULL)";
   L_2   : aliased constant String := "CREATE TABLE IF NOT EXISTS entity_type ( "
       & "`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` VARCHAR(127) UNIQUE )";
   L_3   : aliased constant String := "CREATE TABLE IF NOT EXISTS sequence ( `na"
       & "me` VARCHAR(127) UNIQUE NOT NULL, `version` INTEGER NOT NULL, `value` BIGIN"
       & "T NOT NULL, `block_size` BIGINT NOT NULL, PRIMARY KEY (`name`))";
   L_4   : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""entity_type"")";
   L_5   : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""sequence"")";
   L_6   : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build ("
       & " `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `number` INTEGER NOT NUL"
       & "L, `create_date` DATETIME NOT NULL, `finish_date` DATETIME , `pass_count` I"
       & "NTEGER NOT NULL, `fail_count` INTEGER NOT NULL, `timeout_count` INTEGER NOT"
       & " NULL, `test_duration` INTEGER NOT NULL, `status` NOT NULL, `build_config_i"
       & "d` BIGINT NOT NULL, `node_id` BIGINT NOT NULL, `branch_id` BIGINT NOT NULL,"
       & " `project_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_7   : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_c"
       & "onfig ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(25"
       & "5) NOT NULL, `description` VARCHAR(4096) NOT NULL, `node_id` BIGINT , `proj"
       & "ect_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_8   : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_c"
       & "onfig_step ( `id` BIGINT NOT NULL, `parameters` VARCHAR(65536) NOT NULL, `n"
       & "umber` INTEGER NOT NULL, `builder` INTEGER NOT NULL, `timeout` INTEGER NOT "
       & "NULL, `step` INTEGER NOT NULL, `version` INTEGER NOT NULL, `execution` NOT "
       & "NULL, `build_config_id` BIGINT NOT NULL, `previous_version_id` BIGINT , PRI"
       & "MARY KEY (`id`))";
   L_9   : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_e"
       & "xecutor ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `pid` INTEGER N"
       & "OT NULL, `start_date` DATETIME NOT NULL, `port` INTEGER NOT NULL, `node_id`"
       & " BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_10  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_s"
       & "tep ( `id` BIGINT NOT NULL, `start_date` DATETIME NOT NULL, `end_date` DATE"
       & "TIME , `exit_status` INTEGER NOT NULL, `build_id` BIGINT NOT NULL, `config_"
       & "id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_11  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_environ"
       & "ment ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(255"
       & ") NOT NULL, `value` VARCHAR(4096) NOT NULL, `node_id` BIGINT , `build_confi"
       & "g_id` BIGINT , PRIMARY KEY (`id`))";
   L_12  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_last_bu"
       & "ild ( `id` BIGINT NOT NULL, `status` NOT NULL, `version` INTEGER NOT NULL, "
       & "`build_id` BIGINT NOT NULL, `branch_id` BIGINT NOT NULL, `build_config_id` "
       & "BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_13  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_node ( "
       & "`id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(255) NOT N"
       & "ULL, `login` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`))";
   L_14  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_branch "
       & "( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(255) NOT"
       & " NULL, `tag` VARCHAR(255) NOT NULL, `last_date` DATETIME , `create_date` DA"
       & "TETIME NOT NULL, `update_date` DATETIME NOT NULL, `status` INTEGER NOT NULL"
       & ", `project_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_15  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_depende"
       & "ncy ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `project_id` BIGINT"
       & " NOT NULL, `owner_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_16  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_project"
       & " ( `id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, `version` INTEGER NO"
       & "T NULL, `description` VARCHAR(255) NOT NULL, `create_date` DATETIME NOT NUL"
       & "L, `update_date` DATETIME , `status` INTEGER NOT NULL, `scm` INTEGER NOT NU"
       & "LL, `scm_url` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`))";
   L_17  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test ( "
       & "`id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, `create_date` DATETIME "
       & "NOT NULL, `version` INTEGER NOT NULL, `total_pass_count` INTEGER NOT NULL, "
       & "`total_fail_count` INTEGER NOT NULL, `total_timeout_count` INTEGER NOT NULL"
       & ", `last_pass_date` DATETIME , `last_fail_date` DATETIME , `last_timeout_dat"
       & "e` DATETIME , `last_pass_build` INTEGER , `last_fail_build` INTEGER , `last"
       & "_timeout_build` INTEGER , `total_skip_count` INTEGER NOT NULL, `last_skip_d"
       & "ate` DATETIME NOT NULL, `last_skip_build` INTEGER NOT NULL, `group_id` BIGI"
       & "NT NOT NULL, PRIMARY KEY (`id`))";
   L_18  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_gr"
       & "oup ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(255)"
       & " NOT NULL, `create_date` DATETIME NOT NULL, `project_id` BIGINT NOT NULL, `"
       & "group_id` BIGINT , PRIMARY KEY (`id`))";
   L_19  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_ru"
       & "n ( `duration` INTEGER NOT NULL, `status` INTEGER NOT NULL, `id` BIGINT NOT"
       & " NULL, `assertions` INTEGER NOT NULL, `test_id` BIGINT NOT NULL, `group_id`"
       & " BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_20  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_ru"
       & "n_group ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `total_pass_cou"
       & "nt` INTEGER NOT NULL, `total_fail_count` INTEGER NOT NULL, `total_timeout_c"
       & "ount` INTEGER NOT NULL, `total_skip_count` INTEGER NOT NULL, `diff_pass` IN"
       & "TEGER NOT NULL, `diff_fail` INTEGER NOT NULL, `diff_timeout` INTEGER NOT NU"
       & "LL, `diff_skip` INTEGER NOT NULL, `duration` INTEGER NOT NULL, `build_id` B"
       & "IGINT NOT NULL, `group_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_21  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build"")";
   L_22  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build_config"")";
   L_23  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build_config_step"")";
   L_24  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build_executor"")";
   L_25  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build_step"")";
   L_26  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_environment"")";
   L_27  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_last_build"")";
   L_28  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_node"")";
   L_29  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_branch"")";
   L_30  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_dependency"")";
   L_31  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_project"")";
   L_32  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test"")";
   L_33  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test_group"")";
   L_34  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test_run"")";
   L_35  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test_run_group"")";
   L_36  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "build_config""), ""name"")";
   L_37  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "build_config""), ""description"")";
   L_38  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "environment""), ""value"")";
   L_39  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "node""), ""name"")";
   L_40  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "node""), ""login"")";
   L_41  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "branch""), ""tag"")";
   L_42  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "branch""), ""last_date"")";
   L_43  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "project""), ""name"")";
   L_44  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "project""), ""description"")";
   L_45  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "project""), ""status"")";
   L_46  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "project""), ""scm"")";
   L_47  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""porion_"
       & "project""), ""scm_url"")";
   C_0 : aliased constant Content_Array :=
     (L_0'Access,
      L_1'Access,
      L_2'Access,
      L_3'Access,
      L_4'Access,
      L_5'Access,
      L_6'Access,
      L_7'Access,
      L_8'Access,
      L_9'Access,
      L_10'Access,
      L_11'Access,
      L_12'Access,
      L_13'Access,
      L_14'Access,
      L_15'Access,
      L_16'Access,
      L_17'Access,
      L_18'Access,
      L_19'Access,
      L_20'Access,
      L_21'Access,
      L_22'Access,
      L_23'Access,
      L_24'Access,
      L_25'Access,
      L_26'Access,
      L_27'Access,
      L_28'Access,
      L_29'Access,
      L_30'Access,
      L_31'Access,
      L_32'Access,
      L_33'Access,
      L_34'Access,
      L_35'Access,
      L_36'Access,
      L_37'Access,
      L_38'Access,
      L_39'Access,
      L_40'Access,
      L_41'Access,
      L_42'Access,
      L_43'Access,
      L_44'Access,
      L_45'Access,
      L_46'Access,
      L_47'Access);


   type Content_List_Array is array (Natural range <>) of Content_Access;
   Contents : constant Content_List_Array := (
     0 =>  C_0'Access);

   function Get_Content (Name : String) return Content_Access is
      H : constant Natural := Hash (Name);
   begin
      return (if Names (H).all = Name then Contents (H) else null);
   end Get_Content;

end Porion.Resources.Schema;
