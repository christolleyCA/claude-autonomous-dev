# Sentry Integration for NFP Website Finder

**Complete setup guide for error tracking and performance monitoring**

---

## 📋 Project Configuration

### Manual Project Creation (Required First Step)

Since Sentry projects must be created through the web UI, follow these steps:

1. **Go to Sentry:** https://oxfordshire-inc.sentry.io
2. **Create New Project:**
   - Click "Projects" → "Create Project"
   - Platform: **Node.js**
   - Project Name: `nfp-website-finder`
   - Default Alert Settings: **Yes**
   - Team: Select your default team

3. **Save the DSN:** You'll get a DSN like:
   ```
   https://[key]@[org].ingest.us.sentry.io/[project-id]
   ```
   Keep this for Step 2!

---

## 🔧 N8N Integration Code

### Step 1: Create Sentry Helper Module (Reusable)

Create this as a **Function Node** at the start of your workflow:

```javascript
/**
 * SENTRY HELPER MODULE
 * Reusable Sentry tracking for n8n workflows
 */

const SENTRY_DSN = "YOUR_DSN_HERE"; // Replace with actual DSN from Sentry project
const ENVIRONMENT = "production";
const RELEASE = "nfp-website-finder@1.0.0";

// Lightweight Sentry HTTP client (no SDK needed in n8n)
class SentryTracker {
  constructor(dsn, options = {}) {
    this.dsn = dsn;
    this.environment = options.environment || 'production';
    this.release = options.release || 'unknown';

    // Parse DSN
    const match = dsn.match(/https:\/\/(.+)@(.+)\/(.+)/);
    if (!match) throw new Error('Invalid Sentry DSN');

    this.publicKey = match[1];
    this.host = match[2];
    this.projectId = match[3];
    this.endpoint = `https://${this.host}/api/${this.projectId}/store/`;
  }

  // Send event to Sentry
  async send(payload) {
    const auth = `Sentry sentry_version=7, sentry_key=${this.publicKey}`;

    const response = await fetch(this.endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Sentry-Auth': auth,
      },
      body: JSON.stringify(payload)
    });

    return response.ok;
  }

  // Track custom event
  async trackEvent(eventName, data = {}) {
    const payload = {
      event_id: this._generateId(),
      timestamp: Date.now() / 1000,
      platform: 'node',
      environment: this.environment,
      release: this.release,
      message: {
        message: eventName
      },
      level: 'info',
      tags: {
        event_type: eventName,
        processor_id: data.processor_id || 'unknown',
        ...data.tags
      },
      extra: data.extra || {},
      contexts: {
        workflow: {
          name: data.workflow_name || 'nfp-website-finder',
          execution_id: data.execution_id || 'unknown'
        },
        ...data.contexts
      }
    };

    return await this.send(payload);
  }

  // Track error
  async trackError(error, data = {}) {
    const payload = {
      event_id: this._generateId(),
      timestamp: Date.now() / 1000,
      platform: 'node',
      environment: this.environment,
      release: this.release,
      exception: {
        values: [{
          type: error.name || 'Error',
          value: error.message || String(error),
          stacktrace: {
            frames: this._parseStackTrace(error.stack)
          }
        }]
      },
      level: 'error',
      tags: {
        processor_id: data.processor_id || 'unknown',
        error_type: data.error_type || 'unknown',
        ...data.tags
      },
      extra: data.extra || {},
      contexts: data.contexts || {}
    };

    return await this.send(payload);
  }

  // Start performance transaction
  startTransaction(name, op = 'workflow') {
    const traceId = this._generateId();
    const spanId = this._generateId().substring(0, 16);

    return {
      traceId,
      spanId,
      startTime: Date.now(),
      name,
      op,

      // Finish transaction
      finish: async (status = 'ok', data = {}) => {
        const duration = (Date.now() - this.startTime) / 1000;

        const payload = {
          event_id: this._generateId(),
          timestamp: Date.now() / 1000,
          start_timestamp: this.startTime / 1000,
          platform: 'node',
          environment: this.environment,
          release: this.release,
          type: 'transaction',
          transaction: name,
          contexts: {
            trace: {
              trace_id: traceId,
              span_id: spanId,
              op,
              status
            },
            ...data.contexts
          },
          tags: data.tags || {},
          measurements: {
            duration: { value: duration, unit: 'second' },
            ...data.measurements
          }
        };

        return await this.send(payload);
      }
    };
  }

  // Generate random ID
  _generateId() {
    return 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'.replace(/x/g, () =>
      Math.floor(Math.random() * 16).toString(16)
    );
  }

  // Parse stack trace
  _parseStackTrace(stack) {
    if (!stack) return [];

    return stack.split('\n').slice(1).map(line => {
      const match = line.match(/at (.+) \((.+):(\d+):(\d+)\)/);
      if (match) {
        return {
          function: match[1],
          filename: match[2],
          lineno: parseInt(match[3]),
          colno: parseInt(match[4])
        };
      }
      return { function: line.trim() };
    });
  }
}

