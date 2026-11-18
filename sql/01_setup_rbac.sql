-- =============================================================================
-- Step 1 - Access control (RBAC)
-- Feature: Security / centralized identity (no provider API keys on clients)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

-- Lab objects (database for tags, warehouse for queries)
CREATE DATABASE  IF NOT EXISTS AI_GATEWAY_LAB;
CREATE SCHEMA    IF NOT EXISTS AI_GATEWAY_LAB.GOVERNANCE;
CREATE WAREHOUSE IF NOT EXISTS AI_GATEWAY_WH WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60;

-- Persona 1: developers / applications that send inference requests
CREATE ROLE IF NOT EXISTS AI_APP_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE AI_APP_ROLE;
GRANT USAGE ON AI GATEWAY SNOWFLAKE        TO ROLE AI_APP_ROLE;
GRANT USAGE ON WAREHOUSE AI_GATEWAY_WH     TO ROLE AI_APP_ROLE;

-- Persona 2: FinOps / Security / Platform team that reads ALL traces and usage
CREATE ROLE IF NOT EXISTS AI_MONITOR_ROLE;
GRANT MONITOR ON AI GATEWAY SNOWFLAKE      TO ROLE AI_MONITOR_ROLE;
GRANT USAGE ON WAREHOUSE AI_GATEWAY_WH     TO ROLE AI_MONITOR_ROLE;
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE AI_MONITOR_ROLE; -- ACCOUNT_USAGE views

-- One SERVICE user per application = cost attribution per application
CREATE USER IF NOT EXISTS SVC_CHATBOT_APP
  TYPE = SERVICE
  DEFAULT_ROLE = AI_APP_ROLE
  COMMENT = 'Customer-service chatbot calling Cortex AI Gateway';
GRANT ROLE AI_APP_ROLE TO USER SVC_CHATBOT_APP;

-- Programmatic access token (PAT) used as the Bearer token by the app.
-- Copy the token value from the output - it is shown only once.
-- (A network policy on the service user is recommended for PAT usage.)
ALTER USER SVC_CHATBOT_APP ADD PROGRAMMATIC ACCESS TOKEN chatbot_pat
  ROLE_RESTRICTION = 'AI_APP_ROLE'
  DAYS_TO_EXPIRY = 30;

-- Grant human users
-- GRANT ROLE AI_APP_ROLE     TO USER <developer_user>;
-- GRANT ROLE AI_MONITOR_ROLE TO USER <finops_user>;

-- By default USAGE on the gateway is granted to PUBLIC.
-- To restrict access, grant USAGE to the roles that need it FIRST, then:
-- REVOKE USAGE ON AI GATEWAY SNOWFLAKE FROM ROLE PUBLIC;   -- account-wide impact!
