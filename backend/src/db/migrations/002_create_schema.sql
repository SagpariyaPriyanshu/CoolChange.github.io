-- =============================================================================
-- 002_create_schema.sql  --  Cool Change domain schema (Story 0.3)
--
-- Author: Yu (Data Scientist), designed with Yipu (BE Lead).
-- Companion docs: SCHEMA.md, API_CONTRACT.md, BLOCK_COUNT_DISCREPANCY.md
--
-- Principles this schema follows (from the architecture decisions):
--   1. Precompute offline, ship static tables. The API is a READ LAYER --
--      it never aggregates, never fits a model, never joins at request time.
--   2. Store vegetation components as separate columns, never precomputed
--      combinations, so the front end can recombine them.
--   3. One colour scale shared across all scenarios (app_config), so the map
--      does not re-scale when the scenario toggle moves.
--   4. Discrete warming levels, not a continuous year slider -- the climate
--      data is indexed by warming level, not by year.
--
-- All geography is ASGS 2016, because the source heat dataset is keyed to
-- 2016 mesh blocks. The earlier "use ASGS Edition 3 (2021)" note does not
-- apply to this dataset.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- mesh_block -- the core table. One row per mesh block. Expect 54,239 rows.
-- -----------------------------------------------------------------------------
CREATE TABLE mesh_block (
    mb_code16        CHAR(11)     PRIMARY KEY,

    -- ABS hierarchy, all carried in the source heat file
    sa1_code16       CHAR(11)     NOT NULL,
    sa2_code16       CHAR(9)      NOT NULL,
    sa2_name         VARCHAR(64)  NOT NULL,
    sa3_code16       CHAR(5)      NOT NULL,
    sa3_name         VARCHAR(64)  NOT NULL,
    lga_name         VARCHAR(64)  NOT NULL,

    -- Heat. NOTE: this is a DEVIATION, not an absolute temperature.
    uhi_mean         REAL         NOT NULL,

    -- Vegetation. canopy_pct is the independent variable in the model.
    canopy_pct       REAL         NOT NULL,
    grass_pct        REAL         NOT NULL,
    shrub_pct        REAL         NOT NULL,
    any_veg_pct      REAL         NOT NULL,
    shrub_tree_pct   REAL         NOT NULL,
    tree_03_10_pct   REAL         NOT NULL,
    tree_10_15_pct   REAL         NOT NULL,
    tree_15plus_pct  REAL         NOT NULL,

    -- Census context (ABS 2016 Mesh Block Counts)
    mb_category      VARCHAR(24)  NOT NULL,
    dwellings        INTEGER      NOT NULL,
    persons          INTEGER      NOT NULL,
    area_sqkm        REAL         NOT NULL,

    -- Socio-economic context (SEIFA 2016, SA1 level). NULLABLE ON PURPOSE.
    irsd_score       INTEGER,
    irsd_decile      SMALLINT,

    CONSTRAINT ck_mesh_block_uhi_range
        CHECK (uhi_mean BETWEEN -20 AND 25),
    CONSTRAINT ck_mesh_block_pct_range
        CHECK (canopy_pct      BETWEEN 0 AND 100
           AND grass_pct       BETWEEN 0 AND 100
           AND shrub_pct       BETWEEN 0 AND 100
           AND any_veg_pct     BETWEEN 0 AND 100
           AND shrub_tree_pct  BETWEEN 0 AND 100
           AND tree_03_10_pct  BETWEEN 0 AND 100
           AND tree_10_15_pct  BETWEEN 0 AND 100
           AND tree_15plus_pct BETWEEN 0 AND 100),
    CONSTRAINT ck_mesh_block_counts_nonneg
        CHECK (dwellings >= 0 AND persons >= 0 AND area_sqkm > 0),
    CONSTRAINT ck_mesh_block_irsd_decile
        CHECK (irsd_decile IS NULL OR irsd_decile BETWEEN 1 AND 10)
);

COMMENT ON TABLE  mesh_block IS
    'One row per ABS 2016 mesh block in metropolitan Melbourne. 54,239 rows. '
    'The published study analysed 55,603; the extra blocks are mostly parkland '
    'and water that the public service does not publish. See '
    'BLOCK_COUNT_DISCREPANCY.md. Never cite 55,603 as our n.';

