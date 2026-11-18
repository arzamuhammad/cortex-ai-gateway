-- =============================================================================
-- Step 0 - Prerequisites & discovery
-- Role: ACCOUNTADMIN (or a role with privileges to manage the AI gateway)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

-- Cortex AI Gateway (Preview) is available in supported AWS commercial regions.
SELECT CURRENT_REGION(), CURRENT_ACCOUNT();

-- Every account has exactly one gateway named SNOWFLAKE (nothing to CREATE).
-- Note the BASE_URL column: this is the endpoint every client will use.
SHOW AI GATEWAYS;

-- Inspect the current specification and SAVE A COPY before changing it.
-- ALTER ... FROM SPECIFICATION replaces the WHOLE spec, not individual fields.
DESCRIBE AI GATEWAY SNOWFLAKE;
