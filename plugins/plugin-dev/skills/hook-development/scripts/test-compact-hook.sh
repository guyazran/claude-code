#!/bin/bash
# Test Autonomous Context Management Hook
# Verifies that the compact-on-loop.sh hook correctly triggers context compaction.

set -euo pipefail

HOOK_SCRIPT="${CLAUDE_PLUGIN_ROOT}/skills/hook-development/examples/compact-on-loop.sh"
SESSION_ID="test-session-$$"
STATE_FILE="/tmp/hook-iteration-count-$SESSION_ID"

# Ensure script is executable
chmod +x "$HOOK_SCRIPT"

# Cleanup on exit
trap 'rm -f "$STATE_FILE" output.json' EXIT

echo "🧪 Testing Autonomous Context Management Hook"
echo "-------------------------------------------"

# Test Case 1: Initial call (count=1)
echo "Test Case 1: Initial call"
echo "{\"hook_event_name\": \"Stop\", \"session_id\": \"$SESSION_ID\"}" | "$HOOK_SCRIPT" > output.json
if jq -e '.compactContext == false' output.json >/dev/null; then
  echo "✅ Pass: compactContext is false for initial call"
else
  echo "❌ Fail: compactContext should be false"
  cat output.json
  exit 1
fi

# Test Case 2: Just before threshold (count=19)
echo "Test Case 2: Just before threshold"
echo "18" > "$STATE_FILE"
echo "{\"hook_event_name\": \"Stop\", \"session_id\": \"$SESSION_ID\"}" | "$HOOK_SCRIPT" > output.json
if jq -e '.compactContext == false' output.json >/dev/null; then
  echo "✅ Pass: compactContext is false at iteration 19"
else
  echo "❌ Fail: compactContext should still be false"
  cat output.json
  exit 1
fi

# Test Case 3: Reaching threshold (count=20)
echo "Test Case 3: Reaching threshold"
echo "19" > "$STATE_FILE"
echo "{\"hook_event_name\": \"Stop\", \"session_id\": \"$SESSION_ID\"}" | "$HOOK_SCRIPT" > output.json
if jq -e '.compactContext == true' output.json >/dev/null; then
  echo "✅ Pass: compactContext is true at iteration 20"
else
  echo "❌ Fail: compactContext should be true"
  cat output.json
  exit 1
fi

# Test Case 4: After reset (count=1 again)
echo "Test Case 4: After reset"
echo "{\"hook_event_name\": \"Stop\", \"session_id\": \"$SESSION_ID\"}" | "$HOOK_SCRIPT" > output.json
if jq -e '.compactContext == false' output.json >/dev/null; then
  echo "✅ Pass: compactContext reset to false after threshold"
else
  echo "❌ Fail: compactContext should be false after reset"
  cat output.json
  exit 1
fi

rm output.json
echo "-------------------------------------------"
echo "✅ All test cases passed!"
exit 0
