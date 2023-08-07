/* Update of porion_environment table with 3 new columns */
ALTER TABLE porion_environment ADD COLUMN kind TINYINT NOT NULL DEFAULT 0;
ALTER TABLE porion_environment ADD COLUMN secret TINYINT NOT NULL DEFAULT 0;
ALTER TABLE porion_environment ADD COLUMN step_number INTEGER;

INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM ado_entity_type WHERE name = "porion_environment"), "kind");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM ado_entity_type WHERE name = "porion_environment"), "secret");
INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM ado_entity_type WHERE name = "porion_environment"), "step_number");
