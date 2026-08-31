/**
 * Loads Yu's seed CSVs via psql. Run after `npm run migrate`.
 *
 *   npm run seed
 */
require("../config");
const path = require("path");
const { spawnSync } = require("child_process");
const config = require("../config");

const seedsDir = path.join(__dirname, "seeds");
const result = spawnSync(
  "psql",
  [config.databaseUrl, "-v", "ON_ERROR_STOP=1", "-f", "load_seeds.sql"],
  { cwd: seedsDir, stdio: "inherit" }
);

if (result.error) {
  console.error(
    "psql failed to start. Install PostgreSQL client tools, or run:\n" +
      `  cd ${seedsDir} && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f load_seeds.sql`
  );
  console.error(result.error.message);
  process.exit(1);
}

process.exit(result.status === 0 ? 0 : result.status || 1);