COMMENT ON COLUMN mesh_block.uhi_mean IS
    'Mean summer land surface temperature DEVIATION in degrees C from the '
    'non-urban baseline -- NOT an absolute temperature. Observed range in our '
    'data: -7.44 to +15.68. Derived from a satellite overpass at ~9:50am, so '
    'it is mid-morning surface heat, not afternoon peak and not night-time.';

COMMENT ON COLUMN mesh_block.canopy_pct IS
    'Percent tree canopy cover (source field PERANYTREE). The independent '
    'variable in the cooling model.';

COMMENT ON COLUMN mesh_block.area_sqkm IS
    'Albers-projected area from the ABS census file. Do NOT substitute the '
    'source Shape_Area field -- that arrives in square DEGREES because the '
    'extract requests outSR=4326, and is roughly 1e-6 times the wrong number.';

COMMENT ON COLUMN mesh_block.irsd_score IS
    'SEIFA Index of Relative Socio-economic Disadvantage, SA1 level, 2016. '
    'NULL for 1,477 blocks (2.7%), from two ABS confidentiality behaviours: '
    '1,345 blocks whose SA1 is absent from the SEIFA release entirely (290 '
    'SA1s) and 132 whose SA1 is listed but has its score suppressed as "-" '
    '(15 SA1s). 86.9% of them have zero residents. A NULL here is correct '
    'data, not a failed join. Never render it as 0.';

COMMENT ON COLUMN mesh_block.irsd_decile IS
    'SEIFA IRSD decile. 1 = most disadvantaged, 10 = least disadvantaged.';

CREATE INDEX ix_mesh_block_lga         ON mesh_block (lga_name);
CREATE INDEX ix_mesh_block_sa2_code    ON mesh_block (sa2_code16);
CREATE INDEX ix_mesh_block_sa2_name    ON mesh_block (sa2_name);
CREATE INDEX ix_mesh_block_sa3_code    ON mesh_block (sa3_code16);
CREATE INDEX ix_mesh_block_irsd_decile ON mesh_block (irsd_decile);
CREATE INDEX ix_mesh_block_category    ON mesh_block (mb_category);

-- Suburb search (US1.2.1). Prefix matching on a lowercased name.
CREATE INDEX ix_mesh_block_sa2_name_lower ON mesh_block (LOWER(sa2_name) varchar_pattern_ops);


-- -----------------------------------------------------------------------------
-- projection_metro -- the city-wide 2050 figure. Exactly 4 rows.
--
-- These are the MODAL band for metro Melbourne at each warming level, used for
-- headline copy and as the US3.2.5 fallback for blocks with no row in
-- mesh_block_projection. Per-block bands live in that table and DO vary across
-- the city -- see its comment.
-- -----------------------------------------------------------------------------
CREATE TABLE projection_metro (
    warming_level  NUMERIC(2,1) PRIMARY KEY,
    horizon_label  VARCHAR(24)  NOT NULL,
    statistic      VARCHAR(6)   NOT NULL DEFAULT '50.0',
    days_label     VARCHAR(12)  NOT NULL,
    days_lower     INTEGER      NOT NULL,
    days_upper     INTEGER,                       -- NULL = open ended, e.g. "15+"

    CONSTRAINT ck_projection_metro_level
        CHECK (warming_level IN (1.2, 1.5, 2.0, 3.0)),
    CONSTRAINT ck_projection_metro_bounds
        CHECK (days_upper IS NULL OR days_upper > days_lower)
);

COMMENT ON TABLE projection_metro IS
    'Projected days per year at or above 35 C for metropolitan Melbourne, by '
    'global warming level. Source: Australian Climate Service, median case '
    '(statistic 50.0), variable txge35. Four rows. Also the US3.2.5 fallback '
    'for blocks with no row in mesh_block_projection.';

COMMENT ON COLUMN projection_metro.warming_level IS
    'Global warming level, not a year. Agreed mapping: 1.2 = today, '
    '1.5 = 2030, 2.0 = 2050, 3.0 = 2050 under high warming (a SCENARIO, not a '
    'later year).';

COMMENT ON COLUMN projection_metro.statistic IS
    'Percentile of the model ensemble. A STRING in the source data. We use the '
    'median, "50.0", only.';

INSERT INTO projection_metro
    (warming_level, horizon_label,       statistic, days_label, days_lower, days_upper)
