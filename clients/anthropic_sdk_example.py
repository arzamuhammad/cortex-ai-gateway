"""Step 5b - Call Cortex AI Gateway with the Anthropic SDK (/v1/messages).

export SNOWFLAKE_AI_GATEWAY_URL="<BASE_URL from SHOW AI GATEWAYS>"
export SNOWFLAKE_PAT="<programmatic access token>"
python anthropic_sdk_example.py
"""
import os

from anthropic import Anthropic

token = os.environ["SNOWFLAKE_PAT"]
client = Anthropic(
    base_url=os.environ["SNOWFLAKE_AI_GATEWAY_URL"].rstrip("/"),
    api_key=token,
    default_headers={"Authorization": f"Bearer {token}"},
)

msg = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=300,
    messages=[{"role": "user", "content": "Give 3 benefits of centralizing LLM access."}],
)
print(msg.content[0].text)
print(f"usage: {msg.usage}")
