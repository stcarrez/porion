/* Setup indexes */
CREATE INDEX IF NOT EXISTS porion_last_build_idx_1 ON porion_last_build (
  build_id
);
CREATE INDEX IF NOT EXISTS porion_last_build_idx_2 ON porion_last_build (
  branch_id
);
CREATE INDEX IF NOT EXISTS porion_last_build_idx_3 ON porion_last_build (
  recipe_id
);
