-- =============================================================================
-- Step 2 - Gateway specification: model allowlist + logging
-- Feature: Model access control, Observability (trace logging)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

-- Snapshot the current spec first (copy the output somewhere safe)
DESCRIBE AI GATEWAY SNOWFLAKE;

-- Expose only approved models and enable trace logging.
-- Model names must be available in your region - adjust to your account.
ALTER AI GATEWAY SNOWFLAKE FROM SPECIFICATION $$
schema_version: 1
models:
  - name: claude-sonnet-4-6
  - name: claude-haiku-4-5
  - name: openai-gpt-5
  - name: llama4-maverick
logging:
  enabled: true                 # required for traces in AGENT_TRACE_TABLE
  capture_payload:
    request_response: false     # true = prompts/responses are stored (sensitive data!)
$$;

-- Verify
DESCRIBE AI GATEWAY SNOWFLAKE;

-- Alternative: expose every model available in the account
-- models:
--   - name: '*'
