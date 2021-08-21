/* File generated automatically by dynamo */
/*  */
CREATE TABLE IF NOT EXISTS porion_build (
  /* the build global identifier. */
  `id` BIGINT NOT NULL,
  /* the optimistic lock. */
  `version` INTEGER NOT NULL,
  /* the project build number. */
  `number` INTEGER NOT NULL,
  /* the build creation date. */
  `create_date` DATETIME NOT NULL,
  /* the date when the build was finished. */
  `finish_date` DATETIME ,
  /* the number of tests that passed. */
  `pass_count` INTEGER NOT NULL,
  /* the number of tests that failed. */
  `fail_count` INTEGER NOT NULL,
  /* the number of tests that timeout. */
  `timeout_count` INTEGER NOT NULL,
  /* the test total duration in us. */
  `test_duration` INTEGER NOT NULL,
  /*  */
  `status`  NOT NULL,
  /* the build configuration. */
  `build_config_id` BIGINT NOT NULL,
  /* the node where the build was made. */
  `node_id` BIGINT NOT NULL,
  /* the branch associated with the build. */
  `branch_id` BIGINT NOT NULL,
  /* the project. */
  `project_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* Describes a configuration to build a project.
The build configuration can be associated with a build node and
it is decomposed in several build steps. Each step is managed by
a specific builder which can perform specific operations. */
CREATE TABLE IF NOT EXISTS porion_build_config (
  /* identifier */
  `id` BIGINT NOT NULL,
  /* optimistic locking */
  `version` INTEGER NOT NULL,
  /* the build configuration name. */
  `name` VARCHAR(255) BINARY NOT NULL,
  /* a description of the build configuration. */
  `description` VARCHAR(4096) BINARY NOT NULL,
  /*  */
  `node_id` BIGINT ,
  /*  */
  `project_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS porion_build_step (
  /* build step identifier */
  `id` BIGINT NOT NULL,
  /* the optimistic locking. */
  `version` INTEGER NOT NULL,
  /* the build step command. */
  `parameters` VARCHAR(65536) BINARY NOT NULL,
  /* the build step number. */
  `number` INTEGER NOT NULL,
  /* the builder controller that handles execution of this build step. */
  `builder` INTEGER NOT NULL,
  /* the maximum execution time in seconds. */
  `timeout` INTEGER NOT NULL,
  /* the step classification type. */
  `step` INTEGER NOT NULL,
  /* the build configuration that contains this build step. */
  `build_config_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* Specific environment variables
can be defined for the build
configuration or for a specific
build node. */
CREATE TABLE IF NOT EXISTS porion_environment (
  /* the environment identifier. */
  `id` BIGINT NOT NULL,
  /* the optimistic lock version. */
  `version` INTEGER NOT NULL,
  /* the environment variable name. */
  `name` VARCHAR(255) BINARY NOT NULL,
  /* the environment variable value. */
  `value` VARCHAR(4096) BINARY NOT NULL,
  /*  */
  `node_id` BIGINT ,
  /*  */
  `build_config_id` BIGINT ,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS porion_node (
  /* the node identifier */
  `id` BIGINT NOT NULL,
  /* optimistic lock version */
  `version` INTEGER NOT NULL,
  /* the node name. */
  `name` VARCHAR(255) BINARY NOT NULL,
  /* the login name. */
  `login` VARCHAR(255) BINARY NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS porion_branch (
  /* the identifier. */
  `id` BIGINT NOT NULL,
  /* the optimistic lock version. */
  `version` INTEGER NOT NULL,
  /* the branch name. */
  `name` VARCHAR(255) BINARY NOT NULL,
  /* the last identification tag. */
  `tag` VARCHAR(255) BINARY NOT NULL,
  /* the date of the last detected change. */
  `last_date` DATETIME ,
  /* the date when the branch was created. */
  `create_date` DATETIME NOT NULL,
  /* the date when the branch was updated. */
  `update_date` DATETIME NOT NULL,
  /* the branch status. */
  `status` INTEGER NOT NULL,
  /*  */
  `project_id` BIGINT NOT NULL,
  /* the last build. */
  `last_build_id` BIGINT ,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS porion_dependency (
  /* dependency identifier. */
  `id` BIGINT NOT NULL,
  /* optimistic locking. */
  `version` INTEGER NOT NULL,
  /*  */
  `project_id` BIGINT NOT NULL,
  /*  */
  `owner_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS porion_project (
  /* the project identifier */
  `id` BIGINT NOT NULL,
  /* the project name */
  `name` VARCHAR(255) BINARY NOT NULL,
  /* optimistic lock version */
  `version` INTEGER NOT NULL,
  /* the project description. */
  `description` VARCHAR(255) BINARY NOT NULL,
  /* date when the project was created. */
  `create_date` DATETIME NOT NULL,
  /* date when the project was modified. */
  `update_date` DATETIME NOT NULL,
  /* the project status. */
  `status` INTEGER NOT NULL,
  /*  */
  `scm` INTEGER NOT NULL,
  /* source control information parameter */
  `scm_url` VARCHAR(255) BINARY NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS porion_test (
  /* the test identifier */
  `id` BIGINT NOT NULL,
  /* the test name. */
  `name` VARCHAR(255) BINARY NOT NULL,
  /*  */
  `create_date` DATETIME NOT NULL,
  /* the optimistic lock version */
  `version` INTEGER NOT NULL,
  /* the number of pass for this test case. */
  `total_pass_count` INTEGER NOT NULL,
  /* the total number of times the test failed. */
  `total_fail_count` INTEGER NOT NULL,
  /* the total number of time the test resulted in a timeout. */
  `total_timeout_count` INTEGER NOT NULL,
  /* the last date when the test passed. */
  `last_pass_date` DATETIME ,
  /* the last date when the test failed. */
  `last_fail_date` DATETIME ,
  /* the last date when the test failed with a timeout. */
  `last_timeout_date` DATETIME ,
  /* the last build that succeeded. */
  `last_pass_build` INTEGER ,
  /* the last build that failed. */
  `last_fail_build` INTEGER ,
  /* the last build that resulted in a timeout. */
  `last_timeout_build` INTEGER ,
  /*  */
  `total_skip_count` INTEGER NOT NULL,
  /*  */
  `last_skip_date` DATETIME NOT NULL,
  /*  */
  `last_skip_build` INTEGER NOT NULL,
  /*  */
  `group_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS porion_test_group (
  /* the group identifier. */
  `id` BIGINT NOT NULL,
  /* optimistic lock version */
  `version` INTEGER NOT NULL,
  /* the group name. */
  `name` VARCHAR(255) BINARY NOT NULL,
  /* the date when this group was created. */
  `create_date` DATETIME NOT NULL,
  /*  */
  `project_id` BIGINT NOT NULL,
  /*  */
  `group_id` BIGINT ,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* Describes the result of execution of the test case. */
CREATE TABLE IF NOT EXISTS porion_test_run (
  /* the test execution time in us. */
  `duration` INTEGER NOT NULL,
  /* the test execution status. */
  `status` INTEGER NOT NULL,
  /*  */
  `id` BIGINT NOT NULL,
  /* the number of assertions that have been checked */
  `assertions` INTEGER NOT NULL,
  /* the test case information */
  `test_id` BIGINT NOT NULL,
  /*  */
  `group_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS porion_test_run_group (
  /* group identifier */
  `id` BIGINT NOT NULL,
  /* optimistic locking */
  `version` INTEGER NOT NULL,
  /*  */
  `total_pass_count` INTEGER NOT NULL,
  /*  */
  `total_fail_count` INTEGER NOT NULL,
  /*  */
  `total_timeout_count` INTEGER NOT NULL,
  /*  */
  `total_skip_count` INTEGER NOT NULL,
  /*  */
  `diff_pass` INTEGER NOT NULL,
  /*  */
  `diff_fail` INTEGER NOT NULL,
  /*  */
  `diff_timeout` INTEGER NOT NULL,
  /*  */
  `diff_skip` INTEGER NOT NULL,
  /* total duration for the execution of the test group */
  `duration` INTEGER NOT NULL,
  /*  */
  `build_id` BIGINT NOT NULL,
  /*  */
  `group_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT IGNORE INTO entity_type (name) VALUES
("porion_build"), ("porion_build_config"), ("porion_build_step"), ("porion_environment"), ("porion_node"), ("porion_branch"), ("porion_dependency"), ("porion_project"), ("porion_test"), ("porion_test_group"), ("porion_test_run"), ("porion_test_run_group");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_build_config"), "name");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_build_config"), "description");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_build_step"), "parameters");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_build_step"), "number");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_build_step"), "timeout");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_environment"), "value");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_node"), "name");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_node"), "login");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_branch"), "tag");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_branch"), "last_date");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_project"), "name");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_project"), "description");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_project"), "status");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_project"), "scm");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_project"), "scm_url");
