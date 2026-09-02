-- Precomputed SA2 outlines for the overview map. Rebuilt by loadGeometry.js.
-- Keeping this derived cache separate avoids unioning 54,239 polygons during
-- the first web request after every API restart.
CREATE TABLE IF NOT EXISTS map_suburb_geometry (
  sa2_code16 CHAR(9) PRIMARY KEY,
  geom GEOMETRY(MULTIPOLYGON, 4326) NOT NULL
);

CREATE INDEX IF NOT EXISTS ix_map_suburb_geometry_gist
  ON map_suburb_geometry USING GIST (geom);

COMMENT ON TABLE map_suburb_geometry IS
  'Derived, simplified SA2 outlines for the Melbourne overview map. Rebuild with npm run geometry:load.';
