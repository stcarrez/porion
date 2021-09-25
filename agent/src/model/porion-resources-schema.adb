--  Advanced Resource Embedder 1.2.0
package body Porion.Resources.Schema is
   L_1   : aliased constant String := "pragma synchronous=OFF";
   L_2   : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_audit_fiel"
       & "d ( `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, `name` VARCHAR(255)"
       & " NOT NULL, `entity_type` INTEGER NOT NULL)";
   L_3   : aliased constant String := "CREATE TABLE IF NOT EXISTS entity_type ( "
       & "`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` VARCHAR(127) UNIQUE )";
   L_4   : aliased constant String := "CREATE TABLE IF NOT EXISTS sequence ( `na"
       & "me` VARCHAR(127) UNIQUE NOT NULL, `version` INTEGER NOT NULL, `value` BI"
       & "GINT NOT NULL, `block_size` BIGINT NOT NULL, PRIMARY KEY (`name`))";
   L_5   : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""entity_type"")";
   L_6   : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""sequence"")";
   L_7   : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build ("
       & " `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `number` INTEGER NOT "
       & "NULL, `create_date` DATETIME NOT NULL, `finish_date` DATETIME , `pass_co"
       & "unt` INTEGER NOT NULL, `fail_count` INTEGER NOT NULL, `timeout_count` IN"
       & "TEGER NOT NULL, `test_duration` INTEGER NOT NULL, `status` NOT NULL, `ta"
       & "g` VARCHAR(255) NOT NULL, `build_config_id` BIGINT NOT NULL, `node_id` B"
       & "IGINT NOT NULL, `branch_id` BIGINT NOT NULL, `project_id` BIGINT NOT NUL"
       & "L, PRIMARY KEY (`id`))";
   L_8   : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_c"
       & "onfig ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR"
       & "(255) NOT NULL, `description` VARCHAR(4096) NOT NULL, `status` INTEGER N"
       & "OT NULL, `node_id` BIGINT , `project_id` BIGINT NOT NULL, `branch_id` BI"
       & "GINT NOT NULL, PRIMARY KEY (`id`))";
   L_9   : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_c"
       & "onfig_step ( `id` BIGINT NOT NULL, `parameters` VARCHAR(65536) NOT NULL,"
       & " `number` INTEGER NOT NULL, `builder` INTEGER NOT NULL, `timeout` INTEGE"
       & "R NOT NULL, `step` INTEGER NOT NULL, `version` INTEGER NOT NULL, `execut"
       & "ion` NOT NULL, `build_config_id` BIGINT NOT NULL, `previous_version_id` "
       & "BIGINT , PRIMARY KEY (`id`))";
   L_10  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_e"
       & "xecutor ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `pid` INTEGE"
       & "R NOT NULL, `start_date` DATETIME NOT NULL, `port` INTEGER NOT NULL, `no"
       & "de_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_11  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_q"
       & "ueue ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `creation_date`"
       & " DATETIME NOT NULL, `update_date` DATETIME NOT NULL, `order` INTEGER NOT"
       & " NULL, `build_config_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_12  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_s"
       & "tep ( `id` BIGINT NOT NULL, `start_date` DATETIME NOT NULL, `end_date` D"
       & "ATETIME , `exit_status` INTEGER NOT NULL, `build_id` BIGINT NOT NULL, `c"
       & "onfig_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_13  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_environ"
       & "ment ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR("
       & "255) NOT NULL, `value` VARCHAR(4096) NOT NULL, `node_id` BIGINT , `build"
       & "_config_id` BIGINT , PRIMARY KEY (`id`))";
   L_14  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_last_bu"
       & "ild ( `id` BIGINT NOT NULL, `status` NOT NULL, `version` INTEGER NOT NUL"
       & "L, `build_id` BIGINT NOT NULL, `branch_id` BIGINT NOT NULL, `build_confi"
       & "g_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_15  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_node ( "
       & "`id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(255) NO"
       & "T NULL, `login` VARCHAR(255) NOT NULL, `repository_dir` VARCHAR(255) NOT"
       & " NULL, PRIMARY KEY (`id`))";
   L_16  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_branch "
       & "( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(255) "
       & "NOT NULL, `tag` VARCHAR(255) NOT NULL, `last_date` DATETIME , `create_da"
       & "te` DATETIME NOT NULL, `update_date` DATETIME NOT NULL, `status` INTEGER"
       & " NOT NULL, `project_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_17  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_depende"
       & "ncy ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `project_id` BIG"
       & "INT NOT NULL, `owner_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_18  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_project"
       & " ( `id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, `version` INTEGER"
       & " NOT NULL, `description` VARCHAR(255) NOT NULL, `create_date` DATETIME N"
       & "OT NULL, `update_date` DATETIME , `status` INTEGER NOT NULL, `scm` INTEG"
       & "ER NOT NULL, `scm_url` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`))";
   L_19  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test ( "
       & "`id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, `create_date` DATETI"
       & "ME NOT NULL, `version` INTEGER NOT NULL, `total_pass_count` INTEGER NOT "
       & "NULL, `total_fail_count` INTEGER NOT NULL, `total_timeout_count` INTEGER"
       & " NOT NULL, `last_pass_date` DATETIME , `last_fail_date` DATETIME , `last"
       & "_timeout_date` DATETIME , `last_pass_build` INTEGER , `last_fail_build` "
       & "INTEGER , `last_timeout_build` INTEGER , `total_skip_count` INTEGER NOT "
       & "NULL, `last_skip_date` DATETIME NOT NULL, `last_skip_build` INTEGER NOT "
       & "NULL, `group_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_20  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_gr"
       & "oup ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(2"
       & "55) NOT NULL, `create_date` DATETIME NOT NULL, `project_id` BIGINT NOT N"
       & "ULL, `group_id` BIGINT , PRIMARY KEY (`id`))";
   L_21  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_ru"
       & "n ( `duration` INTEGER NOT NULL, `status` INTEGER NOT NULL, `id` BIGINT "
       & "NOT NULL, `assertions` INTEGER NOT NULL, `test_id` BIGINT NOT NULL, `gro"
       & "up_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_22  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_ru"
       & "n_group ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `total_pass_"
       & "count` INTEGER NOT NULL, `total_fail_count` INTEGER NOT NULL, `total_tim"
       & "eout_count` INTEGER NOT NULL, `total_skip_count` INTEGER NOT NULL, `diff"
       & "_pass` INTEGER NOT NULL, `diff_fail` INTEGER NOT NULL, `diff_timeout` IN"
       & "TEGER NOT NULL, `diff_skip` INTEGER NOT NULL, `duration` INTEGER NOT NUL"
       & "L, `build_id` BIGINT NOT NULL, `group_id` BIGINT NOT NULL, PRIMARY KEY ("
       & "`id`))";
   L_23  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build"")";
   L_24  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build_config"")";
   L_25  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build_config_step"")";
   L_26  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build_executor"")";
   L_27  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build_queue"")";
   L_28  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build_step"")";
   L_29  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_environment"")";
   L_30  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_last_build"")";
   L_31  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_node"")";
   L_32  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_branch"")";
   L_33  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_dependency"")";
   L_34  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_project"")";
   L_35  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test"")";
   L_36  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test_group"")";
   L_37  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test_run"")";
   L_38  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test_run_group"")";
   L_39  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_build_config""), ""name"")";
   L_40  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_build_config""), ""description"")";
   L_41  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_build_config""), ""status"")";
   L_42  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_environment""), ""value"")";
   L_43  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_node""), ""name"")";
   L_44  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_node""), ""login"")";
   L_45  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_node""), ""repository_dir"")";
   L_46  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_branch""), ""tag"")";
   L_47  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_branch""), ""last_date"")";
   L_48  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_project""), ""name"")";
   L_49  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_project""), ""description"")";
   L_50  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_project""), ""status"")";
   L_51  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_project""), ""scm"")";
   L_52  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_project""), ""scm_url"")";
   C_0 : aliased constant Content_Array :=
     (L_1'Access,
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
      L_47'Access,
      L_48'Access,
      L_49'Access,
      L_50'Access,
      L_51'Access,
      L_52'Access);


   type Content_List_Array is array (Natural range <>) of Content_Access;
   Contents : constant Content_List_Array := (
     0 =>  C_0'Access);

   function Get_Content (Name : String) return Content_Access is
   begin
      return (if Names (0).all = Name then Contents (0) else null);
   end Get_Content;

end Porion.Resources.Schema;
