/* Add column last_change and last_reported_build_id in porion_subscriber table */
ALTER TABLE porion_subscriber ADD COLUMN last_change BIGINT;
ALTER TABLE porion_subscriber ADD COLUMN last_reported_build_id BIGINT;
