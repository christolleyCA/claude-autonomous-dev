# N8n + Sentry Integration Guide

This guide shows how to add real-time Sentry monitoring to your N8n workflows for both testing and production.

## Why Use Sentry in N8n?

- **Real-time error alerts** when workflows fail
- **Performance monitoring** of workflow execution times
- **Contextual debugging** with workflow state captured
- **Production visibility** without checking N8n UI
- **Trend analysis** of workflow failures over time

## Integration Methods

### Method 1: HTTP Request Node (Recommended - No Dependencies)

Add Sentry error tracking to any workflow using the HTTP Request node:

```json
{
  "name": "Report Error to Sentry",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "url": "https://sentry.io/api/0/projects/YOUR_ORG/YOUR_PROJECT/events/",
    "method": "POST",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "Authorization",
          "value": "Bearer YOUR_SENTRY_AUTH_TOKEN"
        },
        {
          "name": "Content-Type",
          "value": "application/json"
        }
      ]
    },
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={{ {\n  \"message\": $json.error.message || \"Workflow Error\",\n  \"level\": \"error\",\n  \"tags\": {\n    \"workflow\": \"{{$workflow.name}}\",\n    \"execution_id\": \"{{$execution.id}}\",\n    \"environment\": \"production\"\n  },\n  \"extra\": {\n    \"node_name\": $json.nodeName,\n    \"error_details\": $json.error,\n    \"timestamp\": \"{{new Date().toISOString()}}\"\n  }\n} }}"
  }
}
```

### Method 2: Sentry DSN Method (Simpler)

Use Sentry's ingest API directly with your DSN:

```json
{
  "name": "Send to Sentry via DSN",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "url": "https://YOUR_KEY@oXXXXXX.ingest.sentry.io/api/YOUR_PROJECT_ID/store/",
    "method": "POST",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "Content-Type",
          "value": "application/json"
        },
        {
          "name": "X-Sentry-Auth",
          "value": "Sentry sentry_version=7, sentry_key=YOUR_KEY"
        }
      ]
    },
    "sendBody": true,
    "specifyBody": "json",
    "jsonBody": "={{ {\n  \"message\": \"N8n Workflow Error: \" + ($json.error?.message || \"Unknown error\"),\n  \"level\": \"error\",\n  \"platform\": \"node\",\n  \"tags\": {\n    \"workflow\": \"{{$workflow.name}}\",\n    \"workflow_id\": \"{{$workflow.id}}\",\n    \"execution_id\": \"{{$execution.id}}\",\n    \"environment\": \"production\"\n  },\n  \"contexts\": {\n    \"workflow\": {\n      \"name\": \"{{$workflow.name}}\",\n      \"active\": \"{{$workflow.active}}\",\n      \"execution_mode\": \"{{$execution.mode}}\"\n    }\n  },\n  \"extra\": $json\n} }}"
  }
}
```

### Method 3: Error Workflow (Automatic on Failures)

N8n allows you to configure an "Error Workflow" that triggers automatically when any workflow fails:

1. Create a dedicated error-handling workflow
2. Set it as the Error Workflow in N8n settings
3. It receives the error context automatically

Example Error Workflow:

```json
{
  "name": "[SYSTEM] Global Error Handler with Sentry",
  "nodes": [
    {
      "parameters": {},
      "name": "Error Trigger",
      "type": "n8n-nodes-base.errorTrigger",
      "position": [250, 300]
    },
    {
      "parameters": {
        "jsCode": "// Format error for Sentry\nconst error = $input.first().json;\nconst workflowError = error.error;\n\nreturn [{\n  json: {\n    message: `Workflow Failed: ${error.workflow.name}`,\n    level: \"error\",\n    platform: \"node\",\n    tags: {\n      workflow_name: error.workflow.name,\n      workflow_id: error.workflow.id,\n      execution_id: error.execution.id,\n      environment: \"production\",\n      mode: error.execution.mode\n    },\n    contexts: {\n      workflow: {\n        name: error.workflow.name,\n        active: error.workflow.active\n      },\n      execution: {\n        id: error.execution.id,\n        mode: error.execution.mode,\n        startedAt: error.execution.startedAt\n      }\n    },\n    extra: {\n      error_message: workflowError.message,\n      error_stack: workflowError.stack,\n      node_name: workflowError.node?.name,\n      node_type: workflowError.node?.type,\n      raw_error: error\n    }\n  }\n}];"
      },
      "name": "Format Sentry Event",
      "type": "n8n-nodes-base.code",
      "position": [450, 300]
    },
    {
      "parameters": {
        "url": "https://YOUR_KEY@oXXXXXX.ingest.sentry.io/api/YOUR_PROJECT_ID/store/",
        "method": "POST",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {
              "name": "Content-Type",
              "value": "application/json"
            },
            {
              "name": "X-Sentry-Auth",
              "value": "Sentry sentry_version=7, sentry_key=YOUR_KEY"
            }
          ]
        },
        "sendBody": true,
        "specifyBody": "json",
        "jsonBody": "={{$json}}"
      },
      "name": "Send to Sentry",
      "type": "n8n-nodes-base.httpRequest",
      "position": [650, 300]
    },
    {
      "parameters": {
        "message": "=🚨 Workflow Error Sent to Sentry\n\nWorkflow: {{$node[\"Error Trigger\"].json.workflow.name}}\nExecution ID: {{$node[\"Error Trigger\"].json.execution.id}}\nError: {{$node[\"Error Trigger\"].json.error.message}}"
      },
      "name": "Log to Console",
      "type": "n8n-nodes-base.noOp",
      "position": [850, 300]
    }
  ],
  "connections": {
    "Error Trigger": {
      "main": [[{"node": "Format Sentry Event", "type": "main", "index": 0}]]
    },
    "Format Sentry Event": {
      "main": [[{"node": "Send to Sentry", "type": "main", "index": 0}]]
    },
    "Send to Sentry": {
      "main": [[{"node": "Log to Console", "type": "main", "index": 0}]]
    }
  }
}
```

