--  Advanced Resource Embedder 1.2.0
package body Porion.Projects.Schema is
   L_1   : aliased constant String := "pragma synchronous=OFF";
   L_2   : aliased constant String := "CREATE TABLE IF NOT EXISTS entity_type ( "
       & "`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` VARCHAR(127) UNIQUE )";
   L_3   : aliased constant String := "CREATE TABLE IF NOT EXISTS sequence ( `na"
       & "me` VARCHAR(127) UNIQUE NOT NULL, `version` INTEGER NOT NULL, `value` BI"
       & "GINT NOT NULL, `block_size` BIGINT NOT NULL, PRIMARY KEY (`name`))";
   L_4   : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""entity_type"")";
   L_5   : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""sequence"")";
   L_6   : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_audit ( `i"
       & "d` BIGINT NOT NULL, `date` DATETIME NOT NULL, `old_value` VARCHAR(255) ,"
       & " `new_value` VARCHAR(255) , `entity_id` BIGINT NOT NULL, `field` INTEGER"
       & " NOT NULL, `session_id` BIGINT , `entity_type` INTEGER NOT NULL, PRIMARY"
       & " KEY (`id`))";
   L_7   : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_audit_fiel"
       & "d ( `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, `name` VARCHAR(255)"
       & " NOT NULL, `entity_type` INTEGER NOT NULL)";
   L_8   : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_message ( "
       & "`id` BIGINT NOT NULL, `create_date` DATETIME NOT NULL, `priority` INTEGE"
       & "R NOT NULL, `count` INTEGER NOT NULL, `parameters` VARCHAR(255) NOT NULL"
       & ", `server_id` INTEGER NOT NULL, `task_id` INTEGER NOT NULL, `status` TIN"
       & "YINT NOT NULL, `processing_date` DATETIME , `version` INTEGER NOT NULL, "
       & "`entity_id` BIGINT NOT NULL, `entity_type` INTEGER NOT NULL, `finish_dat"
       & "e` DATETIME , `queue_id` BIGINT NOT NULL, `message_type_id` BIGINT NOT N"
       & "ULL, `user_id` BIGINT , `session_id` BIGINT , PRIMARY KEY (`id`))";
   L_9   : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_message_ty"
       & "pe ( `id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, PRIMARY KEY (`i"
       & "d`))";
   L_10  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_queue ( `i"
       & "d` BIGINT NOT NULL, `server_id` INTEGER NOT NULL, `name` VARCHAR(255) NO"
       & "T NULL, PRIMARY KEY (`id`))";
   L_11  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_applicatio"
       & "n ( `id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, `secret_key` VAR"
       & "CHAR(255) NOT NULL, `client_id` VARCHAR(255) NOT NULL, `version` INTEGER"
       & " NOT NULL, `create_date` DATETIME NOT NULL, `update_date` DATETIME NOT N"
       & "ULL, `title` VARCHAR(255) NOT NULL, `description` VARCHAR(255) NOT NULL,"
       & " `app_login_url` VARCHAR(255) NOT NULL, `app_logo_url` VARCHAR(255) NOT "
       & "NULL, `user_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_12  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_callback ("
       & " `id` BIGINT NOT NULL, `url` VARCHAR(255) NOT NULL, `version` INTEGER NO"
       & "T NULL, `application_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_13  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_oauth_sess"
       & "ion ( `id` BIGINT NOT NULL, `create_date` DATETIME NOT NULL, /* a random"
       & " salt string to access/request token generation. */ `salt` VARCHAR(255) "
       & "NOT NULL, `expire_date` DATETIME NOT NULL, `application_id` BIGINT NOT N"
       & "ULL, `user_id` BIGINT NOT NULL, `session_id` BIGINT NOT NULL, PRIMARY KE"
       & "Y (`id`))";
   L_14  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_acl ( `id`"
       & " BIGINT NOT NULL, `entity_id` BIGINT NOT NULL, `writeable` TINYINT NOT N"
       & "ULL, `user_id` BIGINT NOT NULL, `workspace_id` BIGINT NOT NULL, `entity_"
       & "type` INTEGER NOT NULL, `permission` BIGINT NOT NULL, PRIMARY KEY (`id`)"
       & ")";
   L_15  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_permission"
       & " ( `id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`"
       & "))";
   L_16  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_access_key"
       & " ( `access_key` VARCHAR(255) NOT NULL, `expire_date` DATE NOT NULL, `id`"
       & " BIGINT NOT NULL, `version` INTEGER NOT NULL, `kind` TINYINT NOT NULL, `"
       & "user_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_17  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_email ( `e"
       & "mail` VARCHAR(255) NOT NULL, `status` TINYINT NOT NULL, `last_error_date"
       & "` DATETIME NOT NULL, `version` INTEGER NOT NULL, `id` BIGINT NOT NULL, `"
       & "user_id` BIGINT , PRIMARY KEY (`id`))";
   L_18  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_session ( "
       & "`start_date` DATETIME NOT NULL, `end_date` DATETIME , `ip_address` VARCH"
       & "AR(255) NOT NULL, `stype` TINYINT NOT NULL, `version` INTEGER NOT NULL, "
       & "`server_id` INTEGER NOT NULL, `id` BIGINT NOT NULL, `auth_id` BIGINT , `"
       & "user_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_19  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_user ( `fi"
       & "rst_name` VARCHAR(255) NOT NULL, `last_name` VARCHAR(255) NOT NULL, `pas"
       & "sword` VARCHAR(255) NOT NULL, `open_id` VARCHAR(255) NOT NULL, `country`"
       & " VARCHAR(255) NOT NULL, `name` VARCHAR(255) NOT NULL, `version` INTEGER "
       & "NOT NULL, `id` BIGINT NOT NULL, `salt` VARCHAR(255) NOT NULL, `email_id`"
       & " BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_20  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_audit"")";
   L_21  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_audit_field"")";
   L_22  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_message"")";
   L_23  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_message_type"")";
   L_24  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_queue"")";
   L_25  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_application"")";
   L_26  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_callback"")";
   L_27  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_oauth_session"")";
   L_28  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_acl"")";
   L_29  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_permission"")";
   L_30  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_access_key"")";
   L_31  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_email"")";
   L_32  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_session"")";
   L_33  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_user"")";
   L_34  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""awa_"
       & "user""), ""first_name"")";
   L_35  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""awa_"
       & "user""), ""last_name"")";
   L_36  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""awa_"
       & "user""), ""country"")";
   L_37  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""awa_"
       & "user""), ""name"")";
   L_38  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_counter ( "
       & "`object_id` BIGINT NOT NULL, `date` DATE NOT NULL, `counter` INTEGER NOT"
       & " NULL, `definition_id` BIGINT NOT NULL, PRIMARY KEY (`object_id`, `date`"
       & ", `definition_id`))";
   L_39  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_counter_de"
       & "finition ( `name` VARCHAR(255) NOT NULL, `id` INTEGER NOT NULL, `entity_"
       & "type` INTEGER , PRIMARY KEY (`id`))";
   L_40  : aliased constant String := "CREATE TABLE IF NOT EXISTS awa_visit ( `o"
       & "bject_id` BIGINT NOT NULL, `counter` INTEGER NOT NULL, `date` DATETIME N"
       & "OT NULL, `user` BIGINT NOT NULL, `definition_id` BIGINT NOT NULL, PRIMAR"
       & "Y KEY (`object_id`, `user`, `definition_id`))";
   L_41  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_counter"")";
   L_42  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_counter_definition"")";
   L_43  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""awa_visit"")";
   L_44  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build ("
       & " `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `number` INTEGER NOT "
       & "NULL, `create_date` DATETIME NOT NULL, `finish_date` DATETIME , `pass_co"
       & "unt` INTEGER NOT NULL, `fail_count` INTEGER NOT NULL, `timeout_count` IN"
       & "TEGER NOT NULL, `test_duration` INTEGER NOT NULL, `status` NOT NULL, `bu"
       & "ild_config_id` BIGINT NOT NULL, `node_id` BIGINT NOT NULL, `branch_id` B"
       & "IGINT NOT NULL, `project_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_45  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_c"
       & "onfig ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR"
       & "(255) NOT NULL, `description` VARCHAR(4096) NOT NULL, `node_id` BIGINT ,"
       & " `project_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_46  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_build_s"
       & "tep ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `parameters` VAR"
       & "CHAR(65536) NOT NULL, `number` INTEGER NOT NULL, `builder` INTEGER NOT N"
       & "ULL, `timeout` INTEGER NOT NULL, `step` INTEGER NOT NULL, `build_config_"
       & "id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_47  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_environ"
       & "ment ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR("
       & "255) NOT NULL, `value` VARCHAR(4096) NOT NULL, `node_id` BIGINT , `build"
       & "_config_id` BIGINT , PRIMARY KEY (`id`))";
   L_48  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_last_bu"
       & "ild ( `id` BIGINT NOT NULL, `status` NOT NULL, `version` INTEGER NOT NUL"
       & "L, `build_id` BIGINT NOT NULL, `branch_id` BIGINT NOT NULL, `build_confi"
       & "g_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_49  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_node ( "
       & "`id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(255) NO"
       & "T NULL, `login` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`))";
   L_50  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_branch "
       & "( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(255) "
       & "NOT NULL, `tag` VARCHAR(255) NOT NULL, `last_date` DATETIME , `create_da"
       & "te` DATETIME NOT NULL, `update_date` DATETIME NOT NULL, `status` INTEGER"
       & " NOT NULL, `project_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_51  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_depende"
       & "ncy ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `project_id` BIG"
       & "INT NOT NULL, `owner_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_52  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_project"
       & " ( `id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, `version` INTEGER"
       & " NOT NULL, `description` VARCHAR(255) NOT NULL, `create_date` DATETIME N"
       & "OT NULL, `update_date` DATETIME , `status` INTEGER NOT NULL, `scm` INTEG"
       & "ER NOT NULL, `scm_url` VARCHAR(255) NOT NULL, PRIMARY KEY (`id`))";
   L_53  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test ( "
       & "`id` BIGINT NOT NULL, `name` VARCHAR(255) NOT NULL, `create_date` DATETI"
       & "ME NOT NULL, `version` INTEGER NOT NULL, `total_pass_count` INTEGER NOT "
       & "NULL, `total_fail_count` INTEGER NOT NULL, `total_timeout_count` INTEGER"
       & " NOT NULL, `last_pass_date` DATETIME , `last_fail_date` DATETIME , `last"
       & "_timeout_date` DATETIME , `last_pass_build` INTEGER , `last_fail_build` "
       & "INTEGER , `last_timeout_build` INTEGER , `total_skip_count` INTEGER NOT "
       & "NULL, `last_skip_date` DATETIME NOT NULL, `last_skip_build` INTEGER NOT "
       & "NULL, `group_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_54  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_gr"
       & "oup ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `name` VARCHAR(2"
       & "55) NOT NULL, `create_date` DATETIME NOT NULL, `project_id` BIGINT NOT N"
       & "ULL, `group_id` BIGINT , PRIMARY KEY (`id`))";
   L_55  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_ru"
       & "n ( `duration` INTEGER NOT NULL, `status` INTEGER NOT NULL, `id` BIGINT "
       & "NOT NULL, `assertions` INTEGER NOT NULL, `test_id` BIGINT NOT NULL, `gro"
       & "up_id` BIGINT NOT NULL, PRIMARY KEY (`id`))";
   L_56  : aliased constant String := "CREATE TABLE IF NOT EXISTS porion_test_ru"
       & "n_group ( `id` BIGINT NOT NULL, `version` INTEGER NOT NULL, `total_pass_"
       & "count` INTEGER NOT NULL, `total_fail_count` INTEGER NOT NULL, `total_tim"
       & "eout_count` INTEGER NOT NULL, `total_skip_count` INTEGER NOT NULL, `diff"
       & "_pass` INTEGER NOT NULL, `diff_fail` INTEGER NOT NULL, `diff_timeout` IN"
       & "TEGER NOT NULL, `diff_skip` INTEGER NOT NULL, `duration` INTEGER NOT NUL"
       & "L, `build_id` BIGINT NOT NULL, `group_id` BIGINT NOT NULL, PRIMARY KEY ("
       & "`id`))";
   L_57  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build"")";
   L_58  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build_config"")";
   L_59  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_build_step"")";
   L_60  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_environment"")";
   L_61  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_last_build"")";
   L_62  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_node"")";
   L_63  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_branch"")";
   L_64  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_dependency"")";
   L_65  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_project"")";
   L_66  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test"")";
   L_67  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test_group"")";
   L_68  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test_run"")";
   L_69  : aliased constant String := "INSERT OR IGNORE INTO entity_type (name) "
       & "VALUES (""porion_test_run_group"")";
   L_70  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_build_config""), ""name"")";
   L_71  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_build_config""), ""description"")";
   L_72  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_build_step""), ""parameters"")";
   L_73  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_build_step""), ""number"")";
   L_74  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_build_step""), ""timeout"")";
   L_75  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_environment""), ""value"")";
   L_76  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_node""), ""name"")";
   L_77  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_node""), ""login"")";
   L_78  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_branch""), ""tag"")";
   L_79  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_branch""), ""last_date"")";
   L_80  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_project""), ""name"")";
   L_81  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_project""), ""description"")";
   L_82  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_project""), ""status"")";
   L_83  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
       & "tity_type, name) VALUES ((SELECT id FROM entity_type WHERE name = ""pori"
       & "on_project""), ""scm"")";
   L_84  : aliased constant String := "INSERT OR IGNORE INTO awa_audit_field (en"
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
      L_84'Access);


   type Content_List_Array is array (Natural range <>) of Content_Access;
   Contents : constant Content_List_Array := (
     0 =>  C_0'Access);

   function Get_Content (Name : String) return Content_Access is
   begin
      return (if Names (0).all = Name then Contents (0) else null);
   end Get_Content;

end Porion.Projects.Schema;
