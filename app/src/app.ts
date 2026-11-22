import Fastify, { type FastifyInstance } from "fastify";

const SERVICE_NAME = "ecs-lab-api";

// Set at image build time from the git commit SHA (see the Dockerfile).
const VERSION = process.env.APP_VERSION ?? "dev";

// On ECS, every container can read its own task metadata from this endpoint.
// Off ECS (your laptop, CI) the variable is not set, so we report 'local'.
async function readTaskId(): Promise<string> {
  const metadataUri = process.env.ECS_CONTAINER_METADATA_URI_V4;
  if (!metadataUri) return "local";
  try {
    const response = await fetch(`${metadataUri}/task`, {
      signal: AbortSignal.timeout(2000),
    });
    const task = (await response.json()) as { TaskARN?: string };
    return task.TaskARN?.split("/").pop() ?? "unknown";
  } catch {
    return "unknown";
  }
}

export interface BuildAppOptions {
  /** Turn request logging off, for example in tests. */
  logger?: boolean;
}

export async function buildApp(
  options: BuildAppOptions = {},
): Promise<FastifyInstance> {
  const app = Fastify({
    // JSON lines on stdout. ECS ships stdout to CloudWatch Logs.
    logger:
      options.logger === false
        ? false
        : { level: process.env.LOG_LEVEL ?? "info" },
    // The load balancer sits in front of us, so trust X-Forwarded-* headers.
    trustProxy: true,
  });

  const taskId = await readTaskId();

  // Health check for the load balancer and for ECS.
  // Logged at warn and above only, so frequent checks do not flood the logs.
  app.get("/health", { logLevel: "warn" }, async () => ({ status: "ok" }));

  app.get("/", async () => ({
    service: SERVICE_NAME,
    version: VERSION,
    task: taskId,
    uptimeSeconds: Math.round(process.uptime()),
  }));

  // Sample route. Copy this pattern when you add your own endpoints.
  app.get<{ Params: { name: string } }>(
    "/api/greet/:name",
    async (request) => ({
      message: `Hello, ${request.params.name}!`,
      servedBy: taskId,
    }),
  );

  return app;
}
