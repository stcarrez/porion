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
  /* the source tag that was used when building the project. */
  `tag` VARCHAR(255) NOT NULL,
  /* the branch associated with the build. */
  `branch_id` BIGINT NOT NULL,
  /* the build configuration. */
  `build_config_id` BIGINT NOT NULL,
  /* the node where the build was made. */
  `node_id` BIGINT NOT NULL,
  /* the project. */
  `project_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
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
  `name` VARCHAR(255) NOT NULL,
  /* a description of the build configuration. */
  `description` VARCHAR(4096) NOT NULL,
  /* the build configuration status. */
  `status` INTEGER NOT NULL,
  /* a rate factor to apply on the build for this build configuration. */
  `rate_factor` INTEGER NOT NULL,
  /*  */
  `node_id` BIGINT ,
  /*  */
  `branch_id` BIGINT NOT NULL,
  /*  */
  `project_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/* Describes a step in the build process.
Members are fozen to force the creation
of a new instance when the build configuration
is modified. */
CREATE TABLE IF NOT EXISTS porion_build_config_step (
  /* build step identifier */
  `id` BIGINT NOT NULL,
  /* the build step command. */
  `parameters` VARCHAR(65536) NOT NULL,
  /* the build step number. */
  `number` INTEGER NOT NULL,
  /* the builder controller that handles execution of this build step. */
  `builder` INTEGER NOT NULL,
  /* the maximum execution time in seconds. */
  `timeout` INTEGER NOT NULL,
  /* the step classification type. */
  `step` INTEGER NOT NULL,
  /*  */
  `version` INTEGER NOT NULL,
  /*  */
  `execution`  NOT NULL,
  /*  */
  `previous_version_id` BIGINT ,
  /* the build configuration that contains this build step. */
  `build_config_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/* Tracks a porion agent that is building something. */
CREATE TABLE IF NOT EXISTS porion_build_executor (
  /* the build executor identifier. */
  `id` BIGINT NOT NULL,
  /* the optimistic lock version. */
  `version` INTEGER NOT NULL,
  /* the process id that is running this build executor. */
  `pid` INTEGER NOT NULL,
  /* the date and time when this executor was started. */
  `start_date` DATETIME NOT NULL,
  /* the build executor management port. */
  `port` INTEGER NOT NULL,
  /* the node where the executor is running its commands. */
  `node_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS porion_build_queue (
  /* the build queue identifier. */
  `id` BIGINT NOT NULL,
  /* the optimistic lock version. */
  `version` INTEGER NOT NULL,
  /* the creation date. */
  `creation_date` DATETIME NOT NULL,
  /* the last update date. */
  `update_date` DATETIME NOT NULL,
  /* the builder order. */
  `order` INTEGER NOT NULL,
  /* the node for which the build was queued. */
  `node_id` BIGINT NOT NULL,
  /*  */
  `build_config_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS porion_build_step (
  /* the build step identifier. */
  `id` BIGINT NOT NULL,
  /* the date and time when the build step was started. */
  `start_date` DATETIME NOT NULL,
  /* the date and time when the build step was finished. */
  `end_date` DATETIME ,
  /* the command exit status. */
  `exit_status` INTEGER NOT NULL,
  /* the build that used this build step */
  `build_id` BIGINT NOT NULL,
  /* the build step configuration that was used. */
  `config_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
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
  `name` VARCHAR(255) NOT NULL,
  /* the environment variable value. */
  `value` VARCHAR(4096) NOT NULL,
  /*  */
  `node_id` BIGINT ,
  /*  */
  `build_config_id` BIGINT ,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS porion_last_build (
  /* the record identifier. */
  `id` BIGINT NOT NULL,
  /* the build status. */
  `status`  NOT NULL,
  /* the optimistic lock version. */
  `version` INTEGER NOT NULL,
  /*  */
  `build_id` BIGINT NOT NULL,
  /*  */
  `branch_id` BIGINT NOT NULL,
  /*  */
  `build_config_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS porion_node (
  /* the node identifier */
  `id` BIGINT NOT NULL,
  /* optimistic lock version */
  `version` INTEGER NOT NULL,
  /* the node name. */
  `name` VARCHAR(255) NOT NULL,
  /* the login name. */
  `login` VARCHAR(255) NOT NULL,
  /* the repository directory. */
  `repository_dir` VARCHAR(255) NOT NULL,
  /* node launcher specific parameters. */
  `parameters` VARCHAR(255) NOT NULL,
  /* date when the node was created. */
  `create_date` DATETIME NOT NULL,
  /* date when the node was updated. */
  `update_date` DATETIME ,
  /* the type of node */
  `kind`  NOT NULL,
  /* whether the build node was deleted. */
  `deleted` TINYINT NOT NULL,
  /* the node status. */
  `status`  NOT NULL,
  /* the OS name. */
  `os_name` VARCHAR(255) NOT NULL,
  /* the OS version or additional information. */
  `os_version` VARCHAR(255) NOT NULL,
  /* the date when the node system information was collected. */
  `info_date` DATETIME ,
  /* the CPU type on this build node. */
  `cpu_type` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS porion_branch (
  /* the identifier. */
  `id` BIGINT NOT NULL,
  /* the optimistic lock version. */
  `version` INTEGER NOT NULL,
  /* the branch name. */
  `name` VARCHAR(255) NOT NULL,
  /* the last identification tag. */
  `tag` VARCHAR(255) NOT NULL,
  /* the date of the last detected change. */
  `last_date` DATETIME ,
  /* the date when the branch was created. */
  `create_date` DATETIME NOT NULL,
  /* the date when the branch was updated. */
  `update_date` DATETIME NOT NULL,
  /* the branch status. */
  `status` INTEGER NOT NULL,
  /* the test success rate for the last builds with build configuration of this branch */
  `pass_rate` INTEGER NOT NULL,
  /* the test failure rate for the last builds with build configuration of this branch */
  `fail_rate` INTEGER NOT NULL,
  /* the test timeout rate for the last builds with build configuration of this branch */
  `timeout_rate` INTEGER NOT NULL,
  /* the build success rate for the build configuration of this branch. */
  `build_rate` INTEGER NOT NULL,
  /* a rate factor to apply when consolidating results on the project */
  `rate_factor` INTEGER NOT NULL,
  /*  */
  `project_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
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
);
/*  */
CREATE TABLE IF NOT EXISTS porion_project (
  /* the project identifier */
  `id` BIGINT NOT NULL,
  /* the project name */
  `name` VARCHAR(255) NOT NULL,
  /* optimistic lock version */
  `version` INTEGER NOT NULL,
  /* the project description. */
  `description` VARCHAR(255) NOT NULL,
  /* date when the project was created. */
  `create_date` DATETIME NOT NULL,
  /* date when the project was modified. */
  `update_date` DATETIME ,
  /* the project status. */
  `status` INTEGER NOT NULL,
  /*  */
  `scm` INTEGER NOT NULL,
  /* source control information parameter */
  `scm_url` VARCHAR(255) NOT NULL,
  /* the test success rate for the last builds with build configuration of this project (all branches) */
  `pass_rate` INTEGER NOT NULL,
  /* the test failure rate for the last builds with build configuration of this project (all branches) */
  `fail_rate` INTEGER NOT NULL,
  /* the test timeout rate for the last builds with build configuration of this project (all branches) */
  `timeout_rate` INTEGER NOT NULL,
  /* the build success rate for the build configuration of this project (all branches). */
  `build_rate` INTEGER NOT NULL,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS porion_test (
  /* the test identifier */
  `id` BIGINT NOT NULL,
  /* the test name. */
  `name` VARCHAR(255) NOT NULL,
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
);
/*  */
CREATE TABLE IF NOT EXISTS porion_test_group (
  /* the group identifier. */
  `id` BIGINT NOT NULL,
  /* optimistic lock version */
  `version` INTEGER NOT NULL,
  /* the group name. */
  `name` VARCHAR(255) NOT NULL,
  /* the date when this group was created. */
  `create_date` DATETIME NOT NULL,
  /*  */
  `project_id` BIGINT NOT NULL,
  /*  */
  `group_id` BIGINT ,
  PRIMARY KEY (`id`)
);
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
);
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
  `group_id` BIGINT NOT NULL,
  /*  */
  `build_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build_config");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build_config_step");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build_executor");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build_queue");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build_step");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_environment");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_last_build");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_node");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_branch");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_dependency");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_project");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_test");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_test_group");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_test_run");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_test_run_group");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_build_config"), "name");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_build_config"), "description");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_build_config"), "status");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_build_config"), "rate_factor");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_environment"), "value");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_node"), "name");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_node"), "login");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_node"), "repository_dir");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_node"), "kind");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_node"), "deleted");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_branch"), "tag");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_branch"), "last_date");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_project"), "name");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_project"), "description");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_project"), "status");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_project"), "scm");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_project"), "scm_url");
