"""Step 5a - Call Cortex AI Gateway with the OpenAI SDK (/v1/chat/completions).

pip install -r requirements.txt
export SNOWFLAKE_AI_GATEWAY_URL="<BASE_URL from SHOW AI GATEWAYS>"
export SNOWFLAKE_PAT="<programmatic access token>"
python openai_sdk_example.py
"""
import os

from openai import OpenAI

client = OpenAI(
    base_url=os.environ["SNOWFLAKE_AI_GATEWAY_URL"].rstrip("/") + "/v1",
    api_key=os.environ["SNOWFLAKE_PAT"],  # Snowflake identity, not a provider key
)

# Switching provider = changing only the model string.
for model in ["openai-gpt-5", "llama4-maverick"]:
    resp = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are a concise assistant."},
            {"role": "user", "content": "Explain what an AI gateway is in one sentence."},
        ],
        max_tokens=200,
    )
    print(f"[{model}] {resp.choices[0].message.content}")
    print(f"  usage: {resp.usage}")

# A model NOT in the allowlist should be rejected by the gateway.
try:
    client.chat.completions.create(
        model="mistral-large2",
        messages=[{"role": "user", "content": "hello"}],
    )
except Exception as exc:  # expected: model not allowed
    print(f"Blocked as expected: {exc}")
