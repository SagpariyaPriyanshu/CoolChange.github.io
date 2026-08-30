const express = require("express");

const router = express.Router();

// Temporary endpoint added purely to verify the CI/CD pipeline
// (deploybackend.yml) — confirms a push to development actually reaches
// the running instance. Safe to remove once the workflow's been proven
// working, or to leave in as a lightweight "what's currently deployed"
// check if it turns out useful. 
router.get("/", (req, res) => {
  res.json({
    message: "CI/CD deploy test endpoint",
    deployedAt: new Date().toISOString(),
  });
});

module.exports = router;
