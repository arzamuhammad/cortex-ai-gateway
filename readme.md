# Cortex AI Gateway - Step-by-Step Implementation Tutorial

> 🇮🇩 Versi Bahasa Indonesia: [readme-ind.md](readme-ind.md)

A hands-on guide to governing every LLM and MCP call from your agents, apps and coding assistants through **Snowflake Cortex AI Gateway**.

> **Status:** Cortex AI Gateway is in **Preview** and is available in supported **AWS commercial regions**. Some capabilities described here are on the roadmap and are clearly marked. Always check the [official documentation](https://docs.snowflake.com/) before going to production.

---

## 1. Why Cortex AI Gateway?

Enterprises are moving fast from chatbots to **agents that act**: they run queries, read files, open tickets and post messages through LLMs and MCP (Model Context Protocol) tools. Every team picks its own model, its own SDK and its own API key, so access to AI is spread across many separate point-to-point connections:

```
WITHOUT A GATEWAY                         WITH CORTEX AI GATEWAY
Coding agent --key--> Provider A          Coding agent --+      +---------------------+ --> Provider A
App ----------key--> Provider B           App -----------+----> | CORTEX AI GATEWAY   | --> Provider B
AI agent -----key--> Provider C           AI agent ------+      | identity, models,   | --> Provider C
              key--> MCP tools                                  | cost, traces        | --> MCP tools
Keys, costs, logs scattered                                     +---------------------+
                                          One governed checkpoint inside your Snowflake account
```

Cortex AI Gateway is a **neutral control plane** in your Snowflake account. All AI clients go through it to reach models and tools.

- **Nothing to deploy.** Every account already has one gateway object named `SNOWFLAKE`.
- **Drop-in compatible.** It speaks the OpenAI (`/v1/chat/completions`) and Anthropic (`/v1/messages`) APIs, so to adopt it you only change `base_url`.
- **Your data, your traces.** Inference runs on Snowflake Cortex, and every request is recorded as a trace in **your** account (`AGENT_TRACE_TABLE`). Traces are governed by RBAC and can be joined with business data in SQL.
- **No price markup.** Inference is billed like Cortex inference.

## 2. Problems It Solves

| # | Problem | Without a gateway | With Cortex AI Gateway |
|---|---|---|---|
| 1 | **Runaway AI spend** | Bills from many vendors arrive late and can't be split by team. Overspend is noticed only after the budget is gone. | Cost per user, team and app in one place. Budgets alert you and per-user quotas **block** requests at the limit. |
| 2 | **API key sprawl** | Provider keys sit on laptops, `.env` files, repos and CI/CD, and must be rotated by hand. | No provider keys on clients. Users authenticate with their Snowflake identity (PAT, OAuth or SSO), and revoking a role removes access. |
| 3 | **Shadow AI and compliance** | Nobody can answer "what did the AI do with customer data?" | Every call is a trace in your account, queryable with SQL and protected by RBAC and masking. |
| 4 | **Unapproved models** | Anyone can call any model. | A **model allowlist** in the gateway spec controls which models can be called. |
| 5 | **Uncontrolled tools (MCP)** | Agents connect to any MCP server and can call any tool. | A governed MCP catalog with per-tool enable/disable and usage monitoring. |
| 6 | **Provider lock-in** | Switching models means code, SDK and credential changes in every app. | One endpoint for many model families. Switching is a model-name change. |
| 7 | **No cost attribution** | One combined invoice. | A service user per app plus cost-center tags give chargeback and showback per department. |

## 3. Features Explained

### 3.1 Unified inference endpoint
OpenAI-compatible `/v1/chat/completions` and Anthropic-compatible `/v1/messages`. One endpoint gives access to models from Anthropic, OpenAI, Meta, Mistral, DeepSeek, Snowflake and others, depending on what is available in your region. → *Tutorial step 5*

### 3.2 Centralized identity and access control (RBAC)
- `USAGE` on the gateway, together with the `SNOWFLAKE.CORTEX_USER` database role, lets a role send inference requests.
- `MONITOR` lets a role read all users' traces and usage.
- Clients authenticate with a Snowflake PAT or OAuth token.
- Using one **service user per application** makes costs attributable per app.

→ *Step 1*

### 3.3 Gateway specification (model allowlist and logging)
A YAML spec is the control plane. It defines which models are exposed and whether traces and payloads are captured. `ALTER AI GATEWAY ... FROM SPECIFICATION` **replaces the whole spec**, so always snapshot it with `DESCRIBE` first. → *Step 2*

### 3.4 Cost governance (tags, budgets, quotas)
- **Tags** (`COST_CENTER`) attribute spend to teams.
- **Budgets** are for showback and notifications. They don't block requests.
- **Quotas** set per-user daily, weekly or monthly limits and can **block** requests when a limit is reached. Scope quotas with tags first.

→ *Step 3*

### 3.5 Observability (traces and spans)
- A **trace** is one end-to-end agent turn. A **span** is one step within it (an LLM call or a tool call), with model, tokens, latency and status.
- Gateway (server-side) spans and client-side OpenTelemetry spans land in the same `AGENT_TRACE_TABLE`.
- `SNOWFLAKE.ACCOUNT_USAGE.AI_GATEWAY_USAGE_HISTORY` is the billing source of truth.
- Snowsight provides dashboards.

→ *Step 4*

### 3.6 Coding-agent integration
`snow ai claude` and `snow ai opencode` (Snowflake CLI) launch Claude Code or OpenCode through the gateway using your Snowflake connection. Developers never handle provider keys. → *Step 5d*

### 3.7 MCP governance
A catalog of managed MCP connectors (e.g. Slack, Jira, GitHub, Salesforce) and custom MCP servers. Individual tools can be enabled or disabled, for example allowing Slack `search` but not `postMessage`, and their usage is monitored. Configure this in Snowsight; availability may vary during Preview.

### 3.8 Roadmap capabilities (not yet generally available)
The following have been announced as coming or in preview and may not be available in your account yet:
- Dynamic model routing.
- Rate limits and fallbacks.
- Centralized guardrails: prompt injection detection, PII redaction and content safety.
- Custom LLM-as-judge guardrails.
- Dangerous-activity detection across agent sessions.
- Support for more Snowflake-native agents.

Plan for these, but don't depend on them yet.

## 4. Repository Layout

```
cortex-ai-gateway-tutorial/
├── readme.md / readme-ind.md
├── sql/
│   ├── 00_prerequisites.sql    # region check, SHOW / DESCRIBE gateway
│   ├── 01_setup_rbac.sql       # roles, service user, PAT
│   ├── 02_gateway_spec.sql     # model allowlist + logging
│   ├── 03_cost_controls.sql    # tags, quota, budget
│   ├── 04_observability.sql    # traces, usage, chargeback
│   └── 99_teardown.sql
└── clients/
    ├── requirements.txt
    ├── openai_sdk_example.py   # /v1/chat/completions
    ├── anthropic_sdk_example.py# /v1/messages
    ├── curl_example.sh
    └── coding_agents.md        # snow ai claude / opencode
```

## 5. Step-by-Step Implementation

**Prerequisites:**
- A Snowflake account in a supported AWS commercial region.
- `ACCOUNTADMIN` (or an equivalent role).
- Python 3.9+.
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index), optional, for coding agents.

