/* Add column source_changes in porion_build table */
ALTER TABLE porion_build ADD COLUMN source_changes INTEGER NOT NULL DEFAULT 0;
