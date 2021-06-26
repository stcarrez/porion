/* File generated automatically by dynamo */
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
  /*  */
  `status`  NOT NULL,
  /*  */
  `last_build_id` BIGINT ,
  /*  */
  `project_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
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
  /* the build configuration. */
  `build_config_id` BIGINT NOT NULL,
  /* the node where the build was made. */
  `node_id` BIGINT NOT NULL,
  /* the project. */
  `project_id` BIGINT NOT NULL,
  /*  */
  `branch_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS porion_build_config (
  /* identifier */
  `id` BIGINT NOT NULL,
  /* optimistic locking */
  `version` INTEGER NOT NULL,
  /*  */
  `node_id` BIGINT ,
  /*  */
  `project_id` BIGINT NOT NULL,
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
  `update_date` DATETIME NOT NULL,
  /* the project status. */
  `status` INTEGER NOT NULL,
  /*  */
  `scm` INTEGER NOT NULL,
  /* source control information parameter */
  `scm_url` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS porion_test (
  /* the test identifier */
  `id` BIGINT NOT NULL,
  /* the test name. */
  `name` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`)
);
/*  */
CREATE TABLE IF NOT EXISTS porion_test_run (
  /* the optimistic lock. */
  `version` INTEGER NOT NULL,
  /* the test execution time in us. */
  `duration` INTEGER NOT NULL,
  /* the test execution status. */
  `status` INTEGER NOT NULL,
  /*  */
  `id` BIGINT NOT NULL,
  /*  */
  `build_id` BIGINT NOT NULL,
  /*  */
  `test_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_branch");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_build_config");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_node");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_project");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_test");
INSERT OR IGNORE INTO entity_type (name) VALUES ("porion_test_run");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_branch"), "tag");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_branch"), "last_date");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_node"), "name");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_node"), "login");
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
