const express = require("express");

const router = express.Router();

router.get("/", (req, res) => {
  res.json({
    status: "ok",
    version: "v1",
    endpoints: [
      "GET /api/v1/bootstrap",
      "GET /api/v1/meshblocks",
      "GET /api/v1/meshblocks/:mb_code16",
      "GET /api/v1/areas/:area_type/:area_code",
      "GET /api/v1/search?q=",
    ],
  });
});

module.exports = router;