| Step | File | What you do | Feature |
|---|---|---|---|
| 0 | `sql/00_prerequisites.sql` | Check the region, run `SHOW AI GATEWAYS`, copy `BASE_URL`, and snapshot the spec | - |
| 1 | `sql/01_setup_rbac.sql` | Create the app and monitor roles, a service user, and a PAT | 3.2 |
| 2 | `sql/02_gateway_spec.sql` | Allowlist models and enable logging | 3.3 |
| 3 | `sql/03_cost_controls.sql` | Add a cost-center tag, a quota (block) and a budget (alert) | 3.4 |
| 4 | Run the clients below | Send requests through the gateway | 3.1 |
| 5 | `sql/04_observability.sql` | Inspect traces, token usage, errors and chargeback | 3.5 |
| 6 | `sql/99_teardown.sql` | Clean up and restore the original spec | - |

### Running the clients
```bash
cd clients
pip install -r requirements.txt
export SNOWFLAKE_AI_GATEWAY_URL="<BASE_URL from SHOW AI GATEWAYS>"
export SNOWFLAKE_PAT="<token from step 1>"

python openai_sdk_example.py      # also shows a non-allowlisted model being rejected
python anthropic_sdk_example.py
bash curl_example.sh
snow ai claude                    # coding agent through the gateway
```

**Expected results:**
- Allowlisted models answer.
- A non-allowlisted model is rejected.
- About a minute later, the requests appear in `AGENT_TRACE_TABLE('SNOWFLAKE')` under `SVC_CHATBOT_APP`.

> ⚠️ The direct Cortex REST API (`/api/v2/cortex/...`) is **not** the gateway. Requests sent there bypass the allowlist and don't create gateway traces. Always use the `BASE_URL` from `SHOW AI GATEWAYS`.

## 6. Recommended Rollout

1. **Visibility:** enable logging and onboard one pilot team, for example developers using `snow ai claude`.
2. **Control:** set up the model allowlist, one service user per app, cost-center tags, budgets and quotas, then revoke `USAGE` from `PUBLIC`.
3. **Protect:** allow only approved MCP tools, and turn on guardrails when they become available.
4. **Optimize:** analyze traces with SQL to find token-heavy sessions and pick the right model per task.

## 7. Notes and Limitations
- Model names and availability depend on your region. Adjust `02_gateway_spec.sql` accordingly.
- Usage-view columns may evolve during Preview. Confirm them with `DESCRIBE VIEW`.
- Quotas may overshoot slightly, and traces can occasionally be dropped. Use `AI_GATEWAY_USAGE_HISTORY` for billing.
- If you turn on payload capture, treat the trace table as sensitive data.

## References
- [Snowflake Documentation - Cortex AI Gateway](https://docs.snowflake.com/)
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index)

*This is a community tutorial, not official Snowflake documentation. Test in a non-production account first.*
