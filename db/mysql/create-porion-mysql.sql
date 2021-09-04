/* Copied from ado-mysql.sql*/
/* File generated automatically by dynamo */
/* Entity table that enumerates all known database tables */
CREATE TABLE IF NOT EXISTS entity_type (
  /* the database table unique entity index */
  `id` INTEGER  AUTO_INCREMENT,
  /* the database entity name */
  `name` VARCHAR(127) BINARY UNIQUE ,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT IGNORE INTO entity_type (name) VALUES
("entity_type"), ("sequence");
/* Copied from awa-mysql.sql*/
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
  `old_value` VARCHAR(255) BINARY ,
  /* the new field value. */
  `new_value` VARCHAR(255) BINARY ,
  /* the database entity identifier to which the audit is associated. */
  `entity_id` BIGINT NOT NULL,
  /*  */
  `field` INTEGER NOT NULL,
  /* the user session under which the field was modified. */
  `session_id` BIGINT ,
  /* the entity type. */
  `entity_type` INTEGER NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* The Audit_Field table describes
the database field being updated. */
CREATE TABLE IF NOT EXISTS awa_audit_field (
  /* the audit field identifier. */
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  /* the audit field name. */
  `name` VARCHAR(255) BINARY NOT NULL,
  /* the entity type */
  `entity_type` INTEGER NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
  `parameters` VARCHAR(255) BINARY NOT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS awa_message_type (
  /*  */
  `id` BIGINT NOT NULL,
  /* the message type name */
  `name` VARCHAR(255) BINARY NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* The message queue tracks the event messages that must be dispatched by
a given server. */
CREATE TABLE IF NOT EXISTS awa_queue (
  /*  */
  `id` BIGINT NOT NULL,
  /*  */
  `server_id` INTEGER NOT NULL,
  /* the message queue name */
  `name` VARCHAR(255) BINARY NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* The application that is granted access to the database. */
CREATE TABLE IF NOT EXISTS awa_application (
  /* the application identifier. */
  `id` BIGINT NOT NULL,
  /* the application name. */
  `name` VARCHAR(255) BINARY NOT NULL,
  /* the application secret key. */
  `secret_key` VARCHAR(255) BINARY NOT NULL,
  /* the application public identifier. */
  `client_id` VARCHAR(255) BINARY NOT NULL,
  /* the optimistic lock version. */
  `version` INTEGER NOT NULL,
  /* the application create date. */
  `create_date` DATETIME NOT NULL,
  /* the application update date. */
  `update_date` DATETIME NOT NULL,
  /* the application title displayed in the OAuth login form. */
  `title` VARCHAR(255) BINARY NOT NULL,
  /* the application description. */
  `description` VARCHAR(255) BINARY NOT NULL,
  /* the optional login URL. */
  `app_login_url` VARCHAR(255) BINARY NOT NULL,
  /* the application logo URL. */
  `app_logo_url` VARCHAR(255) BINARY NOT NULL,
  /*  */
  `user_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS awa_callback (
  /*  */
  `id` BIGINT NOT NULL,
  /*  */
  `url` VARCHAR(255) BINARY NOT NULL,
  /* the optimistic lock version. */
  `version` INTEGER NOT NULL,
  /*  */
  `application_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* The session is created when the user has granted an access to an application
or when the application has refreshed its access token. */
CREATE TABLE IF NOT EXISTS awa_oauth_session (
  /* the session identifier. */
  `id` BIGINT NOT NULL,
  /* the session creation date. */
  `create_date` DATETIME NOT NULL,
  /* a random salt string to access/request token generation. */
  `salt` VARCHAR(255) BINARY NOT NULL,
  /* the expiration date. */
  `expire_date` DATETIME NOT NULL,
  /* the application that is granted access. */
  `application_id` BIGINT NOT NULL,
  /*  */
  `user_id` BIGINT NOT NULL,
  /*  */
  `session_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* The permission table lists all the application permissions that are defined.
This is a system table shared by every user and workspace.
The list of permission is fixed and never changes. */
CREATE TABLE IF NOT EXISTS awa_permission (
  /* the permission database identifier. */
  `id` BIGINT NOT NULL,
  /* the permission name */
  `name` VARCHAR(255) BINARY NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS awa_access_key (
  /* the secure access key. */
  `access_key` VARCHAR(255) BINARY NOT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* The Email entity defines the user email addresses.
The user has a primary email address that is obtained
from the registration process (either through a form
submission or through OpenID authentication). */
CREATE TABLE IF NOT EXISTS awa_email (
  /* the email address. */
  `email` VARCHAR(255) BINARY NOT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS awa_session (
  /*  */
  `start_date` DATETIME NOT NULL,
  /*  */
  `end_date` DATETIME ,
  /*  */
  `ip_address` VARCHAR(255) BINARY NOT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* The User entity represents a user that can access and use the application. */
CREATE TABLE IF NOT EXISTS awa_user (
  /* the user first name. */
  `first_name` VARCHAR(255) BINARY NOT NULL,
  /* the user last name. */
  `last_name` VARCHAR(255) BINARY NOT NULL,
  /* the user password hash. */
  `password` VARCHAR(255) BINARY NOT NULL,
  /* the user OpenID identifier. */
  `open_id` VARCHAR(255) BINARY NOT NULL,
  /* the user country. */
  `country` VARCHAR(255) BINARY NOT NULL,
  /* the user display name. */
  `name` VARCHAR(255) BINARY NOT NULL,
  /* version number. */
  `version` INTEGER NOT NULL,
  /* the user identifier. */
  `id` BIGINT NOT NULL,
  /* the password salt. */
  `salt` VARCHAR(255) BINARY NOT NULL,
  /*  */
  `email_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT IGNORE INTO entity_type (name) VALUES
("awa_audit"), ("awa_audit_field"), ("awa_message"), ("awa_message_type"), ("awa_queue"), ("awa_application"), ("awa_callback"), ("awa_oauth_session"), ("awa_acl"), ("awa_permission"), ("awa_access_key"), ("awa_email"), ("awa_session"), ("awa_user");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "awa_user"), "first_name");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "awa_user"), "last_name");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "awa_user"), "country");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "awa_user"), "name");
/* Copied from awa-workspaces-mysql.sql*/
/* File generated automatically by dynamo */
/*  */
CREATE TABLE IF NOT EXISTS awa_invitation (
  /* the invitation identifier. */
  `id` BIGINT NOT NULL,
  /* version optimistic lock. */
  `version` INTEGER NOT NULL,
  /* date when the invitation was created and sent. */
  `create_date` DATETIME NOT NULL,
  /* the email address to which the invitation was sent. */
  `email` VARCHAR(255) BINARY NOT NULL,
  /* the invitation message. */
  `message` text NOT NULL,
  /* the date when the invitation was accepted. */
  `acceptance_date` DATETIME ,
  /* the workspace where the user is invited. */
  `workspace_id` BIGINT NOT NULL,
  /*  */
  `access_key_id` BIGINT ,
  /* the user being invited. */
  `invitee_id` BIGINT ,
  /*  */
  `inviter_id` BIGINT NOT NULL,
  /*  */
  `member_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* The workspace controls the features available in the application
for a set of users: the workspace members.  A user could create
several workspaces and be part of several workspaces that other
users have created. */
CREATE TABLE IF NOT EXISTS awa_workspace (
  /* the workspace identifier */
  `id` BIGINT NOT NULL,
  /*  */
  `version` INTEGER NOT NULL,
  /*  */
  `create_date` DATETIME NOT NULL,
  /*  */
  `owner_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS awa_workspace_feature (
  /*  */
  `id` BIGINT NOT NULL,
  /*  */
  `limit` INTEGER NOT NULL,
  /*  */
  `workspace_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* The workspace member indicates the users who
are part of the workspace. The join_date is NULL when
a user was invited but has not accepted the invitation. */
CREATE TABLE IF NOT EXISTS awa_workspace_member (
  /*  */
  `id` BIGINT NOT NULL,
  /* the date when the user has joined the workspace. */
  `join_date` DATETIME ,
  /* the member role. */
  `role` VARCHAR(255) BINARY NOT NULL,
  /*  */
  `member_id` BIGINT NOT NULL,
  /*  */
  `workspace_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT IGNORE INTO entity_type (name) VALUES
("awa_invitation"), ("awa_workspace"), ("awa_workspace_feature"), ("awa_workspace_member");
/* Copied from porion-mysql.sql*/
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
/* Describes a step in the build process.
Members are fozen to force the creation
of a new instance when the build configuration
is modified. */
CREATE TABLE IF NOT EXISTS porion_build_config_step (
  /* build step identifier */
  `id` BIGINT NOT NULL,
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
  /*  */
  `version` INTEGER NOT NULL,
  /* the build configuration that contains this build step. */
  `build_config_id` BIGINT NOT NULL,
  /*  */
  `previous_version_id` BIGINT ,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
  `update_date` DATETIME ,
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
("porion_build"), ("porion_build_config"), ("porion_build_config_step"), ("porion_build_executor"), ("porion_build_step"), ("porion_environment"), ("porion_last_build"), ("porion_node"), ("porion_branch"), ("porion_dependency"), ("porion_project"), ("porion_test"), ("porion_test_group"), ("porion_test_run"), ("porion_test_run_group");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_build_config"), "name");
INSERT IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_build_config"), "description");
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
/* Copied from awa_counters-mysql.sql*/
/* File generated automatically by dynamo */
/*  */
CREATE TABLE IF NOT EXISTS awa_counter (
  /* the object associated with the counter. */
  `object_id` BIGINT NOT NULL,
  /* the day associated with the counter. */
  `date` DATE NOT NULL,
  /* the counter value. */
  `counter` INTEGER NOT NULL,
  /* the counter definition identifier. */
  `definition_id` BIGINT NOT NULL,
  PRIMARY KEY (`object_id`, `date`, `definition_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/* A counter definition defines what the counter represents. It uniquely identifies
the counter for the Counter table. A counter may be associated with a database
table. In that case, the counter definition has a relation to the corresponding Entity_Type. */
CREATE TABLE IF NOT EXISTS awa_counter_definition (
  /* the counter name. */
  `name` VARCHAR(255) BINARY NOT NULL,
  /* the counter unique id. */
  `id` INTEGER NOT NULL,
  /* the optional entity type that identifies the database table. */
  `entity_type` INTEGER ,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*  */
CREATE TABLE IF NOT EXISTS awa_visit (
  /* the entity identifier. */
  `object_id` BIGINT NOT NULL,
  /* the number of times the entity was visited by the user. */
  `counter` INTEGER NOT NULL,
  /* the date and time when the entity was last visited. */
  `date` DATETIME NOT NULL,
  /* the user who visited the entity. */
  `user` BIGINT NOT NULL,
  /* the counter definition identifier. */
  `definition_id` BIGINT NOT NULL,
  PRIMARY KEY (`object_id`, `user`, `definition_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT IGNORE INTO entity_type (name) VALUES
("awa_counter"), ("awa_counter_definition"), ("awa_visit");
