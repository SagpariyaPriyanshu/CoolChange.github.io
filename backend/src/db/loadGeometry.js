/**
 * Populate mesh_block_geometry from Victoria's public Cooling and Greening
 * ArcGIS service. Existing rows are updated, so reruns are safe.
 *
 *   npm run geometry:load
 */
const pool = require("./pool");

const SOURCE =
  "https://plan-gis.mapshare.vic.gov.au/arcgis/rest/services/" +
  "CoolingGreening/CoolingGreening/MapServer/55/query";
const PAGE_SIZE = 1000;

const upsertGeometry = `
INSERT INTO mesh_block_geometry (mb_code16, geom)
SELECT RTRIM(m.mb_code16),
       ST_Multi(
         ST_CollectionExtract(
           ST_MakeValid(ST_SetSRID(ST_GeomFromGeoJSON(item.geometry::text), 4326)),
           3
         )
       )
  FROM jsonb_to_recordset($1::jsonb)
       AS item(mb_code16 text, geometry jsonb)
  JOIN mesh_block m ON m.mb_code16 = item.mb_code16
ON CONFLICT (mb_code16) DO UPDATE SET geom = EXCLUDED.geom
`;

async function fetchPage(offset) {
  const params = new URLSearchParams({
    where: "1=1",
    outFields: "MB_CODE16",
    returnGeometry: "true",
    outSR: "4326",
    geometryPrecision: "6",
    orderByFields: "OBJECTID",
    resultOffset: String(offset),
    resultRecordCount: String(PAGE_SIZE),
    f: "geojson",
  });
  const response = await fetch(`${SOURCE}?${params}`, {
    headers: { "User-Agent": "CoolChange/0.1 mesh-block geometry loader" },
  });
  if (!response.ok) {
    throw new Error(`Geometry source returned HTTP ${response.status}.`);
  }
  const payload = await response.json();
  return payload.features || [];
}

async function main() {
  let offset = 0;
  try {
    const existing = await pool.query(
      "SELECT COUNT(*)::integer AS count FROM mesh_block_geometry"
    );
    if (existing.rows[0].count < 54239) {
      while (true) {
        const features = await fetchPage(offset);
        if (!features.length) break;

        const rows = features.map((feature) => ({
          mb_code16: String(feature.properties.MB_CODE16),
          geometry: feature.geometry,
        }));
        await pool.query(upsertGeometry, [JSON.stringify(rows)]);
        offset += features.length;
        console.log(`Loaded ${offset.toLocaleString()} mesh-block polygons`);
        if (features.length < PAGE_SIZE) break;
      }
    } else {
      console.log("All 54,239 mesh-block polygons are already loaded.");
    }

    const result = await pool.query(
      "SELECT COUNT(*)::integer AS count FROM mesh_block_geometry"
    );
    console.log(`Geometry table now contains ${result.rows[0].count.toLocaleString()} rows.`);

    console.log("Rebuilding simplified suburb boundaries…");
    await pool.query(`
      INSERT INTO map_suburb_geometry (sa2_code16, geom)
      SELECT m.sa2_code16,
             ST_Multi(
               ST_SimplifyPreserveTopology(
                 ST_UnaryUnion(ST_Collect(g.geom)),
                 0.00035
               )
             )
        FROM mesh_block m
        JOIN mesh_block_geometry g USING (mb_code16)
       GROUP BY m.sa2_code16
      ON CONFLICT (sa2_code16) DO UPDATE SET geom = EXCLUDED.geom
    `);
    const suburbs = await pool.query(
      "SELECT COUNT(*)::integer AS count FROM map_suburb_geometry"
    );
    console.log(`Suburb map cache now contains ${suburbs.rows[0].count} boundaries.`);
  } finally {
    await pool.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
