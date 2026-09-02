const { Pool } = require("pg");
const config = require("../config");

const pool = new Pool({
  connectionString: config.databaseUrl,
  // Cloud DBs (RDS) need SSL; local Postgres/PostGIS does not.
  ssl: config.databaseSsl ? { rejectUnauthorized: false } : undefined,
});

module.exports = pool;
