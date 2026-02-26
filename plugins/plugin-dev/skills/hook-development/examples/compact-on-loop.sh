#!/bin/bash
# Autonomous Context Management Example
# This script demonstrates how to autonomously trigger context compaction
# after a certain number of iterations in a loop.

set -euo pipefail

# Use session_id for a stable state file path across hook calls in the same session
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')
STATE_FILE="/tmp/hook-iteration-count-$SESSION_ID"

# Read current count
COUNT=$(cat "$STATE_FILE" 2>/dev/null || echo "0")
NEW_COUNT=$((COUNT + 1))

# Save new count
echo "$NEW_COUNT" > "$STATE_FILE"

# Threshold for compaction
THRESHOLD=20

if [ "$NEW_COUNT" -ge "$THRESHOLD" ]; then
  # Reset count and request compaction
  echo "0" > "$STATE_FILE"
  
  # Return JSON with compactContext: true
  # This tells Claude Code to compact the context window now
  cat <<EOF
{
  "decision": "block",
  "reason": "Autonomous loop iteration $NEW_COUNT. Triggering context compaction to maintain performance.",
  "systemMessage": "Loop iteration threshold reached. Compacting context window.",
  "compactContext": true
}
EOF
else
  # Just continue the loop
  cat <<EOF
{
  "decision": "block",
  "reason": "Autonomous loop iteration $NEW_COUNT. Continuing...",
  "compactContext": false
}
EOF
fi

exit 0
