#!/usr/bin/env python
# -*- coding: utf-8 -*-

import asyncio, os, sys, json
from contextlib import AsyncExitStack
from dotenv import load_dotenv
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from langchain_mcp_adapters.tools import load_mcp_tools
from langgraph.prebuilt import create_react_agent
from langchain_google_genai import ChatGoogleGenerativeAI
from langgraph.checkpoint.memory import MemorySaver

load_dotenv()

class CustomEncoder(json.JSONEncoder):
    def default(self, o):
        if hasattr(o, "content"):
            return {"type": o.__class__.__name__, "content": o.content}
        return super().default(o)

def read_config_json():
    config_path = os.getenv("THEAILANGUAGE_CONFIG")
    if not config_path:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        config_path = os.path.join(script_dir, "theailanguage_config.json")
        print(f"⚠️  THEAILANGUAGE_CONFIG not set. Falling back to: {config_path}")
    try:
        with open(config_path, "r") as f:
            return json.load(f)
    except Exception as e:
        print(f"❌ Failed to read config file at '{config_path}': {e}")
        sys.exit(1)

# ——————————————————————————————
# 1) LLM
# ——————————————————————————————
llm = ChatGoogleGenerativeAI(
    model="gemini-2.0-flash",
    temperature=0,
    max_retries=3,
    google_api_key=os.getenv("GOOGLE_API_KEY")
)

# ——————————————————————————————
# 2) 建立 Agent
# ——————————————————————————————
async def build_agent():
    cfg = read_config_json()
    mcp_servers = cfg.get("mcpServers", {})
    if not mcp_servers:
        print("❌ No MCP servers in config"); sys.exit(1)

    tools = []
    async with AsyncExitStack() as stack:
        for name, info in mcp_servers.items():
            print(f"🔗 Connecting to MCP Server: {name}")
            params = StdioServerParameters(command=info["command"], args=info["args"])
            read, write = await stack.enter_async_context(stdio_client(params))
            session = await stack.enter_async_context(ClientSession(read, write))
            await session.initialize()
            server_tools = await load_mcp_tools(session)
            tools.extend(server_tools)
            print(f"✅ Loaded {len(server_tools)} tools from {name}")

    if not tools:
        print("❌ No tools loaded"); sys.exit(1)

    # we only care about scale_deployment here
    system_prompt = """
You are AutoScalerBot.
 Goal: you can perform two types of tasks:
 1) Load testing: user may request to generate load against a target URL/file.
 2) Autoscaling: keep P95 latency below 250 ms for deployment "cartservice" in namespace "default",
    without exceeding 10 replicas.

 Tool usage:
 - To run a load test, call:
     load_gen(target_url: str, users: int, spawn_rate: int, duration: int)
   Example: load_gen(target_url="http://140.112.18.212", users=100, spawn_rate=10, duration=120)

 - To scale deployment, call:
     scale_deployment(namespace: str, deployment: str, replicas: int)
   When scaling, read user-supplied current_latency and current_replicas.

 Loop rules for autoscaling:
 1) If user input is two numbers "latency replicas", interpret them as current_latency and current_replicas.
 2) If current_latency > 250 AND current_replicas < 10, call scale_deployment(...)
 3) Else respond with FINAL ANSWER: SLA_MET.

Always use the correct tool for the request. Never answer without calling a tool or returning FINAL ANSWER.
"""
    memory = MemorySaver()
    agent = create_react_agent(
        llm,
        tools=tools,
        prompt=system_prompt,
        checkpointer=memory
    )
    return agent, system_prompt 

# ——————————————————————————————
# 3) CLI + Multi-turn
# ——————————————————————————————
async def main():
    agent, system_prompt = await build_agent()
    thread_id = "auto-0001"
    config = {"configurable": {"thread_id": thread_id}}

    # 初始 messages 包含 system prompt 角色
    messages = [{"role":"system", "content": system_prompt}]

    print("\n🚀 AutoScalerBot ready! Enter 'latency replicas' or 'quit'.")
    while True:
        line = input("Query (latency replicas): ").strip()
        if not line or line.lower() == "quit":
            break

        # append user message
        messages.append({"role":"user", "content": line})

        # Agent.ainvoke 會自動多輪調用直到背後 LLM 回 FINAL ANSWER
        resp = await agent.ainvoke({"messages": messages}, config)

        print("\n📨 Response:")
        print(json.dumps(resp, indent=2, ensure_ascii=False, cls=CustomEncoder))

        # 若是 FINAL ANSWER，結束本次 loop
        if isinstance(resp, str) and resp.startswith("FINAL ANSWER"):
            # 重置 messages（或 break 看需求）
            messages = [{"role":"system", "content": system_prompt}]
            print("🔄 reset context for next run\n")

if __name__ == "__main__":
    asyncio.run(main())
