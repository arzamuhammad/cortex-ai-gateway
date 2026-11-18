# Step 5d - Connect coding agents

## Option A - Snowflake CLI (recommended)
Uses your existing Snowflake connection (PAT or OAuth), points the agent at the
gateway, and forwards trace context automatically.

```bash
snow ai claude      # launches Claude Code through Cortex AI Gateway
snow ai opencode    # launches OpenCode through Cortex AI Gateway
```

## Option B - Manual configuration

**Claude Code** - `~/.claude/settings.json`
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "<gateway BASE_URL>",
    "ANTHROPIC_AUTH_TOKEN": "<Snowflake PAT>"
  }
}
```

**OpenCode** - `~/.config/opencode/opencode.json`: set the provider `baseURL`
to `<gateway BASE_URL>/v1` and use the Snowflake PAT as the API key.

> Use the `BASE_URL` returned by `SHOW AI GATEWAYS`; do not build it by hand
> (PrivateLink accounts use a different host). The direct Cortex REST API
> (`/api/v2/cortex/...`) is **not** the gateway and bypasses its controls.
