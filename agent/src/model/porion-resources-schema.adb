--  Advanced Resource Embedder 1.5.0
package body Porion.Resources.Schema is

   L_1   : aliased constant String := "pragma synchronous=OFF";
   L_2   : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_audit_fiel"
       & "d ( `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, `name` VARCHAR(25"
       & "5) NOT NULL, `entity_type` INTEGER NOT NULL)";
   L_3   : aliased constant String := "CREATE TABLE IF NOT EXISTS ado_entity_typ"
       & "e ( `id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` VARCHAR(127) UNIQUE"
       & " )";
   L_4   : aliased constant String := "CREATE TABLE IF NOT EXISTS ado_sequence ("
       & " `name` VARCHAR(127) UNIQUE NOT NULL, `version` INTEGER NOT NULL, `val"
       & "ue` BIGINT NOT NULL, `block_size` BIGINT NOT NULL, PRIMARY KEY (`name`"
       & "))";
   L_5   : aliased constant String := "CREATE TABLE IF NOT EXISTS ado_version ( "
       & "`name` VARCHAR(127) UNIQUE NOT NULL, `version` INTEGER NOT NULL, PRIMA"
       & "RY KEY (`name`))";
   L_6   : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""ado_entity_type"")";
   L_7   : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""ado_sequence"")";
   L_8   : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""ado_version"")";
   L_9   : aliased constant String := "INSERT OR IGNORE INTO ado_version (name, "
       & "version) VALUES (""ado"", 2)";
   L_10  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build ("
       & " `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `number` INTEGER NO"
       & "T NULL, `create_date` DATETIME NOT NULL, `finish_date` DATETIME , `pas"
       & "s_count` INTEGER NOT NULL, `fail_count` INTEGER NOT NULL, `timeout_cou"
       & "nt` INTEGER NOT NULL, `test_duration` INTEGER NOT NULL, `status` TINYI"
       & "NT NOT NULL, `tag` VARCHAR(255) NOT NULL, `build_duration` INTEGER NOT"
       & " NULL, `sys_time` INTEGER NOT NULL, `user_time` INTEGER NOT NULL, `sou"
       & "rce_changes` INTEGER NOT NULL, `branch_id` BIGINT NOT NULL, `recipe_id"
       & "` BIGINT NOT NULL, `node_id` BIGINT NOT NULL, `project_id` BIGINT NOT "
       & "NULL, PRIMARY KEY (`id`))";
   L_11  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_e"
       & "xecutor ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `pid` INTE"
       & "GER NOT NULL, `start_date` DATETIME NOT NULL, `port` INTEGER NOT NULL,"
       & " `node_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_12  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_q"
       & "ueue ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `create_date`"
       & " DATETIME NOT NULL, `update_date` DATETIME NOT NULL, `order` INTEGER N"
       & "OT NULL, `building` TINYINT NOT NULL, `node_id` BIGINT NOT NULL, `reci"
       & "pe_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_13  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_r"
       & "eason ( `id` BIGINT NOT NULL, `create_date` DATETIME NOT NULL, `versio"
       & "n` INTEGER NOT NULL, `reason` TINYINT NOT NULL, `build_id` BIGINT , `q"
       & "ueue_id` BIGINT , `upstream_build_id` BIGINT , PRIMARY KEY (`id`))";
   L_14  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_s"
       & "tep ( `id` BIGINT NOT NULL, `start_date` DATETIME NOT NULL, `end_date`"
       & " DATETIME , `exit_status` INTEGER NOT NULL, `user_time` INTEGER NOT NU"
       & "LL, `sys_time` INTEGER NOT NULL, `step_duration` INTEGER NOT NULL, `bu"
       & "ild_id` BIGINT NOT NULL, `recipe_step_id` BIGINT NOT NULL, PRIMARY KEY"
       & " (`id`))";
   L_15  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_environ"
       & "ment ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHA"
       & "R(255) NOT NULL, `value` VARCHAR(4096) NOT NULL, `kind` TINYINT NOT NU"
       & "LL, `secret` TINYINT NOT NULL, `step_number` INTEGER , `branch_id` BIG"
       & "INT , `node_id` BIGINT , `recipe_id` BIGINT , `project_id` BIGINT , PR"
       & "IMARY KEY (`id`))";
   L_16  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_last_bu"
       & "ild ( `id` BIGINT NOT NULL, `status` TINYINT NOT NULL, `version` INTEG"
       & "ER NOT NULL, `last_build` TINYINT NOT NULL, `build_id` BIGINT NOT NULL"
       & ", `branch_id` BIGINT NOT NULL, `recipe_id` BIGINT NOT NULL, PRIMARY KE"
       & "Y (`id`))";
   L_17  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_recipe "
       & "( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(255"
       & ") NOT NULL, `description` VARCHAR(4096) NOT NULL, `status` INTEGER NOT"
       & " NULL, `rate_factor` INTEGER NOT NULL, `main_recipe` TINYINT NOT NULL,"
       & " `filter_rules` VARCHAR(255) NOT NULL, `node_id` BIGINT , `branch_id` "
       & "BIGINT NOT NULL, `project_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_18  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_recipe_"
       & "step ( `id` BIGINT NOT NULL, `parameters` VARCHAR(65536) NOT NULL, `nu"
       & "mber` INTEGER NOT NULL, `builder` INTEGER NOT NULL, `timeout` INTEGER "
       & "NOT NULL, `step` INTEGER NOT NULL, `version` INTEGER NOT NULL, `execut"
       & "ion` TINYINT NOT NULL, `next_version_id` BIGINT , `recipe_id` BIGINT N"
       & "OT NULL, PRIMARY KEY (`id`))";
   L_19  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_m"
       & "etric ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `value` INTE"
       & "GER NOT NULL, `content` VARCHAR(255) NOT NULL, `build_id` BIGINT NOT N"
       & "ULL, `metric_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_20  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_metric "
       & "( `id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, `label` VARCHAR("
       & "255) NOT NULL, `version` INTEGER NOT NULL, `metric` TINYINT NOT NULL, "
       & "PRIMARY KEY (`id`))";
   L_21  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_node ( "
       & "`id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(255) "
       & "NOT NULL, `login` VARCHAR(255) NOT NULL, `repository_dir` VARCHAR(255)"
       & " NOT NULL, `parameters` VARCHAR(255) NOT NULL, `create_date` DATETIME "
       & "NOT NULL, `update_date` DATETIME , `kind` TINYINT NOT NULL, `deleted` "
       & "TINYINT NOT NULL, `status` TINYINT NOT NULL, `os_name` VARCHAR(255) NO"
       & "T NULL, `os_version` VARCHAR(255) NOT NULL, `info_date` DATETIME , `cp"
       & "u_type` VARCHAR(255) NOT NULL, `main_node` TINYINT NOT NULL, `check_ru"
       & "les` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`))";
   L_22  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_branch "
       & "( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(255"
       & ") NOT NULL, `tag` VARCHAR(255) NOT NULL, `last_date` DATETIME , `creat"
       & "e_date` DATETIME NOT NULL, `update_date` DATETIME NOT NULL, `status` I"
       & "NTEGER NOT NULL, `pass_rate` INTEGER NOT NULL, `fail_rate` INTEGER NOT"
       & " NULL, `timeout_rate` INTEGER NOT NULL, `build_rate` INTEGER NOT NULL,"
       & " `rate_factor` INTEGER NOT NULL, `main_branch` TINYINT NOT NULL, `last"
       & "_build_number` INTEGER NOT NULL, `build_progress` INTEGER NOT NULL, `d"
       & "escription` VARCHAR(255) NOT NULL, `project_id` BIGINT NOT NULL, PRIMA"
       & "RY KEY (`id`))";
   L_23  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_depende"
       & "ncy ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `project_id` B"
       & "IGINT NOT NULL, `owner_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_24  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_project"
       & " ( `id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, `version` INTEG"
       & "ER NOT NULL, `description` VARCHAR(255) NOT NULL, `create_date` DATETI"
       & "ME NOT NULL, `update_date` DATETIME , `status` INTEGER NOT NULL, `scm`"
       & " INTEGER NOT NULL, `scm_url` VARCHAR(255) NOT NULL, `pass_rate` INTEGE"
       & "R NOT NULL, `fail_rate` INTEGER NOT NULL, `timeout_rate` INTEGER NOT N"
       & "ULL, `build_rate` INTEGER NOT NULL, `check_date` DATETIME NOT NULL, `c"
       & "heck_delay` INTEGER NOT NULL, `next_check_date` DATETIME NOT NULL, `bu"
       & "ild_progress` INTEGER NOT NULL, PRIMARY KEY (`id`))";
   L_25  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test ( "
       & "`id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, `create_date` DATE"
       & "TIME NOT NULL, `version` INTEGER NOT NULL, `total_pass_count` INTEGER "
       & "NOT NULL, `total_fail_count` INTEGER NOT NULL, `total_timeout_count` I"
       & "NTEGER NOT NULL, `last_pass_date` DATETIME , `last_fail_date` DATETIME"
       & " , `last_timeout_date` DATETIME , `last_pass_build` INTEGER , `last_fa"
       & "il_build` INTEGER , `last_timeout_build` INTEGER , `total_skip_count` "
       & "INTEGER NOT NULL, `last_skip_date` DATETIME NOT NULL, `last_skip_build"
       & "` INTEGER NOT NULL, `group_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_26  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_gr"
       & "oup ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR"
       & "(255) NOT NULL, `create_date` DATETIME NOT NULL, `project_id` BIGINT N"
       & "OT NULL, `group_id` BIGINT , PRIMARY KEY (`id`))";
   L_27  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_ru"
       & "n ( `duration` INTEGER NOT NULL, `status` INTEGER NOT NULL, `id` BIGIN"
       & "T NOT NULL, `assertions` INTEGER NOT NULL, `test_id` BIGINT NOT NULL, "
       & "`group_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_28  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_ru"
       & "n_group ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `total_pas"
       & "s_count` INTEGER NOT NULL, `total_fail_count` INTEGER NOT NULL, `total"
       & "_timeout_count` INTEGER NOT NULL, `total_skip_count` INTEGER NOT NULL,"
       & " `diff_pass` INTEGER NOT NULL, `diff_fail` INTEGER NOT NULL, `diff_tim"
       & "eout` INTEGER NOT NULL, `diff_skip` INTEGER NOT NULL, `duration` INTEG"
       & "ER NOT NULL, `group_id` BIGINT NOT NULL, `build_id` BIGINT NOT NULL, P"
       & "RIMARY KEY (`id`))";
   L_29  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_build"")";
   L_30  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_build_executor"")";
   L_31  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_build_queue"")";
   L_32  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_build_reason"")";
   L_33  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_build_step"")";
   L_34  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_environment"")";
   L_35  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_last_build"")";
   L_36  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_recipe"")";
   L_37  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_recipe_step"")";
   L_38  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_build_metric"")";
   L_39  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_metric"")";
   L_40  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_node"")";
   L_41  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_branch"")";
   L_42  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_dependency"")";
   L_43  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_project"")";
   L_44  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_test"")";
   L_45  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_test_group"")";
   L_46  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_test_run"")";
   L_47  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""porion_test_run_group"")";
   L_48  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_build""), ""id"")";
   L_49  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_build""), ""status"")";
   L_50  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_environment""), ""value"")";
   L_51  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_environment""), ""kind"")";
   L_52  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_environment""), ""secret"")";
   L_53  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_environment""), ""step_number"")";
   L_54  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_recipe""), ""name"")";
   L_55  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_recipe""), ""description"")";
   L_56  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_recipe""), ""status"")";
   L_57  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_recipe""), ""rate_factor"")";
   L_58  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_recipe""), ""main_recipe"")";
   L_59  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_recipe""), ""filter_rules"")";
   L_60  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_recipe_step""), ""id"")";
   L_61  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_recipe_step""), ""number"")";
   L_62  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_node""), ""name"")";
   L_63  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_node""), ""login"")";
   L_64  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_node""), ""repository_dir"")";
   L_65  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_node""), ""kind"")";
   L_66  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_node""), ""deleted"")";
   L_67  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_node""), ""main_node"")";
   L_68  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_node""), ""check_rules"")";
   L_69  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""tag"")";
   L_70  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""last_date"")";
   L_71  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""status"")";
   L_72  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""pass_rate"")";
   L_73  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""fail_rate"")";
   L_74  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""timeout_rate"")";
   L_75  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""build_rate"")";
   L_76  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""rate_factor"")";
   L_77  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""main_branch"")";
   L_78  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""last_build_number"")";
   L_79  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""build_progress"")";
   L_80  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_branch""), ""description"")";
   L_81  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_project""), ""name"")";
   L_82  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_project""), ""description"")";
   L_83  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_project""), ""status"")";
   L_84  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_project""), ""scm"")";
   L_85  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_project""), ""scm_url"")";
   L_86  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_project""), ""pass_rate"")";
   L_87  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_project""), ""fail_rate"")";
   L_88  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_project""), ""timeout_rate"")";
   L_89  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_project""), ""build_rate"")";
   L_90  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_project""), ""check_delay"")";
   L_91  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM ado_entity_type WHERE name = "
       & """porion_project""), ""build_progress"")";
   L_92  : aliased constant String := "INSERT OR IGNORE INTO ado_version (name, "
       & "version) VALUES (""porion_lib"", 4)";
   L_93  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_audit ( `i"
       & "d` BIGINT NOT NULL, `date` DATETIME NOT NULL, `old_value` VARCHAR(255)"
       & " , `new_value` VARCHAR(255) , `entity_id` BIGINT NOT NULL, `session_id"
       & "` BIGINT , `field` INTEGER NOT NULL, `entity_type` INTEGER NOT NULL, P"
       & "RIMARY KEY (`id`))";
   L_94  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_audit_fiel"
       & "d ( `id` INTEGER NOT NULL, `name` VARCHAR(255) NOT NULL, `entity_type`"
       & " INTEGER NOT NULL, PRIMARY KEY (`id`))";
   L_95  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""awa_audit"")";
   L_96  : aliased constant String := "INSERT OR IGNORE INTO ado_entity_type (na"
       & "me) VALUES (""awa_audit_field"")";
   L_97  : aliased constant String := "INSERT OR IGNORE INTO ado_version (name, "
       & "version) VALUES (""porion_agent"", 1)";
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
      L_52'Access,
      L_53'Access,
      L_54'Access,
      L_55'Access,
      L_56'Access,
      L_57'Access,
      L_58'Access,
      L_59'Access,
      L_60'Access,
      L_61'Access,
      L_62'Access,
      L_63'Access,
      L_64'Access,
      L_65'Access,
      L_66'Access,
      L_67'Access,
      L_68'Access,
      L_69'Access,
      L_70'Access,
      L_71'Access,
      L_72'Access,
      L_73'Access,
      L_74'Access,
      L_75'Access,
      L_76'Access,
      L_77'Access,
      L_78'Access,
      L_79'Access,
      L_80'Access,
      L_81'Access,
      L_82'Access,
      L_83'Access,
      L_84'Access,
      L_85'Access,
      L_86'Access,
      L_87'Access,
      L_88'Access,
      L_89'Access,
      L_90'Access,
      L_91'Access,
      L_92'Access,
      L_93'Access,
      L_94'Access,
      L_95'Access,
      L_96'Access,
      L_97'Access);

   type Content_List_Array is array (Natural range <>) of Content_Access;

   Contents : constant Content_List_Array := (
     0 =>  C_0'Access);

   function Get_Content (Name : String) return Content_Access is
   begin
      return (if Names (Names'First).all = Name then Contents (0) else null);
   end Get_Content;

end Porion.Resources.Schema;