VALUES
    (1.2,          'Today',              '50.0',    '5-10',      5,          10),
    (1.5,          '2030',               '50.0',    '10-15',     10,         15),
    (2.0,          '2050',               '50.0',    '10-15',     10,         15),
    (3.0,          '2050 high warming',  '50.0',    '15+',       15,         NULL);


-- -----------------------------------------------------------------------------
-- mesh_block_projection -- per-block bands. 204,532 rows over 51,133 blocks.
--
-- Not 54,239 x 4: 3,106 coastal blocks fall outside every ACS polygon and
-- get no row at all. See the table comment below.
--
-- A block with NO ROWS here falls outside every projection polygon. That is
-- US3.2.5, and it is real: coastal blocks do it. The API falls back to
-- projection_metro and must say the figure is city-wide.
-- -----------------------------------------------------------------------------
CREATE TABLE mesh_block_projection (
    mb_code16      CHAR(11)     NOT NULL REFERENCES mesh_block (mb_code16) ON DELETE CASCADE,
    warming_level  NUMERIC(2,1) NOT NULL REFERENCES projection_metro (warming_level),
    days_label     VARCHAR(12)  NOT NULL,
    days_lower     INTEGER      NOT NULL,
    days_upper     INTEGER,

    PRIMARY KEY (mb_code16, warming_level)
);

COMMENT ON TABLE mesh_block_projection IS
    'Projected days >= 35 C per mesh block per warming level, from a spatial '
    'join of mesh block representative points to the ACS band polygons. '
    '204,532 rows covering 51,133 of the 54,239 blocks. The bands DO vary '
    'geographically: at 2.0 (2050) Melton runs 15+ days and the Mornington '
    'Peninsula 1-5, while 86% of the city sits at 10-15. At 1.5 (2030) the '
    'split is a genuine two-band north-west vs south-east gradient (33,756 vs '
    '16,528 blocks). The variation is COARSE -- three or four discrete classes, '
    'not a smooth surface -- so render it as banded classes, never as a '
    'continuous ramp. Absence of a row = the block falls outside every ACS '
    'polygon (US3.2.5): 3,106 coastal blocks in Port Phillip, Kingston, '
    'Bayside, Hobsons Bay and the Mornington Peninsula, holding 3.9% of the '
    'metro population. That is NOT missing data -- fall back to '
    'projection_metro and label the figure as city-wide.';


-- -----------------------------------------------------------------------------
-- area_baseline -- precomputed comparisons for the "Understand" panel.
--
-- Epic 2 asks how a block compares to its council area and to the metro
-- average. Computing that per request would make the API a compute layer,
-- so it is precomputed here.
-- -----------------------------------------------------------------------------
CREATE TABLE area_baseline (
    area_type          VARCHAR(8)   NOT NULL,
    -- Wide enough for an LGA name used as the code: metro Melbourne has no
    -- numeric LGA identifier in the source data, so the name IS the key, and
    -- "Mornington Peninsula (S)" is 24 characters.
    area_code          VARCHAR(64)  NOT NULL,
    area_name          VARCHAR(64)  NOT NULL,
    scope              VARCHAR(12)  NOT NULL,

    n_blocks           INTEGER      NOT NULL,
    uhi_mean           REAL         NOT NULL,
    uhi_p10            REAL         NOT NULL,
    uhi_p90            REAL         NOT NULL,
    canopy_mean        REAL         NOT NULL,
    canopy_p10         REAL         NOT NULL,
    canopy_p90         REAL         NOT NULL,

    coolest_mb_code    CHAR(11)     REFERENCES mesh_block (mb_code16),
    coolest_uhi        REAL,
    coolest_canopy_pct REAL,

    PRIMARY KEY (area_type, area_code, scope),

    CONSTRAINT ck_area_baseline_type
        CHECK (area_type IN ('METRO', 'LGA', 'SA3', 'SA2')),
    CONSTRAINT ck_area_baseline_scope
        CHECK (scope IN ('ALL', 'RESIDENTIAL')),
    CONSTRAINT ck_area_baseline_n
        CHECK (n_blocks > 0)
);

COMMENT ON TABLE area_baseline IS
    'Precomputed area statistics. Rebuild whenever mesh_block is reloaded -- '
    'these are a derived cache, not an independent source of truth.';

