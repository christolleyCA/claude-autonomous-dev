#!/bin/bash
# Claude Code Response Writer
# Writes command responses back to Supabase

SUPABASE_URL="https://hjtvtkffpziopozmtsnb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdHZ0a2ZmcHppb3Bvem10c25iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNDg0MjMsImV4cCI6MjA3NDcyNDQyM30.Hxk42onTYrmjdWbuEqaFTbQszSuoRVYjl8DwDf3INho"

# Function to update command status to processing
mark_processing() {
    local command_id=$1

    curl -s -X PATCH \
        "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.${command_id}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{\"status\": \"processing\"}"

    echo "✏️  Marked command $command_id as processing"
}

# Function to write successful response
write_response() {
    local command_id=$1
    local response=$2

    # Escape the response for JSON
    local escaped_response=$(echo "$response" | jq -Rs .)

    curl -s -X PATCH \
        "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.${command_id}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{\"status\": \"completed\", \"response\": ${escaped_response}, \"processed_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")\"}"

    echo "✅ Response written for command $command_id"
}

# Function to write error
write_error() {
    local command_id=$1
    local error_message=$2

    # Escape the error message for JSON
    local escaped_error=$(echo "$error_message" | jq -Rs .)

    curl -s -X PATCH \
        "${SUPABASE_URL}/rest/v1/claude_commands?id=eq.${command_id}" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{\"status\": \"error\", \"error_message\": ${escaped_error}, \"processed_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")\"}"

    echo "❌ Error written for command $command_id"
}

# If run directly with arguments
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <command_id> <response|error> [message]"
        echo "Examples:"
        echo "  $0 abc123 response 'Command executed successfully'"
        echo "  $0 abc123 error 'Command failed: invalid syntax'"
        exit 1
    fi

    command_id=$1
    action=$2
    message=$3

    case $action in
        "processing")
            mark_processing "$command_id"
            ;;
        "response")
            write_response "$command_id" "$message"
            ;;
        "error")
            write_error "$command_id" "$message"
            ;;
        *)
            echo "Unknown action: $action"
            echo "Valid actions: processing, response, error"
            exit 1
            ;;
    esac
fi
