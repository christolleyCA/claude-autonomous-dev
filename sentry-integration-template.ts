// ============================================================================
// OPTIMAL SENTRY INTEGRATION TEMPLATE
// ============================================================================
// This template provides production-ready Sentry integration with:
// - Environment-aware sampling (10% prod, 100% dev)
// - Business metrics tracking
// - Performance monitoring with custom spans
// - Conditional breadcrumbs
// - Error fingerprinting

import * as Sentry from "https://deno.land/x/sentry@7.119.0/index.mjs";

// Environment detection
const ENVIRONMENT = Deno.env.get("ENVIRONMENT") || "production";
const IS_PRODUCTION = ENVIRONMENT === "production";
const IS_DEV = ENVIRONMENT === "development";

// Initialize Sentry with optimal configuration
Sentry.init({
  dsn: Deno.env.get("SENTRY_DSN"),
  environment: ENVIRONMENT,

  // Environment-aware sampling (10% in prod, 100% in dev)
  tracesSampleRate: Deno.env.get("SENTRY_SAMPLE_RATE")
    ? parseFloat(Deno.env.get("SENTRY_SAMPLE_RATE")!)
    : (IS_PRODUCTION ? 0.1 : 1.0),

  // Enable profiling in dev only
  profilesSampleRate: IS_DEV ? 1.0 : 0,

  // Release tracking
  release: Deno.env.get("GIT_COMMIT_SHA"),

  // Function tagging
  initialScope: {
    tags: {
      function: "FUNCTION_NAME", // build-feature will replace this
      runtime: "deno",
      deployment: "supabase-edge",
    },
  },

  // Error filtering
  beforeSend(event, hint) {
    // Skip validation errors in production (expected user errors)
    if (IS_PRODUCTION && hint.originalException?.name === "ValidationError") {
      return null;
    }
    return event;
  },
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Add breadcrumb with environment awareness
 * Verbose in dev, minimal in production
 */
function addBreadcrumb(
  category: string,
  message: string,
  level: "debug" | "info" | "warning" | "error" = "info",
  data?: Record<string, any>
) {
  // In production, only log warnings and errors
  if (IS_PRODUCTION && (level === "debug" || level === "info")) {
    return;
  }

  Sentry.addBreadcrumb({ category, message, level, data });
}

/**
 * Track business metrics
 */
function trackMetric(
  name: string,
  value: number = 1,
  tags?: Record<string, string>
) {
  try {
    Sentry.metrics.increment(name, value, { tags: tags || {} });
  } catch (error) {
    console.warn("Failed to track metric:", error);
  }
}

/**
 * Create performance span
 */
function createSpan(transaction: any, operation: string, description: string): any {
  return transaction.startChild({ op: operation, description });
}

/**
 * Capture exception with fingerprinting
 */
function captureError(
  error: Error,
  context?: {
    fingerprint?: string[];
    tags?: Record<string, string>;
    extra?: Record<string, any>;
  }
) {
  Sentry.captureException(error, {
    fingerprint: context?.fingerprint || [error.name, error.message],
    tags: context?.tags,
    extra: context?.extra,
  });
}

/**
 * Track request/response metrics
 */
function trackRequestMetrics(req: Request, transaction: any) {
  const contentLength = req.headers.get("content-length");
  if (contentLength) {
    transaction.setData("request_size_bytes", parseInt(contentLength));
  }
}

function trackResponseMetrics(
  response: Response,
  transaction: any,
  startTime: number
) {
  const responseTime = Date.now() - startTime;
  const contentLength = response.headers.get("content-length");

  transaction.setData("response_time_ms", responseTime);
  if (contentLength) {
    transaction.setData("response_size_bytes", parseInt(contentLength));
  }

  // Track as business metric
  trackMetric("function.execution_time", responseTime, {
    status: response.status.toString(),
  });
}

export {
  Sentry,
  addBreadcrumb,
  trackMetric,
  createSpan,
  captureError,
  trackRequestMetrics,
  trackResponseMetrics,
  IS_PRODUCTION,
  IS_DEV,
};