// Initialize tracker
const sentry = new SentryTracker(SENTRY_DSN, {
  environment: ENVIRONMENT,
  release: RELEASE
});

// Export for use in workflow
return [{
  json: {
    sentry,
    initialized: true,
    dsn: SENTRY_DSN
  }
}];
```

---

## 📊 Custom Event Tracking Examples

### Event 1: Workflow Started

```javascript
// At the start of your workflow
const sentry = $('Sentry Helper').item.json.sentry;
const processorId = $json.processor_id || 'processor-1';

await sentry.trackEvent('workflow_started', {
  processor_id: processorId,
  tags: {
    processor_id: processorId,
    workflow_version: '1.0'
  },
  extra: {
    total_rows: $json.total_rows || 0,
    start_time: new Date().toISOString()
  }
});

return $input.all();
```

### Event 2: Batch Started

```javascript
const sentry = $('Sentry Helper').item.json.sentry;
const processorId = $json.processor_id;
const batchSize = $json.batch_size;

await sentry.trackEvent('batch_started', {
  processor_id: processorId,
  tags: {
    processor_id: processorId,
    batch_size: String(batchSize)
  },
  extra: {
    batch_number: $json.batch_number,
    start_row: $json.start_row,
    end_row: $json.end_row
  }
});

return $input.all();
```

### Event 3: Gemini API Call (with Performance Tracking)

```javascript
const sentry = $('Sentry Helper').item.json.sentry;
const processorId = $json.processor_id;

// Start transaction
const transaction = sentry.startTransaction('gemini_api_call', 'http.client');

try {
  const startTime = Date.now();

  // Your Gemini API call here
  const response = await fetch('https://generativelanguage.googleapis.com/...', {
    method: 'POST',
    headers: { /* ... */ },
    body: JSON.stringify({ /* ... */ })
  });

  const duration = Date.now() - startTime;
  const result = await response.json();

  // Track event
  await sentry.trackEvent('gemini_api_call', {
    processor_id: processorId,
    tags: {
      processor_id: processorId,
      status: response.ok ? 'success' : 'error',
      http_status: String(response.status)
    },
    extra: {
      duration_ms: duration,
      tokens_used: result.usageMetadata?.totalTokenCount || 0,
      model: 'gemini-1.5-flash'
    }
  });

  // Finish transaction
  await transaction.finish('ok', {
    measurements: {
      'api.response_time': { value: duration / 1000, unit: 'second' },
      'api.tokens_used': { value: result.usageMetadata?.totalTokenCount || 0, unit: 'none' }
    }
  });

  return [{ json: result }];

} catch (error) {
  // Track error
  await sentry.trackError(error, {
    processor_id: processorId,
    error_type: 'gemini_api_error',
    tags: {
      processor_id: processorId,
      api: 'gemini'
    },
    extra: {
      request_details: $json
    }
  });

  await transaction.finish('error');
  throw error;
}
```

### Event 4: Batch Completed

```javascript
const sentry = $('Sentry Helper').item.json.sentry;
const processorId = $json.processor_id;

await sentry.trackEvent('batch_completed', {
  processor_id: processorId,
  tags: {
    processor_id: processorId,
    success_rate: String(Math.round(($json.success_count / $json.rows_processed) * 100))
  },
  extra: {
    rows_processed: $json.rows_processed,
    success_count: $json.success_count,
    error_count: $json.error_count,
    duration_seconds: $json.duration_seconds
  }
});

return $input.all();
```

### Event 5: Milestone Reached

```javascript
const sentry = $('Sentry Helper').item.json.sentry;
const milestoneNumber = $json.milestone_number;
const totalCompleted = $json.total_completed;

await sentry.trackEvent('milestone_reached', {
  tags: {
    milestone: String(milestoneNumber),
    total_completed: String(totalCompleted)
  },
  extra: {
    milestone_number: milestoneNumber,
    total_completed: totalCompleted,
    timestamp: new Date().toISOString(),
    processors_active: $json.processors_active || 1
  }
});

return $input.all();
```

### Event 6: Error Occurred

```javascript
const sentry = $('Sentry Helper').item.json.sentry;
const error = $json.error;
const processorId = $json.processor_id;