COMMENT ON COLUMN area_baseline.scope IS
    'ALL = every block in the area. RESIDENTIAL = mb_category = Residential '
    'only. Both are stored because our extract omits ~1,364 mostly-parkland '
    'blocks, so an ALL-scope "metro average" is not Melbourne''s true average, '
    'and the ALL-scope "coolest block" may miss the true coolest in council '
    'areas with large parks. RESIDENTIAL compares a resident''s street to '
    'other residential streets, which is the honest comparison. WHICHEVER THE '
    'UI SHOWS, IT MUST BE LABELLED: "average residential block in Wyndham", '
    'never "Wyndham''s average".';

COMMENT ON COLUMN area_baseline.coolest_mb_code IS
    'Coolest block in the area under this scope. WARNING for the UI: the '
    'coolest block does not always have more canopy. In Wyndham it has less '
    '(3.96% vs 4.74%) yet runs 8.3 C cooler, because the canopy-heat '
    'relationship is spatially non-stationary. Do not imply causation here.';


-- -----------------------------------------------------------------------------
-- model_coefficient -- the fitted canopy/heat relationship (Epic 4).
--
-- Kept in a table rather than hardcoded so that swapping global OLS for GWR
-- in Iteration 2 is a data change, not a code change and not a migration.
-- -----------------------------------------------------------------------------
CREATE TABLE model_coefficient (
    model_id     SERIAL       PRIMARY KEY,
    model_type   VARCHAR(16)  NOT NULL,
    scope_type   VARCHAR(8)   NOT NULL,
    -- VARCHAR(64) for the same reason as area_baseline.area_code: an LGA-scope
    -- GWR fit in Iteration 2 is keyed by LGA name.
    scope_code   VARCHAR(64)  NOT NULL,

    slope        REAL         NOT NULL,
    intercept    REAL         NOT NULL,
    pearson_r    REAL,
    r_squared    REAL,
    n_blocks     INTEGER      NOT NULL,

    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    fitted_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    notes        TEXT,

    CONSTRAINT ck_model_type
        CHECK (model_type IN ('OLS_GLOBAL', 'GWR')),
    CONSTRAINT ck_model_scope_type
        CHECK (scope_type IN ('METRO', 'LGA', 'MB')),
    CONSTRAINT ck_model_slope_sign
        CHECK (slope < 0)
);

COMMENT ON TABLE model_coefficient IS
    'Fitted relationship between canopy cover and surface heat. Iteration 2 '
    'adds GWR as scope_type = MB rows in this same table -- no migration '
    'needed.';

COMMENT ON COLUMN model_coefficient.slope IS
    'Change in uhi_mean (degrees C) per ONE PERCENTAGE POINT of extra canopy. '
    'Negative: more canopy, less heat. The front end simulates with '
    'uhi_simulated = uhi_mean + slope * (canopy_new_pct - canopy_pct). '
    'Sanity range from the literature is about -0.05 to -0.15 per point.';

COMMENT ON COLUMN model_coefficient.is_active IS
    'Exactly one active row per scope should be served by /bootstrap. Old '
    'fits are retained rather than deleted so results stay reproducible.';

CREATE UNIQUE INDEX ux_model_coefficient_active
    ON model_coefficient (scope_type, scope_code)
    WHERE is_active;

-- The current global fit. Benchmark: the published study reports slope
-- -0.1274, r -0.585, R2 0.34 on 55,603 blocks. We are within 3.6% on the
-- slope. A refit that drifts far from these means something broke.
INSERT INTO model_coefficient
    (model_type, scope_type, scope_code, slope, intercept, pearson_r, r_squared, n_blocks, notes)
VALUES
    ('OLS_GLOBAL', 'METRO', 'METRO', -0.1229, 10.0507, -0.5706, 0.326, 54239,
     'Global OLS on all 54,239 blocks. Benchmark (Sun et al. 2019, n=55,603): '
     'slope -0.1274, r -0.585, R2 0.34. Global OLS is deliberately weak -- the '
     'relationship is spatially non-stationary and the published GWR reaches '
     'adjusted R2 0.90. Association, not a controlled experiment.');


-- -----------------------------------------------------------------------------
-- app_config -- the shared colour scale and display constants.
-- Read once by GET /api/v1/bootstrap.
-- -----------------------------------------------------------------------------
CREATE TABLE app_config (
    key         VARCHAR(48) PRIMARY KEY,
    value       TEXT        NOT NULL,
    description TEXT
);

COMMENT ON TABLE app_config IS
    'Display constants served at page load. The colour scale lives here so it '
    'is fixed and shared across every scenario -- if the front end recomputed '
    'the domain from visible data, the map would look identical between '
    'scenarios and the toggle would appear broken.';

