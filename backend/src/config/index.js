require("dotenv").config();

const config = {
  port: Number(process.env.PORT) || 3001,
  nodeEnv: process.env.NODE_ENV || "development",
  databaseUrl:
    process.env.DATABASE_URL ||
    "postgres://coolchange:coolchange@localhost:5433/coolchange",
  // SSL for cloud databases (RDS); leave false for local Postgres/PostGIS.
  databaseSsl: process.env.DATABASE_SSL === "true",
};

module.exports = config;
