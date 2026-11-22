import assert from "node:assert/strict";
import { test } from "node:test";
import { buildApp } from "../src/app.js";

test("GET /health returns ok", async (t) => {
  const app = await buildApp({ logger: false });
  t.after(() => app.close());

  const response = await app.inject({ method: "GET", url: "/health" });

  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.json(), { status: "ok" });
});

test("GET / reports the service and its version", async (t) => {
  const app = await buildApp({ logger: false });
  t.after(() => app.close());

  const response = await app.inject({ method: "GET", url: "/" });
  const body = response.json();

  assert.equal(response.statusCode, 200);
  assert.equal(body.service, "ecs-lab-api");
  assert.equal(typeof body.version, "string");
});

test("GET /api/greet/:name greets by name", async (t) => {
  const app = await buildApp({ logger: false });
  t.after(() => app.close());

  const response = await app.inject({ method: "GET", url: "/api/greet/Ada" });

  assert.equal(response.statusCode, 200);
  assert.equal(response.json().message, "Hello, Ada!");
});
