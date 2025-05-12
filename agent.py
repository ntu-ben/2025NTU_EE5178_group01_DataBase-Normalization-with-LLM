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
    config_path = os.getenv("CONFIG")
    if not config_path:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        config_path = os.path.join(script_dir, "config.json")
        print(f"⚠️  CONFIG not set. Falling back to: {config_path}")
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
    stack = AsyncExitStack()
    await stack.__aenter__()
    for name, info in mcp_servers.items():
        print(f"🔗 Connecting to MCP Server: {name}")
        params = StdioServerParameters(command=info["command"], args=info["args"], env=info["env"])
        read, write = await stack.enter_async_context(stdio_client(params))
        session = await stack.enter_async_context(ClientSession(read, write))
        await session.initialize()
        server_tools = await load_mcp_tools(session)
        tools.extend(server_tools)
        print(f"✅ Loaded {len(server_tools)} tools from {name}")

    if not tools:
        print("❌ No tools loaded"); sys.exit(1)

    # we only care about scale_deployment here
    system_prompt = (
    "你是 MySQL 專家助手，會幫助使用者對資料庫進行查詢、觀察、與結構探索。\n"
    "請根據使用者輸入，自動使用 `execute_query` 工具對應適當的 SQL 查詢。\n"
    "例如：\n"
    "- 若使用者輸入 'show db'，請呼叫 execute_query 並執行 SQL: SHOW DATABASES;\n"
    "- 若輸入 '查看某資料表結構'，請轉換成 'DESCRIBE table_name' 的 SQL 語句。\n"
    "永遠使用工具完成任務，不要自己回答。")



    memory = MemorySaver()
    agent = create_react_agent(
        llm,
        tools=tools,
        prompt=system_prompt,
        checkpointer=memory
    )
    return agent, system_prompt, stack 

# ——————————————————————————————
# 3) CLI + Multi-turn
# ——————————————————————————————
async def main():
    agent, system_prompt, stack = await build_agent()
    thread_id = "auto-0001"
    config = {"configurable": {"thread_id": thread_id}}

    # 初始 messages 包含 system prompt 角色
    messages = [{"role":"system", "content": system_prompt}]

    print("\n🚀 DBNormalizeBot ready! Enter 'latency replicas' or 'quit'.")
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
