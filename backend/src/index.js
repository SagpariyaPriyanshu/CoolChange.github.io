const express = require("express");
const cors = require("cors");
const config = require("./config");
const healthRouter = require("./routes/health");
const apiRouter = require("./routes/api");

const app = express();

app.use(cors());
app.use(express.json());
app.use("/health", healthRouter);
app.use("/api", apiRouter);

if (require.main === module) {
  app.listen(config.port, () => {
    console.log(`CoolChange API running on http://localhost:${config.port}`);
    console.log(`Health:     http://localhost:${config.port}/health`);
    console.log(`Database:   http://localhost:${config.port}/health/db`);
  });
}

module.exports = app;
