/* File generated automatically by dynamo */
/* The subscriber table indicates a user that is interested to be notified by changes
on the project. */
CREATE TABLE IF NOT EXISTS porion_subscriber (
  /* the subscriber id */
  `id` BIGINT NOT NULL,
  /* the optimistic lock version */
  `version` INTEGER NOT NULL,
  /* the date and time of the last notification. */
  `last_notification_date` DATETIME ,
  /* the date and time of the last check for notification. */
  `check_date` DATETIME ,
  /*  */
  `frequency` TINYINT NOT NULL,
  /*  */
  `send_count` INTEGER NOT NULL,
  /* notify when some configuration is changed. */
  `notify_config` TINYINT NOT NULL,
  /* notify when a build is made */
  `notify_build` TINYINT NOT NULL,
  /* notify when unit tests change */
  `notify_xunit` TINYINT NOT NULL,
  /*  */
  `project_id` BIGINT NOT NULL,
  /*  */
  `email_id` BIGINT NOT NULL,
  PRIMARY KEY (`id`)
);
INSERT OR IGNORE INTO ado_entity_type (name) VALUES ("porion_subscriber");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM ado_entity_type WHERE name = "porion_subscriber"), "frequency");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM ado_entity_type WHERE name = "porion_subscriber"), "notify_config");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM ado_entity_type WHERE name = "porion_subscriber"), "notify_build");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM ado_entity_type WHERE name = "porion_subscriber"), "notify_xunit");
INSERT OR IGNORE INTO ado_version (name, version) VALUES ("porion", 2);
