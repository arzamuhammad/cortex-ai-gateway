-- =============================================================================
-- Teardown - remove lab objects. Restore your saved gateway spec manually.
-- =============================================================================
USE ROLE ACCOUNTADMIN;

DROP SNOWFLAKE.CORE.QUOTA  IF EXISTS AI_GATEWAY_LAB.GOVERNANCE.GATEWAY_ENGINEERING_QUOTA;
DROP SNOWFLAKE.CORE.BUDGET IF EXISTS AI_GATEWAY_LAB.GOVERNANCE.GATEWAY_MONTHLY_BUDGET;
ALTER USER IF EXISTS SVC_CHATBOT_APP REMOVE PROGRAMMATIC ACCESS TOKEN chatbot_pat;
DROP USER IF EXISTS SVC_CHATBOT_APP;
DROP ROLE IF EXISTS AI_APP_ROLE;
DROP ROLE IF EXISTS AI_MONITOR_ROLE;
DROP DATABASE IF EXISTS AI_GATEWAY_LAB;
DROP WAREHOUSE IF EXISTS AI_GATEWAY_WH;

-- Restore the gateway spec you saved in step 00/02:
-- ALTER AI GATEWAY SNOWFLAKE FROM SPECIFICATION $$ <saved spec> $$;
-- If you revoked USAGE from PUBLIC and want the default back:
-- GRANT USAGE ON AI GATEWAY SNOWFLAKE TO ROLE PUBLIC;
