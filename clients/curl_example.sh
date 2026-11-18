#!/usr/bin/env bash
# Step 5c - Raw HTTP calls to Cortex AI Gateway
# export SNOWFLAKE_AI_GATEWAY_URL="<BASE_URL from SHOW AI GATEWAYS>"
# export SNOWFLAKE_PAT="<programmatic access token>"
set -euo pipefail
: "${SNOWFLAKE_AI_GATEWAY_URL:?set SNOWFLAKE_AI_GATEWAY_URL}"
: "${SNOWFLAKE_PAT:?set SNOWFLAKE_PAT}"
URL="${SNOWFLAKE_AI_GATEWAY_URL%/}"

echo "== OpenAI-compatible /v1/chat/completions =="
curl -sS "$URL/v1/chat/completions" \
  -H "Authorization: Bearer $SNOWFLAKE_PAT" \
  -H "Content-Type: application/json" \
  -d '{"model":"openai-gpt-5","messages":[{"role":"user","content":"Hello from curl"}],"max_tokens":100}'
echo

echo "== Anthropic-compatible /v1/messages =="
curl -sS "$URL/v1/messages" \
  -H "Authorization: Bearer $SNOWFLAKE_PAT" \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{"model":"claude-haiku-4-5","max_tokens":100,"messages":[{"role":"user","content":"Hello from curl"}]}'
echo
