/* Copied from ado-postgresql.sql*/
/* File generated automatically by dynamo */
/* Entity table that enumerates all known database tables */
CREATE TABLE IF NOT EXISTS entity_type (
  /* the database table unique entity index */
  "id" SERIAL,
  /* the database entity name */
  "name" VARCHAR(127) UNIQUE ,
  PRIMARY KEY ("id")
);
/* Sequence generator */
CREATE TABLE IF NOT EXISTS sequence (
  /* the sequence name */
  "name" VARCHAR(127) UNIQUE NOT NULL,
  /* the sequence record version */
  "version" INTEGER NOT NULL,
  /* the sequence value */
  "value" BIGINT NOT NULL,
  /* the sequence block size */
  "block_size" BIGINT NOT NULL,
  PRIMARY KEY ("name")
);
INSERT INTO entity_type (name) VALUES
('entity_type'), ('sequence')
  ON CONFLICT DO NOTHING;
/* Copied from awa-postgresql.sql*/
/* File generated automatically by dynamo */
/* The Audit table records the changes made on database on behalf of a user.
The record indicates the database table and row, the field being updated,
the old and new value. The old and new values are converted to a string
and they truncated if necessary to 256 characters. */
CREATE TABLE IF NOT EXISTS awa_audit (
  /* the audit identifier */
  "id" BIGINT NOT NULL,
  /* the date when the field was modified. */
  "date" TIMESTAMP NOT NULL,
  /* the old field value. */
  "old_value" VARCHAR(255) ,
  /* the new field value. */
  "new_value" VARCHAR(255) ,
  /* the database entity identifier to which the audit is associated. */
  "entity_id" BIGINT NOT NULL,
  /*  */
  "field" INTEGER NOT NULL,
  /* the user session under which the field was modified. */
  "session_id" BIGINT ,
  /* the entity type. */
  "entity_type" INTEGER NOT NULL,
  PRIMARY KEY ("id")
);
/* The Audit_Field table describes
the database field being updated. */
CREATE TABLE IF NOT EXISTS awa_audit_field (
  /* the audit field identifier. */
  "id" SERIAL,
  /* the audit field name. */
  "name" VARCHAR(255) NOT NULL,
  /* the entity type */
  "entity_type" INTEGER NOT NULL,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS awa_message (
  /* the message identifier */
  "id" BIGINT NOT NULL,
  /* the message creation date */
  "create_date" TIMESTAMP NOT NULL,
  /* the message priority */
  "priority" INTEGER NOT NULL,
  /* the message count */
  "count" INTEGER NOT NULL,
  /* the message parameters */
  "parameters" VARCHAR(255) NOT NULL,
  /* the server identifier which processes the message */
  "server_id" INTEGER NOT NULL,
  /* the task identfier on the server which processes the message */
  "task_id" INTEGER NOT NULL,
  /* the message status */
  "status" SMALLINT NOT NULL,
  /* the message processing date */
  "processing_date" TIMESTAMP ,
  /*  */
  "version" INTEGER NOT NULL,
  /* the entity identifier to which this event is associated. */
  "entity_id" BIGINT NOT NULL,
  /* the entity type of the entity identifier to which this event is associated. */
  "entity_type" INTEGER NOT NULL,
  /* the date and time when the event was finished to be processed. */
  "finish_date" TIMESTAMP ,
  /*  */
  "queue_id" BIGINT NOT NULL,
  /* the message type */
  "message_type_id" BIGINT NOT NULL,
  /* the optional user who triggered the event message creation */
  "user_id" BIGINT ,
  /* the optional user session that triggered the message creation */
  "session_id" BIGINT ,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS awa_message_type (
  /*  */
  "id" BIGINT NOT NULL,
  /* the message type name */
  "name" VARCHAR(255) NOT NULL,
  PRIMARY KEY ("id")
);
/* The message queue tracks the event messages that must be dispatched by
a given server. */
CREATE TABLE IF NOT EXISTS awa_queue (
  /*  */
  "id" BIGINT NOT NULL,
  /*  */
  "server_id" INTEGER NOT NULL,
  /* the message queue name */
  "name" VARCHAR(255) NOT NULL,
  PRIMARY KEY ("id")
);
/* The application that is granted access to the database. */
CREATE TABLE IF NOT EXISTS awa_application (
  /* the application identifier. */
  "id" BIGINT NOT NULL,
  /* the application name. */
  "name" VARCHAR(255) NOT NULL,
  /* the application secret key. */
  "secret_key" VARCHAR(255) NOT NULL,
  /* the application public identifier. */
  "client_id" VARCHAR(255) NOT NULL,
  /* the optimistic lock version. */
  "version" INTEGER NOT NULL,
  /* the application create date. */
  "create_date" TIMESTAMP NOT NULL,
  /* the application update date. */
  "update_date" TIMESTAMP NOT NULL,
  /* the application title displayed in the OAuth login form. */
  "title" VARCHAR(255) NOT NULL,
  /* the application description. */
  "description" VARCHAR(255) NOT NULL,
  /* the optional login URL. */
  "app_login_url" VARCHAR(255) NOT NULL,
  /* the application logo URL. */
  "app_logo_url" VARCHAR(255) NOT NULL,
  /*  */
  "user_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS awa_callback (
  /*  */
  "id" BIGINT NOT NULL,
  /*  */
  "url" VARCHAR(255) NOT NULL,
  /* the optimistic lock version. */
  "version" INTEGER NOT NULL,
  /*  */
  "application_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/* The session is created when the user has granted an access to an application
or when the application has refreshed its access token. */
CREATE TABLE IF NOT EXISTS awa_oauth_session (
  /* the session identifier. */
  "id" BIGINT NOT NULL,
  /* the session creation date. */
  "create_date" TIMESTAMP NOT NULL,
  /* a random salt string to access/request token generation. */
  "salt" VARCHAR(255) NOT NULL,
  /* the expiration date. */
  "expire_date" TIMESTAMP NOT NULL,
  /* the application that is granted access. */
  "application_id" BIGINT NOT NULL,
  /*  */
  "user_id" BIGINT NOT NULL,
  /*  */
  "session_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/* The ACL table records permissions which are granted for a user to access a given database entity. */
CREATE TABLE IF NOT EXISTS awa_acl (
  /* the ACL identifier */
  "id" BIGINT NOT NULL,
  /* the entity identifier to which the ACL applies */
  "entity_id" BIGINT NOT NULL,
  /* the writeable flag */
  "writeable" BOOLEAN NOT NULL,
  /*  */
  "user_id" BIGINT NOT NULL,
  /*  */
  "workspace_id" BIGINT NOT NULL,
  /* the entity type concerned by the ACL. */
  "entity_type" INTEGER NOT NULL,
  /* the permission that is granted. */
  "permission" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/* The permission table lists all the application permissions that are defined.
This is a system table shared by every user and workspace.
The list of permission is fixed and never changes. */
CREATE TABLE IF NOT EXISTS awa_permission (
  /* the permission database identifier. */
  "id" BIGINT NOT NULL,
  /* the permission name */
  "name" VARCHAR(255) NOT NULL,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS awa_access_key (
  /* the secure access key. */
  "access_key" VARCHAR(255) NOT NULL,
  /* the access key expiration date. */
  "expire_date" DATE NOT NULL,
  /* the access key identifier. */
  "id" BIGINT NOT NULL,
  /*  */
  "version" INTEGER NOT NULL,
  /* the access key type. */
  "kind" SMALLINT NOT NULL,
  /*  */
  "user_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/* The Email entity defines the user email addresses.
The user has a primary email address that is obtained
from the registration process (either through a form
submission or through OpenID authentication). */
CREATE TABLE IF NOT EXISTS awa_email (
  /* the email address. */
  "email" VARCHAR(255) NOT NULL,
  /* the last mail delivery status (if known). */
  "status" SMALLINT NOT NULL,
  /* the date when the last email error was detected. */
  "last_error_date" TIMESTAMP NOT NULL,
  /*  */
  "version" INTEGER NOT NULL,
  /* the email primary key. */
  "id" BIGINT NOT NULL,
  /* the user. */
  "user_id" BIGINT ,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS awa_session (
  /*  */
  "start_date" TIMESTAMP NOT NULL,
  /*  */
  "end_date" TIMESTAMP ,
  /*  */
  "ip_address" VARCHAR(255) NOT NULL,
  /*  */
  "stype" SMALLINT NOT NULL,
  /*  */
  "version" INTEGER NOT NULL,
  /*  */
  "server_id" INTEGER NOT NULL,
  /*  */
  "id" BIGINT NOT NULL,
  /*  */
  "auth_id" BIGINT ,
  /*  */
  "user_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/* The User entity represents a user that can access and use the application. */
CREATE TABLE IF NOT EXISTS awa_user (
  /* the user first name. */
  "first_name" VARCHAR(255) NOT NULL,
  /* the user last name. */
  "last_name" VARCHAR(255) NOT NULL,
  /* the user password hash. */
  "password" VARCHAR(255) NOT NULL,
  /* the user OpenID identifier. */
  "open_id" VARCHAR(255) NOT NULL,
  /* the user country. */
  "country" VARCHAR(255) NOT NULL,
  /* the user display name. */
  "name" VARCHAR(255) NOT NULL,
  /* version number. */
  "version" INTEGER NOT NULL,
  /* the user identifier. */
  "id" BIGINT NOT NULL,
  /* the password salt. */
  "salt" VARCHAR(255) NOT NULL,
  /*  */
  "email_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
INSERT INTO entity_type (name) VALUES
('awa_audit'), ('awa_audit_field'), ('awa_message'), ('awa_message_type'), ('awa_queue'), ('awa_application'), ('awa_callback'), ('awa_oauth_session'), ('awa_acl'), ('awa_permission'), ('awa_access_key'), ('awa_email'), ('awa_session'), ('awa_user')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'awa_user'), 'first_name')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'awa_user'), 'last_name')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'awa_user'), 'country')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'awa_user'), 'name')
  ON CONFLICT DO NOTHING;
/* Copied from awa_counters-postgresql.sql*/
/* File generated automatically by dynamo */
/*  */
CREATE TABLE IF NOT EXISTS awa_counter (
  /* the object associated with the counter. */
  "object_id" BIGINT NOT NULL,
  /* the day associated with the counter. */
  "date" DATE NOT NULL,
  /* the counter value. */
  "counter" INTEGER NOT NULL,
  /* the counter definition identifier. */
  "definition_id" BIGINT NOT NULL,
  PRIMARY KEY ("object_id", "date", "definition_id")
);
/* A counter definition defines what the counter represents. It uniquely identifies
the counter for the Counter table. A counter may be associated with a database
table. In that case, the counter definition has a relation to the corresponding Entity_Type. */
CREATE TABLE IF NOT EXISTS awa_counter_definition (
  /* the counter name. */
  "name" VARCHAR(255) NOT NULL,
  /* the counter unique id. */
  "id" INTEGER NOT NULL,
  /* the optional entity type that identifies the database table. */
  "entity_type" INTEGER ,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS awa_visit (
  /* the entity identifier. */
  "object_id" BIGINT NOT NULL,
  /* the number of times the entity was visited by the user. */
  "counter" INTEGER NOT NULL,
  /* the date and time when the entity was last visited. */
  "date" TIMESTAMP NOT NULL,
  /* the user who visited the entity. */
  "user" BIGINT NOT NULL,
  /* the counter definition identifier. */
  "definition_id" BIGINT NOT NULL,
  PRIMARY KEY ("object_id", "user", "definition_id")
);
INSERT INTO entity_type (name) VALUES
('awa_counter'), ('awa_counter_definition'), ('awa_visit')
  ON CONFLICT DO NOTHING;
/* Copied from porion-postgresql.sql*/
/* File generated automatically by dynamo */
/*  */
CREATE TABLE IF NOT EXISTS porion_build (
  /* the build global identifier. */
  "id" BIGINT NOT NULL,
  /* the optimistic lock. */
  "version" INTEGER NOT NULL,
  /* the project build number. */
  "number" INTEGER NOT NULL,
  /* the build creation date. */
  "create_date" TIMESTAMP NOT NULL,
  /* the date when the build was finished. */
  "finish_date" TIMESTAMP ,
  /* the number of tests that passed. */
  "pass_count" INTEGER NOT NULL,
  /* the number of tests that failed. */
  "fail_count" INTEGER NOT NULL,
  /* the number of tests that timeout. */
  "timeout_count" INTEGER NOT NULL,
  /* the test total duration in us. */
  "test_duration" INTEGER NOT NULL,
  /*  */
  "status"  NOT NULL,
  /* the build configuration. */
  "build_config_id" BIGINT NOT NULL,
  /* the node where the build was made. */
  "node_id" BIGINT NOT NULL,
  /* the branch associated with the build. */
  "branch_id" BIGINT NOT NULL,
  /* the project. */
  "project_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS porion_build_config (
  /* identifier */
  "id" BIGINT NOT NULL,
  /* optimistic locking */
  "version" INTEGER NOT NULL,
  /*  */
  "node_id" BIGINT ,
  /*  */
  "project_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS porion_build_step (
  /* build step identifier */
  "id" BIGINT NOT NULL,
  /* the optimistic locking. */
  "version" INTEGER NOT NULL,
  /* the build step command. */
  "parameters" VARCHAR(65536) NOT NULL,
  /* the build step number. */
  "number" INTEGER NOT NULL,
  /* the builder controller that handles execution of this build step. */
  "builder" INTEGER NOT NULL,
  /* the maximum execution time in seconds. */
  "timeout" INTEGER NOT NULL,
  /* the step classification type. */
  "step" INTEGER NOT NULL,
  /* the build configuration that contains this build step. */
  "build_config_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS porion_node (
  /* the node identifier */
  "id" BIGINT NOT NULL,
  /* optimistic lock version */
  "version" INTEGER NOT NULL,
  /* the node name. */
  "name" VARCHAR(255) NOT NULL,
  /* the login name. */
  "login" VARCHAR(255) NOT NULL,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS porion_branch (
  /* the identifier. */
  "id" BIGINT NOT NULL,
  /* the optimistic lock version. */
  "version" INTEGER NOT NULL,
  /* the branch name. */
  "name" VARCHAR(255) NOT NULL,
  /* the last identification tag. */
  "tag" VARCHAR(255) NOT NULL,
  /* the date of the last detected change. */
  "last_date" TIMESTAMP ,
  /* the date when the branch was created. */
  "create_date" TIMESTAMP NOT NULL,
  /* the date when the branch was updated. */
  "update_date" TIMESTAMP NOT NULL,
  /* the branch status. */
  "status" INTEGER NOT NULL,
  /*  */
  "project_id" BIGINT NOT NULL,
  /* the last build. */
  "last_build_id" BIGINT ,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS porion_dependency (
  /* dependency identifier. */
  "id" BIGINT NOT NULL,
  /* optimistic locking. */
  "version" INTEGER NOT NULL,
  /*  */
  "project_id" BIGINT NOT NULL,
  /*  */
  "owner_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS porion_project (
  /* the project identifier */
  "id" BIGINT NOT NULL,
  /* the project name */
  "name" VARCHAR(255) NOT NULL,
  /* optimistic lock version */
  "version" INTEGER NOT NULL,
  /* the project description. */
  "description" VARCHAR(255) NOT NULL,
  /* date when the project was created. */
  "create_date" TIMESTAMP NOT NULL,
  /* date when the project was modified. */
  "update_date" TIMESTAMP NOT NULL,
  /* the project status. */
  "status" INTEGER NOT NULL,
  /*  */
  "scm" INTEGER NOT NULL,
  /* source control information parameter */
  "scm_url" VARCHAR(255) NOT NULL,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS porion_test (
  /* the test identifier */
  "id" BIGINT NOT NULL,
  /* the test name. */
  "name" VARCHAR(255) NOT NULL,
  /*  */
  "create_date" TIMESTAMP NOT NULL,
  /* the optimistic lock version */
  "version" INTEGER NOT NULL,
  /* the number of pass for this test case. */
  "total_pass_count" INTEGER NOT NULL,
  /* the total number of times the test failed. */
  "total_fail_count" INTEGER NOT NULL,
  /* the total number of time the test resulted in a timeout. */
  "total_timeout_count" INTEGER NOT NULL,
  /* the last date when the test passed. */
  "last_pass_date" TIMESTAMP ,
  /* the last date when the test failed. */
  "last_fail_date" TIMESTAMP ,
  /* the last date when the test failed with a timeout. */
  "last_timeout_date" TIMESTAMP ,
  /* the last build that succeeded. */
  "last_pass_build" INTEGER ,
  /* the last build that failed. */
  "last_fail_build" INTEGER ,
  /* the last build that resulted in a timeout. */
  "last_timeout_build" INTEGER ,
  /*  */
  "total_skip_count" INTEGER NOT NULL,
  /*  */
  "last_skip_date" TIMESTAMP NOT NULL,
  /*  */
  "last_skip_build" INTEGER NOT NULL,
  /*  */
  "group_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS porion_test_group (
  /* the group identifier. */
  "id" BIGINT NOT NULL,
  /* optimistic lock version */
  "version" INTEGER NOT NULL,
  /* the group name. */
  "name" VARCHAR(255) NOT NULL,
  /* the date when this group was created. */
  "create_date" TIMESTAMP NOT NULL,
  /*  */
  "project_id" BIGINT NOT NULL,
  /*  */
  "group_id" BIGINT ,
  PRIMARY KEY ("id")
);
/* Describes the result of execution of the test case. */
CREATE TABLE IF NOT EXISTS porion_test_run (
  /* the test execution time in us. */
  "duration" INTEGER NOT NULL,
  /* the test execution status. */
  "status" INTEGER NOT NULL,
  /*  */
  "id" BIGINT NOT NULL,
  /* the number of assertions that have been checked */
  "assertions" INTEGER NOT NULL,
  /* the test case information */
  "test_id" BIGINT NOT NULL,
  /*  */
  "group_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
/*  */
CREATE TABLE IF NOT EXISTS porion_test_run_group (
  /* group identifier */
  "id" BIGINT NOT NULL,
  /* optimistic locking */
  "version" INTEGER NOT NULL,
  /*  */
  "total_pass_count" INTEGER NOT NULL,
  /*  */
  "total_fail_count" INTEGER NOT NULL,
  /*  */
  "total_timeout_count" INTEGER NOT NULL,
  /*  */
  "total_skip_count" INTEGER NOT NULL,
  /*  */
  "diff_pass" INTEGER NOT NULL,
  /*  */
  "diff_fail" INTEGER NOT NULL,
  /*  */
  "diff_timeout" INTEGER NOT NULL,
  /*  */
  "diff_skip" INTEGER NOT NULL,
  /* total duration for the execution of the test group */
  "duration" INTEGER NOT NULL,
  /*  */
  "build_id" BIGINT NOT NULL,
  /*  */
  "group_id" BIGINT NOT NULL,
  PRIMARY KEY ("id")
);
INSERT INTO entity_type (name) VALUES
('porion_build'), ('porion_build_config'), ('porion_build_step'), ('porion_node'), ('porion_branch'), ('porion_dependency'), ('porion_project'), ('porion_test'), ('porion_test_group'), ('porion_test_run'), ('porion_test_run_group')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_build_step'), 'parameters')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_build_step'), 'number')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_build_step'), 'timeout')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_node'), 'name')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_node'), 'login')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_branch'), 'tag')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_branch'), 'last_date')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_project'), 'name')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_project'), 'description')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_project'), 'status')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_project'), 'scm')
  ON CONFLICT DO NOTHING;
INSERT INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = 'porion_project'), 'scm_url')
  ON CONFLICT DO NOTHING;
