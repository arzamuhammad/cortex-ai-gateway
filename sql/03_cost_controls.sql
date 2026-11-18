-- =============================================================================
-- Step 3 - Cost governance: tags, budget (showback) and quota (hard limit)
-- Feature: Cost tracking, Budgets, Per-user quotas
-- =============================================================================
USE ROLE ACCOUNTADMIN;
USE SCHEMA AI_GATEWAY_LAB.GOVERNANCE;
USE WAREHOUSE AI_GATEWAY_WH;

-- 3.1 Cost-center tag -> attribute AI spend to teams / applications
CREATE TAG IF NOT EXISTS COST_CENTER COMMENT = 'Cost center for AI spend attribution';
ALTER USER SVC_CHATBOT_APP SET TAG AI_GATEWAY_LAB.GOVERNANCE.COST_CENTER = 'customer_service';
-- ALTER USER <developer_user> SET TAG AI_GATEWAY_LAB.GOVERNANCE.COST_CENTER = 'engineering';

-- 3.2 QUOTA = brake. Blocks requests once a user reaches the limit.
-- IMPORTANT: a new quota applies to all users -> scope it with a tag FIRST.
CREATE SNOWFLAKE.CORE.QUOTA IF NOT EXISTS GATEWAY_ENGINEERING_QUOTA();

CALL GATEWAY_ENGINEERING_QUOTA!SET_USER_TAGS(
  [[(SELECT SYSTEM$REFERENCE('TAG', 'AI_GATEWAY_LAB.GOVERNANCE.COST_CENTER', 'SESSION', 'APPLYBUDGET')),
    'engineering']],
  'UNION');
CALL GATEWAY_ENGINEERING_QUOTA!ADD_SHARED_RESOURCE('AI GATEWAY');
CALL GATEWAY_ENGINEERING_QUOTA!SET_PER_USER_LIMIT(5, 'DAILY');          -- 5 credits/user/day
CALL GATEWAY_ENGINEERING_QUOTA!SET_BLOCK_ENFORCEMENT_ENABLED(TRUE, FALSE);

-- 3.3 BUDGET = showback + notification (does not block)
CREATE SNOWFLAKE.CORE.BUDGET IF NOT EXISTS GATEWAY_MONTHLY_BUDGET();
CALL GATEWAY_MONTHLY_BUDGET!ADD_SHARED_RESOURCE('AI GATEWAY');
CALL GATEWAY_MONTHLY_BUDGET!SET_SPENDING_LIMIT(500);                     -- credits / month
-- CALL GATEWAY_MONTHLY_BUDGET!SET_EMAIL_NOTIFICATIONS('<email_integration>', 'finops@company.com');

-- Notes
--  * Quota enforcement happens within minutes; small overshoot is possible.
--  * Budgets are evaluated periodically and are meant for reporting/alerting.
