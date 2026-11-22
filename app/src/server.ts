import { buildApp } from "./app.js";

const port = Number(process.env.PORT ?? 3000);

const app = await buildApp();

// ECS stops a task by sending SIGTERM, then SIGKILL 30 seconds later.
// Finish in-flight requests and exit cleanly before that deadline.
for (const signal of ["SIGTERM", "SIGINT"] as const) {
  process.once(signal, () => {
    app.log.info({ signal }, "shutdown signal received, closing server");
    app.close().then(
      () => process.exit(0),
      (error: unknown) => {
        app.log.error(error, "error during shutdown");
        process.exit(1);
      },
    );
  });
}

try {
  // 0.0.0.0, not localhost: the load balancer reaches the container over the network.
  await app.listen({ port, host: "0.0.0.0" });
} catch (error) {
  app.log.error(error, "failed to start");
  process.exit(1);
}
