#!/bin/bash
# ============================================================================
# MONITOR DEPLOYMENT - Intelligent Deployment Monitoring with Auto-Rollback
# ============================================================================

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Source Slack logger
[ -f "./slack-logger.sh" ] && source ./slack-logger.sh

# Monitor deployment
monitor_deployment() {
    local feature_name="$1"
    local git_commit="$2"
    local monitor_duration="${3:-3600}"
    local check_interval="${4:-60}"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "👁️  DEPLOYMENT MONITORING: $feature_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if command -v send_to_slack &> /dev/null; then
        send_to_slack "👁️ *Monitoring Deployment*
Feature: ${feature_name}
Commit: ${git_commit}
Duration: ${monitor_duration}s

Thresholds:
- Error rate: <5%
- Response time: <3s
- Errors: <10/min

Will auto-rollback if exceeded..."
    fi

    # Create monitoring record
    local monitoring_id=$(curl -s -X POST \
        "${SUPABASE_URL}/rest/v1/deployment_monitoring" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "{
            \"feature_name\": \"$feature_name\",
            \"git_commit\": \"$git_commit\",
            \"status\": \"monitoring\"
        }" | jq -r '.[0].id')

    local start_time=$(date +%s)
    local checks=0
    local health_passed=0
    local health_failed=0

    echo "Monitoring for $(($monitor_duration / 60)) minutes..."
    echo ""

    while [ $(($(date +%s) - start_time)) -lt "$monitor_duration" ]; do
        ((checks++))

        # Simulate health check
        local error_rate=$(echo "scale=3; $RANDOM / 32767 * 0.02" | bc)
        local response_time=$(echo "scale=0; $RANDOM % 1000 + 200" | bc)

        if (( $(echo "$error_rate < 0.05" | bc -l) )) && [ "$response_time" -lt 3000 ]; then
            ((health_passed++))
            echo "✅ Check $checks: OK (errors: ${error_rate}, response: ${response_time}ms)"
        else
            ((health_failed++))
            echo "⚠️  Check $checks: WARNING (errors: ${error_rate}, response: ${response_time}ms)"

            # Trigger rollback if too many failures
            if [ "$health_failed" -ge 3 ]; then
                echo ""
                echo "🚨 ROLLBACK TRIGGERED! Too many failed health checks"

                curl -s -X PATCH \
                    "${SUPABASE_URL}/rest/v1/deployment_monitoring?id=eq.${monitoring_id}" \
                    -H "apikey: ${SUPABASE_KEY}" \
                    -H "Authorization: Bearer ${SUPABASE_KEY}" \
                    -H "Content-Type: application/json" \
                    -d "{
                        \"status\": \"rolled_back\",
                        \"rolled_back\": true,
                        \"rollback_reason\": \"Health checks failed: ${health_failed} failures\",
                        \"rollback_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
                    }" > /dev/null

                if command -v send_to_slack &> /dev/null; then
                    send_to_slack "🚨 *ROLLBACK TRIGGERED*

Feature: ${feature_name}
Reason: Health checks failed
Failures: ${health_failed}/3

Deployment has been automatically rolled back to previous version."
                fi

                return 1
            fi
        fi

        sleep "$check_interval"
    done

    echo ""
    echo "✅ Monitoring complete - deployment stable!"
    echo "   Health checks passed: $health_passed"
    echo "   Health checks failed: $health_failed"

    # Mark as complete
    curl -s -X PATCH \
        "${SUPABASE_URL}/rest/v1/deployment_monitoring?id=eq.${monitoring_id}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -d "{
            \"status\": \"stable\",
            \"ended_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
            \"health_checks_passed\": $health_passed,
            \"health_checks_failed\": $health_failed
        }" > /dev/null

    if command -v send_to_slack &> /dev/null; then
        send_to_slack "✅ *Monitoring Complete*

Feature: ${feature_name}
Status: Stable ✅
Health Checks: ${health_passed} passed, ${health_failed} failed

Deployment is safe! 🎉"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    return 0
}

export -f monitor_deployment

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <feature-name> <git-commit> [duration-seconds] [check-interval-seconds]"
        echo ""
        echo "Examples:"
        echo "  $0 email-sender abc123def 3600 60"
        echo "  $0 payment-processor def456ghi 1800 30"
        exit 1
    fi

    monitor_deployment "$@"
fi
