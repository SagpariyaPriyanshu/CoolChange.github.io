-- Spatial extension for mesh-block polygons (Story 0.3).
-- Domain tables are intentionally not created here: schema is designed
-- with Yu before any heat / vegetation / projection tables are added.
--
-- Docker Compose uses postgis/postgis, so this succeeds there.
-- A vanilla Homebrew Postgres without the postgis package skips it.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'postgis') THEN
    CREATE EXTENSION IF NOT EXISTS postgis;
  ELSE
    RAISE NOTICE 'PostGIS is not installed; skip CREATE EXTENSION. Use Docker Compose for the spatial image.';
  END IF;
END
$$;