## Method 4: Performance Monitoring

Track workflow execution times and success rates:

```json
{
  "name": "Track Performance in Sentry",
  "type": "n8n-nodes-base.code",
  "parameters": {
    "jsCode": "const startTime = $node[\"Start\"].json.timestamp;\nconst endTime = Date.now();\nconst duration = endTime - startTime;\n\n// Send performance metric to Sentry\nreturn [{\n  json: {\n    message: `Workflow Performance: ${$workflow.name}`,\n    level: \"info\",\n    tags: {\n      workflow: $workflow.name,\n      environment: \"production\"\n    },\n    extra: {\n      execution_time_ms: duration,\n      success: true\n    },\n    measurements: {\n      duration: {\n        value: duration,\n        unit: \"millisecond\"\n      }\n    }\n  }\n}];"
  }
}
```

## Setup Instructions

### 1. Get Sentry Credentials

From your Sentry project:
- Go to Settings → Projects → [Your Project]
- Copy the DSN: `https://xxxxx@oXXXXX.ingest.sentry.io/XXXXXX`
- Or create an Auth Token in Settings → Account → API → Auth Tokens

### 2. Add to N8n Workflow

Insert Sentry nodes:
- **After edge function calls** (to track failures)
- **In error paths** (to catch validation errors)
- **At workflow end** (for performance tracking)

### 3. Configure Error Workflow (Recommended)

1. Create the Global Error Handler workflow above
2. Save and activate it
3. Go to Settings → Error Workflows
4. Select your error handler workflow
5. All workflow failures will now automatically report to Sentry

### 4. Testing

Test your integration:
```bash
# Trigger a test error
curl -X POST "https://n8n.grantpilot.app/webhook/your-test-workflow" \
  -H "Content-Type: application/json" \
  -d '{"trigger_error": true}'
```

Check Sentry dashboard - you should see the error within seconds!

## Best Practices

1. **Use Error Workflows for Global Monitoring**
   - Set up one error workflow to catch all failures
   - Reduces duplicate Sentry nodes in every workflow

2. **Tag Everything**
   - Add workflow name, execution ID, environment
   - Makes filtering in Sentry much easier

3. **Don't Over-Report**
   - Don't send validation errors (expected user errors)
   - Only track unexpected failures
   - Use sampling in high-traffic workflows

4. **Performance Tracking**
   - Track slow workflows (>5 seconds)
   - Monitor edge function call times
   - Set up alerts for degraded performance

5. **Environment Separation**
   - Use different Sentry projects for dev/prod
   - Tag with environment: "development", "staging", "production"

## Real-World Example

Here's how the `build-feature.sh` will integrate Sentry into generated N8n workflows:

```json
{
  "name": "[ACTIVE] [my-feature] Part 1 - Main Orchestrator",
  "nodes": [
    {
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook"
    },
    {
      "name": "Call Edge Function",
      "type": "n8n-nodes-base.httpRequest"
    },
    {
      "name": "Format Success Response",
      "type": "n8n-nodes-base.code"
    },
    {
      "name": "Track Success in Sentry",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://YOUR_DSN/api/YOUR_PROJECT_ID/store/",
        "sendBody": true,
        "jsonBody": "={{ {\n  \"message\": \"Workflow Success: {{$workflow.name}}\",\n  \"level\": \"info\",\n  \"tags\": { \"workflow\": \"{{$workflow.name}}\" }\n} }}"
      }
    },
    {
      "name": "Respond to Webhook",
      "type": "n8n-nodes-base.respondToWebhook"
    }
  ],
  "connections": {
    "Call Edge Function": {
      "main": [[{"node": "Format Success Response"}]],
      "error": [[{"node": "Report Error to Sentry"}]]
    },
    "Format Success Response": {
      "main": [[{"node": "Track Success in Sentry"}]]
    },
    "Track Success in Sentry": {
      "main": [[{"node": "Respond to Webhook"}]]
    }
  }
}
```

## Benefits for Testing

When testing workflows:
1. See errors in real-time in Sentry dashboard
2. Get full context (workflow state, inputs, node that failed)
3. Track performance degradation during load testing
4. Historical view of all test runs

## Benefits for Production

1. **Instant Alerts**: Get notified when workflows fail
2. **Debugging Context**: Full workflow state captured
3. **Trend Analysis**: See failure patterns over time
4. **Performance Monitoring**: Track slow workflows
5. **No N8n UI Required**: Monitor from anywhere

## Next Steps

1. ✅ Create Sentry project
2. ✅ Set up Global Error Workflow
3. ✅ Add performance tracking to critical workflows
4. ✅ Configure Slack/email alerts in Sentry
5. ✅ Update `build-feature.sh` to auto-add Sentry nodes
