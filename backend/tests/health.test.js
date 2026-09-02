const request = require("supertest");
const app = require("../src/index");

describe("GET /health", () => {
  it("returns ok status", async () => {
    const response = await request(app).get("/health");

    expect(response.status).toBe(200);
    expect(response.body.status).toBe("ok");
    expect(response.body.service).toBe("coolchange-backend");
  });
});

describe("GET /api", () => {
  it("points at the v1 read-only API", async () => {
    const response = await request(app).get("/api");

    expect(response.status).toBe(200);
    expect(response.body.version).toBe("v1");
    expect(response.body.endpoints[0]).toMatch(/^GET \/api\/v1\//);
  });
});
