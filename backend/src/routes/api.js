const express = require("express");

const router = express.Router();

/**
 * Placeholder for the Story 0.3 read-only API.
 * Mesh-block / heat / projection routes land here after Yu and Yipu
 * confirm the schema and response shape.
 */
router.get("/", (req, res) => {
  res.json({
    status: "scaffold",
    message:
      "Read-only endpoints will be added once the Story 0.3 schema is confirmed.",
    planned: [
      "GET /api/blocks — mesh blocks for the city map (US1.1.1)",
      "GET /api/blocks/:id — vegetation and heat for a selected block (US2.1.*)",
      "GET /api/projections — 2050 bands by warming level (US3.*)",
    ],
  });
});

module.exports = router;
