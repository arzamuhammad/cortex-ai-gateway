-- =============================================================================
-- Step 4 - Observability: traces, spans, usage & cost
-- Feature: Agent traces (AGENT_TRACE_TABLE), usage history
-- Run AFTER sending a few requests (see clients/). Traces appear in ~1 minute.
-- =============================================================================
USE ROLE AI_MONITOR_ROLE;          -- MONITOR = all users' traces; USAGE = only your own
USE WAREHOUSE AI_GATEWAY_WH;

-- 4.1 Raw spans from the last 24 hours
SELECT timestamp,
       trace:"trace_id"::STRING                             AS trace_id,
       record:"name"::STRING                                AS span_name,
       resource_attributes:"user"::STRING                   AS user_name,
       record_attributes:"gen_ai.request.model"::STRING     AS model,
       record_attributes:"gen_ai.usage.input_tokens"::INT   AS input_tokens,
       record_attributes:"gen_ai.usage.output_tokens"::INT  AS output_tokens,
       record_attributes:"http.status_code"::STRING         AS http_status
FROM TABLE(AGENT_TRACE_TABLE('SNOWFLAKE'))
WHERE timestamp >= DATEADD('day', -1, CURRENT_TIMESTAMP())
ORDER BY timestamp DESC
LIMIT 100;

-- 4.2 Token usage per user and model
SELECT resource_attributes:"user"::STRING                         AS user_name,
       record_attributes:"gen_ai.request.model"::STRING           AS model,
       COUNT(*)                                                    AS requests,
       SUM(record_attributes:"gen_ai.usage.input_tokens"::INT)    AS input_tokens,
       SUM(record_attributes:"gen_ai.usage.output_tokens"::INT)   AS output_tokens
FROM TABLE(AGENT_TRACE_TABLE('SNOWFLAKE'))
WHERE timestamp >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY 1, 2
ORDER BY input_tokens DESC NULLS LAST;

-- 4.3 Errors and blocked requests (e.g. 403 not allowlisted, 429 quota)
SELECT record_attributes:"http.status_code"::STRING AS http_status, COUNT(*) AS cnt
FROM TABLE(AGENT_TRACE_TABLE('SNOWFLAKE'))
WHERE timestamp >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY 1 ORDER BY 2 DESC;

-- 4.4 Billing source of truth (has latency of a few hours)
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.AI_GATEWAY_USAGE_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

-- 4.5 Chargeback: credits per cost center (joins usage with user tags)
SELECT t.tag_value                AS cost_center,
       SUM(u.credits)             AS credits
FROM SNOWFLAKE.ACCOUNT_USAGE.AI_GATEWAY_USAGE_HISTORY u
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES t
       ON t.domain = 'USER'
      AND t.object_name = u.user_name
      AND t.tag_name = 'COST_CENTER'
WHERE u.start_time >= DATE_TRUNC('month', CURRENT_DATE())
GROUP BY 1 ORDER BY 2 DESC;

-- Column names of the usage view may evolve during Preview:
-- run DESCRIBE VIEW SNOWFLAKE.ACCOUNT_USAGE.AI_GATEWAY_USAGE_HISTORY to confirm.
-- Snowsight -> AI & ML -> AI Gateway also provides Observability / Cost dashboards.
