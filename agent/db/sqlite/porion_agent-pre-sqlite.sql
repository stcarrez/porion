CREATE TABLE IF NOT EXISTS awa_audit_field (
  /* the audit field identifier. */
  `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  /* the audit field name. */
  `name` VARCHAR(255) NOT NULL,
  /* the entity type */
  `entity_type` INTEGER NOT NULL);