await sentry.trackError(new Error(error.message), {
  processor_id: processorId,
  error_type: error.type || 'workflow_error',
  tags: {
    processor_id: processorId,
    error_type: error.type,
    severity: error.severity || 'medium'
  },
  extra: {
    error_details: error,
    context: $json.context || {},
    row_data: $json.row_data || null
  }
});

return $input.all();
```

### Event 7: Workflow Completed

```javascript
const sentry = $('Sentry Helper').item.json.sentry;

await sentry.trackEvent('workflow_completed', {
  tags: {
    status: 'success',
    total_processed: String($json.total_processed)
  },
  extra: {
    total_processed: $json.total_processed,
    duration_minutes: $json.duration_minutes,
    success_rate: $json.success_rate,
    errors_encountered: $json.errors_encountered,
    end_time: new Date().toISOString()
  }
});

return $input.all();
```

---

## 🎯 Performance Monitoring Setup

### Key Performance Metrics to Track

Add this code to your monitoring node:

```javascript
const sentry = $('Sentry Helper').item.json.sentry;
const metrics = $json.metrics;

// Send custom measurements
await sentry.trackEvent('performance_metrics', {
  tags: {
    metric_type: 'performance_summary'
  },
  extra: {
    avg_batch_time: metrics.avg_batch_time,
    avg_gemini_response: metrics.avg_gemini_response,
    avg_sheets_update: metrics.avg_sheets_update,
    success_rate: metrics.success_rate
  },
  contexts: {
    performance: {
      batch_processing: {
        average_seconds: metrics.avg_batch_time,
        target_seconds: 60,
        meets_target: metrics.avg_batch_time < 60
      },
      gemini_api: {
        average_seconds: metrics.avg_gemini_response,
        target_seconds: 30,
        meets_target: metrics.avg_gemini_response < 30
      },
      sheets_api: {
        average_seconds: metrics.avg_sheets_update,
        target_seconds: 5,
        meets_target: metrics.avg_sheets_update < 5
      },
      overall: {
        success_rate_percent: metrics.success_rate,
        target_percent: 95,
        meets_target: metrics.success_rate > 95
      }
    }
  }
});
```

---

## 🔍 Getting Your DSN

After creating the project in Sentry:

1. Go to **Settings** → **Projects** → **nfp-website-finder**
2. Click **Client Keys (DSN)**
3. Copy the **DSN** value
4. Replace `YOUR_DSN_HERE` in the Sentry Helper code above

**Your DSN will look like:**
```
https://abc123def456@oxfordshire-inc.ingest.us.sentry.io/123456
```

---

## 📈 Viewing Data in Sentry

### Issues Tab
- View all errors and exceptions
- Filter by processor_id
- See stack traces and context

### Performance Tab
- View transaction timings
- See Gemini API performance
- Track batch processing times

### Custom Events
Go to **Discover** → **Build Query**:
```sql
event.type:transaction AND tags[event_type]:workflow_started
```

### Create Alerts

1. **Go to Alerts** → **Create Alert**
2. **Alert Type:** Issues or Metrics
3. **Conditions:**
   - Error rate > 5% in 1 hour
   - Average batch time > 90 seconds
   - Success rate < 90%

---

## 🚀 Quick Start Checklist

- [ ] Create Sentry project `nfp-website-finder`
- [ ] Copy DSN from project settings
- [ ] Add Sentry Helper node to n8n workflow
- [ ] Replace `YOUR_DSN_HERE` with actual DSN
- [ ] Add event tracking nodes throughout workflow
- [ ] Test with a small batch
- [ ] Verify events appear in Sentry
- [ ] Set up alerts for critical metrics
- [ ] Monitor dashboard regularly

---

## 💡 Best Practices

1. **Always wrap API calls in try/catch** and track errors
2. **Track performance for slow operations** (>5 seconds)
3. **Use consistent processor_id** across all events
4. **Add context data** to help debugging
5. **Set up alerts** for critical failures
6. **Review Sentry weekly** to identify trends

---

## 🆘 Troubleshooting

**Events not appearing?**
- Check DSN is correct
- Verify network connectivity from n8n
- Check Sentry project is active

**Too many events?**
- Use sampling: Only track 10% of batch_completed events
- Focus on errors and milestones

**Performance impact?**
- Sentry calls are async and non-blocking
- Failed Sentry calls won't break workflow
- Consider using background tracking

---

**Need help?** Check Sentry docs: https://docs.sentry.io/platforms/javascript/guides/node/