INSERT INTO app_config (key, value, description) VALUES
    ('uhi_scale_min',    '-8.0',
     'Fixed lower bound of the colour domain.'),
    ('uhi_scale_max',    '17.0',
     'Fixed upper bound. Deliberately past the observed max (15.68) so '
     'SIMULATED values stay on the legend instead of falling off the end.'),
    ('canopy_scale_max', '80.0',
     'Observed max canopy is 78.55.'),
    ('uhi_units',        'degrees C above non-urban baseline',
     'US1.1.2 requires the legend to state units and baseline explicitly.'),
    ('data_vintage',     '2018',
     'Newest metro-wide vintage available. DEECA has announced an update with '
     'no delivery date.'),
    ('n_blocks',         '54239',
     'Our n. Never cite 55,603 -- see BLOCK_COUNT_DISCREPANCY.md.');


-- -----------------------------------------------------------------------------
-- mesh_block_geometry -- OPTIONAL, and deliberately separate.
--
-- Polygons are ~34 MB for 54,239 blocks. They must never travel in a JSON API
-- response. The front end loads simplified geometry once as a static asset and
-- joins attributes client-side on mb_code16.
--
-- This table exists for SERVER-SIDE spatial lookups only -- "which block
-- contains this lat/lng" for map clicks and address search. That is the one
-- thing PostGIS earns its place for. Populate it only if we build that
-- endpoint; leaving it empty costs nothing.
-- -----------------------------------------------------------------------------
CREATE TABLE mesh_block_geometry (
    mb_code16 CHAR(11) PRIMARY KEY REFERENCES mesh_block (mb_code16) ON DELETE CASCADE,
    geom      GEOMETRY(MULTIPOLYGON, 4326) NOT NULL
);

CREATE INDEX ix_mesh_block_geometry_gist ON mesh_block_geometry USING GIST (geom);

COMMENT ON TABLE mesh_block_geometry IS
    'Optional. Server-side point-in-polygon lookups only. Geometry for '
    'rendering is served as a static asset, never through the API.';


-- -----------------------------------------------------------------------------
-- equity_by_decile -- the measured heat/disadvantage gradient (Epic 7).
--
-- Adopted from Yipu's schema draft, which reproduced these figures
-- independently in SQL while the pipeline computed them in pandas. Both agree
-- to two decimal places across all ten deciles, which is the strongest
-- validation available for this finding.
--
-- Extended here with the ALL / RESIDENTIAL scope split used everywhere else in
-- this schema, because the ALL scope includes parkland and industrial blocks
-- whose SEIFA decile describes the people in the surrounding SA1, not anyone
-- living on the block.
--
-- Blocks with no SEIFA are excluded, so the counts sum to 52,762, not 54,239.
-- That is correct: a block with no decile cannot be grouped by decile.
-- -----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW equity_by_decile AS
    SELECT 'ALL'::VARCHAR(12)         AS scope,
           irsd_decile,
           count(*)                   AS n_blocks,
           avg(uhi_mean)::REAL        AS mean_uhi,
           stddev(uhi_mean)::REAL     AS stddev_uhi,
           avg(canopy_pct)::REAL      AS mean_canopy_pct,
           sum(persons)               AS persons
      FROM mesh_block
     WHERE irsd_decile IS NOT NULL
     GROUP BY irsd_decile
    UNION ALL
    SELECT 'RESIDENTIAL'::VARCHAR(12),
           irsd_decile,
           count(*),
           avg(uhi_mean)::REAL,
           stddev(uhi_mean)::REAL,
           avg(canopy_pct)::REAL,
           sum(persons)
      FROM mesh_block
     WHERE irsd_decile IS NOT NULL AND mb_category = 'Residential'
     GROUP BY irsd_decile;

CREATE UNIQUE INDEX ux_equity_by_decile ON equity_by_decile (scope, irsd_decile);

COMMENT ON MATERIALIZED VIEW equity_by_decile IS
    'Mean heat and canopy by SEIFA IRSD decile (1 = most disadvantaged). Backs '
    'the equity chart in Epic 7. Refresh after every seed reload: '
    'REFRESH MATERIALIZED VIEW equity_by_decile. State the finding as a '
    'gradient, not a rule -- r between IRSD score and canopy is only +0.28, so '
    'plenty of hot blocks sit in advantaged areas.';
