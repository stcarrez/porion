pragma synchronous=OFF;
/* Copied from ado-sqlite.sql*/
/* File generated automatically by dynamo */
/* Entity table that enumerates all known database tables */
CREATE TABLE IF NOT EXISTS entity_type (
  /* the database table unique entity index */
  `id` INTEGER  PRIMARY KEY AUTOINCREMENT,
  /* the database entity name */
  `name` VARCHAR(127) UNIQUE );
/* Sequence generator */
CREATE TABLE IF NOT EXISTS sequence (
  /* the sequence name */
  `name` VARCHAR(127) UNIQUE NOT NULL,
  /* the sequence record version */
  `version` INTEGER NOT NULL,
  /* the sequence value */
  `value` BIGINT NOT NULL,
  /* the sequence block size */
  `block_size` BIGINT NOT NULL,
  PRIMARY KEY (`name`)
);
INSERT OR IGNORE INTO entity_type (name) VALUES ("entity_type");
INSERT OR IGNORE INTO entity_type (name) VALUES ("sequence");
/* Copied from awa-sqlite.sql*/
/* File generated automatically by dynamo */
/* The Audit table records the changes made on database on behalf of a user.
The record indicates the database table and row, the field being updated,
the old and new value. The old and new values are converted to a string
and they truncated if necessary to 256 characters. */
CREATE TABLE IF NOT EXISTS awa_audit (
  /* the audit identifier */
  `id` BIGINT NOT NULL,
  /* the date when the field was modified. */
  `date` DATETIME NOT NULL,
  /* the old field value. */
  `old_value` VARCHAR(255) ,
  /* the new field value. */
  `new_value` VARCHAR(255) ,
  /* the database entity identifier to which the audit is associated. */
  `entity_id` BIGINT NOT NULL,
  /*  */
  `field` INTEGER NOT NULL,
  /* the user session under which the field was modified. */
  `session_id` BIGINT ,
  /* the entity type. */
  `entity_type` INTEGER NOT NULL,
  PRIMARY KEY (`id`)
);
/* The Audit_Field table describes
the database field being updated. */
CREATE TABLE IF NOT EXISTS awa_audit_field (
  /* the audit field identifier. */
  `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  /* the audit field name. */
  `name` VARCHAR(255) NOT NULL,
  /* the entity type */
  `entity_type` INTEGER NOT NULL);
/*  */
CREATE TABLE IF NOT EXISTS awa_message (
  /* the message identifier */
  `id` BIGINT NOT NULL,
  /* the message creation date */
  `create_date` DATETIME NOT NULL,
  /* the message priority */
  `priority` INTEGER NOT NULL,
  /* the message count */
  `count` INTEGER NOT NULL,
  /* the message parameters */
  `parameters` VARCHAR(255) NOT NULL,
  /* the server identifier which processes the message */
  `server_id` INTEGER NOT NULL,
  /* the task identfier on the server which processes the message */
  `task_id` INTEGER NOT NULL,
  /* the message status */
  `status` TINYINT NOT NULL,
  /* the message processing date */
  `processing_date` DATETIME ,
  /*  */
  `version` INTEGER NOT NULL,
  /* the entity identifier to which this event is associated. */
  `entity_id` BIGINT NOT NULL,
  /* the entity type of the entity identifier to which this event is associated. */
  `entity_type` INTEGER NOT NULL,
  /* the date and time when the event was finished to be processed. */
  `finish_date` DATETIME ,
  /*  */
  `queue_id` BIGINT NOT NULL,
  /* the message type */
  `message_type_id` BIGINT NOT NULL,
  /* the optional user who triggered the event message creation */
  `user_id` BIGINT ,
  /* the optional user session that triggered the message creation */
  `session_id` BIGINT ,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS awa_message_type (
  /*  */
  `id` BIGINT NOT NULL,
  /* the message type name */
  `name` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
);
/* The message queue tracks the event messages that must be dispatched by
a given server. */
CREATE TABLE IF NOT EXISTS awa_queue (
  /*  */
  `id` BIGINT NOT NULL,
  /*  */
  `server_id` INTEGER NOT NULL,
  /* the message queue name */
  `name` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
);
/* The application that is granted access to the database. */
CREATE TABLE IF NOT EXISTS awa_application (
  /* the application identifier. */
  `id` BIGINT NOT NULL,
  /* the application name. */
  `name` VARCHAR(255) NOT NULL,
  /* the application secret key. */
  `secret_key` VARCHAR(255) NOT NULL,
  /* the application public identifier. */
  `client_id` VARCHAR(255) NOT NULL,
  /* the optimistic lock version. */
  `version` INTEGER NOT NULL,
  /* the application create date. */
  `create_date` DATETIME NOT NULL,
  /* the application update date. */
  `update_date` DATETIME NOT NULL,
  /* the application title displayed in the OAuth login form. */
  `title` VARCHAR(255) NOT NULL,
  /* the application description. */
  `description` VARCHAR(255) NOT NULL,
  /* the optional login URL. */
  `app_login_url` VARCHAR(255) NOT NULL,
  /* the application logo URL. */
  `app_logo_url` VARCHAR(255) NOT NULL,
  /*  */
  `user_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS awa_callback (
  /*  */
  `id` BIGINT NOT NULL,
  /*  */
  `url` VARCHAR(255) NOT NULL,
  /* the optimistic lock version. */
  `version` INTEGER NOT NULL,
  /*  */
  `application_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/* The session is created when the user has granted an access to an application
or when the application has refreshed its access token. */
CREATE TABLE IF NOT EXISTS awa_oauth_session (
  /* the session identifier. */
  `id` BIGINT NOT NULL,
  /* the session creation date. */
  `create_date` DATETIME NOT NULL,
  /* a random salt string to access/request token generation. */
  `salt` VARCHAR(255) NOT NULL,
  /* the expiration date. */
  `expire_date` DATETIME NOT NULL,
  /* the application that is granted access. */
  `application_id` BIGINT NOT NULL,
  /*  */
  `user_id` BIGINT NOT NULL,
  /*  */
  `session_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/* The ACL table records permissions which are granted for a user to access a given database entity. */
CREATE TABLE IF NOT EXISTS awa_acl (
  /* the ACL identifier */
  `id` BIGINT NOT NULL,
  /* the entity identifier to which the ACL applies */
  `entity_id` BIGINT NOT NULL,
  /* the writeable flag */
  `writeable` TINYINT NOT NULL,
  /*  */
  `user_id` BIGINT NOT NULL,
  /*  */
  `workspace_id` BIGINT NOT NULL,
  /* the entity type concerned by the ACL. */
  `entity_type` INTEGER NOT NULL,
  /* the permission that is granted. */
  `permission` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/* The permission table lists all the application permissions that are defined.
This is a system table shared by every user and workspace.
The list of permission is fixed and never changes. */
CREATE TABLE IF NOT EXISTS awa_permission (
  /* the permission database identifier. */
  `id` BIGINT NOT NULL,
  /* the permission name */
  `name` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS awa_access_key (
  /* the secure access key. */
  `access_key` VARCHAR(255) NOT NULL,
  /* the access key expiration date. */
  `expire_date` DATE NOT NULL,
  /* the access key identifier. */
  `id` BIGINT NOT NULL,
  /*  */
  `version` INTEGER NOT NULL,
  /* the access key type. */
  `kind` TINYINT NOT NULL,
  /*  */
  `user_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/* The Email entity defines the user email addresses.
The user has a primary email address that is obtained
from the registration process (either through a form
submission or through OpenID authentication). */
CREATE TABLE IF NOT EXISTS awa_email (
  /* the email address. */
  `email` VARCHAR(255) NOT NULL,
  /* the last mail delivery status (if known). */
  `status` TINYINT NOT NULL,
  /* the date when the last email error was detected. */
  `last_error_date` DATETIME NOT NULL,
  /*  */
  `version` INTEGER NOT NULL,
  /* the email primary key. */
  `id` BIGINT NOT NULL,
  /* the user. */
  `user_id` BIGINT ,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS awa_session (
  /*  */
  `start_date` DATETIME NOT NULL,
  /*  */
  `end_date` DATETIME ,
  /*  */
  `ip_address` VARCHAR(255) NOT NULL,
  /*  */
  `stype` TINYINT NOT NULL,
  /*  */
  `version` INTEGER NOT NULL,
  /*  */
  `server_id` INTEGER NOT NULL,
  /*  */
  `id` BIGINT NOT NULL,
  /*  */
  `auth_id` BIGINT ,
  /*  */
  `user_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/* The User entity represents a user that can access and use the application. */
CREATE TABLE IF NOT EXISTS awa_user (
  /* the user first name. */
  `first_name` VARCHAR(255) NOT NULL,
  /* the user last name. */
  `last_name` VARCHAR(255) NOT NULL,
  /* the user password hash. */
  `password` VARCHAR(255) NOT NULL,
  /* the user OpenID identifier. */
  `open_id` VARCHAR(255) NOT NULL,
  /* the user country. */
  `country` VARCHAR(255) NOT NULL,
  /* the user display name. */
  `name` VARCHAR(255) NOT NULL,
  /* version number. */
  `version` INTEGER NOT NULL,
  /* the user identifier. */
  `id` BIGINT NOT NULL,
  /* the password salt. */
  `salt` VARCHAR(255) NOT NULL,
  /*  */
  `email_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_audit");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_audit_field");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_message");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_message_type");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_queue");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_application");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_callback");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_oauth_session");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_acl");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_permission");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_access_key");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_email");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_session");
INSERT OR IGNORE INTO entity_type (name) VALUES ("awa_user");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "awa_user"), "first_name");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "awa_user"), "last_name");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "awa_user"), "country");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "awa_user"), "name");
/* Copied from porion_lib-sqlite.sql*/
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
  /* the build duration in seconds. */
  `build_duration` INTEGER NOT NULL,
  /* the system time of cumulated processes in milliseconds. */
  `sys_time` INTEGER NOT NULL,
  /* the user time of cumulated processes in milliseconds. */
  `user_time` INTEGER NOT NULL,
  /* the branch associated with the build. */
  `branch_id` BIGINT NOT NULL,
  /* the recipe used for the build. */
  `recipe_id` BIGINT NOT NULL,
  /* the node where the build was made. */
  `node_id` BIGINT NOT NULL,
  /* the project. */
  `project_id` BIGINT NOT NULL,
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
  `create_date` DATETIME NOT NULL,
  /* the last update date. */
  `update_date` DATETIME NOT NULL,
  /* the builder order. */
  `order` INTEGER NOT NULL,
  /* indicates whether a build is running. */
  `building` TINYINT NOT NULL,
  /* the node for which the build was queued. */
  `node_id` BIGINT NOT NULL,
  /* the recipe that must be built. */
  `recipe_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS porion_build_reason (
  /* the build reason identifier. */
  `id` BIGINT NOT NULL,
  /* the creation date of this build reason. */
  `create_date` DATETIME NOT NULL,
  /* the optimistic lock version. */
  `version` INTEGER NOT NULL,
  /* the reason for triggering the build. */
  `reason`  NOT NULL,
  /*  */
  `build_id` BIGINT ,
  /*  */
  `queue_id` BIGINT ,
  /*  */
  `upstream_build_id` BIGINT ,
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
  `recipe_step_id` BIGINT NOT NULL,
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
  `recipe_id` BIGINT ,
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
  `recipe_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/* Describes a recipe to build a project.
The build recipe can be associated with a build node and
it is decomposed in several build steps. Each step is managed by
a specific builder which can perform specific operations. */
CREATE TABLE IF NOT EXISTS porion_recipe (
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
  /* the main recipe. */
  `main_recipe` TINYINT NOT NULL,
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
CREATE TABLE IF NOT EXISTS porion_recipe_step (
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
  /* the build configuration that contains this build step.
the recipe that this step belongs to */
  `recipe_id` BIGINT NOT NULL,
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
  /*  */
  `main_node` TINYINT NOT NULL,
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
  /* indicates whether this is considered as the main project branch. */
  `main_branch` TINYINT NOT NULL,
  /* the last build number that was used. */
  `last_build_number` INTEGER NOT NULL,
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
  /* the date and time when the sources were checked. */
  `check_date` DATETIME NOT NULL,
  /* the prefered delay between two source checks. */
  `check_delay` INTEGER NOT NULL,
  /* the next expected check date and time. */
  `next_check_date` DATETIME NOT NULL,
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
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build_executor");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build_queue");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build_reason");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build_step");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_environment");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_last_build");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_recipe");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_recipe_step");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_node");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_branch");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_dependency");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_project");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_test");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_test_group");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_test_run");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_test_run_group");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_environment"), "value");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_recipe"), "name");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_recipe"), "description");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_recipe"), "status");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_recipe"), "rate_factor");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_recipe"), "main_recipe");
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
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_node"), "main_node");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_branch"), "tag");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_branch"), "last_date");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_branch"), "main_branch");
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
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_project"), "check_delay");
/* Copied from porion-sqlite.sql*/
/* File generated automatically by dynamo */
