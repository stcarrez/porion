/* Migration from Porion 0.2.0 to Porion 0.3.0 */

ALTER TABLE porion_node ADD COLUMN `check_rules` VARCHAR(255) NOT NULL DEFAULT 'git mvn make cloc gprbuild lcov';

INSERT OR IGNORE INTO awa_audit_field (entity_type, name)
  VALUES ((SELECT id FROM entity_type WHERE name = "porion_node"), "check_rules");
