#!/bin/bash
# Claude Code Remote Command Polling Script
# This script checks for new commands from Slack via Supabase

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Function to check for pending commands
check_for_commands() {
    # Query Supabase for pending commands
    local response=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/claude_commands?status=eq.pending&order=created_at.asc&limit=1" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json")

    # Check if we got any commands
    local count=$(echo "$response" | jq '. | length')

    if [ "$count" -gt 0 ]; then
        # Extract command details
        local command_id=$(echo "$response" | jq -r '.[0].id')
        local command=$(echo "$response" | jq -r '.[0].command')
        local source=$(echo "$response" | jq -r '.[0].source')
        local user_id=$(echo "$response" | jq -r '.[0].user_id')
        local slack_channel_id=$(echo "$response" | jq -r '.[0].slack_channel_id // ""')
        local slack_thread_ts=$(echo "$response" | jq -r '.[0].slack_thread_ts // ""')

        echo "📬 New command received!"
        echo "   ID: $command_id"
        echo "   Command: $command"
        echo "   Source: $source"
        echo "   User: $user_id"
        echo "   Channel: $slack_channel_id"

        # Return: command_id|command|slack_channel_id|slack_thread_ts
        echo "$command_id|$command|$slack_channel_id|$slack_thread_ts"
    else
        echo "   No pending commands"
        return 1
    fi
}

# If run directly, just check once
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "🔍 Checking for new commands..."
    check_for_commands
fi
