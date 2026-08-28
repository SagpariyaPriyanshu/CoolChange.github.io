const express = require("express");
const pool = require("../db/pool");

const router = express.Router();

router.get("/", (req, res) => {
  res.json({
    status: "ok",
    service: "coolchange-backend",
    node: process.version,
    env: process.env.NODE_ENV || "development",
  });
});

router.get("/db", async (req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT
        current_database() AS database,
        current_user AS db_user,
        (SELECT extversion FROM pg_extension WHERE extname = 'postgis') AS postgis
    `);
    const row = rows[0];
    res.json({
      status: "ok",
      db: "connected",
      database: row.database,
      user: row.db_user,
      postgis: row.postgis || null,
    });
  } catch (error) {
    res.status(503).json({
      status: "error",
      db: "disconnected",
      message: error.message,
    });
  }
});

module.exports = router;
