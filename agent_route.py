#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Agent Route3nf **v6**
- Correct indentation (fixed unexpected‑indent error)
- Graph edges: router → phase_node and phase_node → router (single write per key)
- Keyword args for StdioServerParameters
"""

import asyncio
import json
import os
import sys
from contextlib import AsyncExitStack
from typing import List, TypedDict
from typing_extensions import Annotated

from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.agents import initialize_agent, AgentType
from langgraph.graph import END, StateGraph
from langgraph.channels import LastValue
from langchain_mcp_adapters.tools import load_mcp_tools
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

load_dotenv()

# Suppress LangChain deprecation banner ↓
import warnings
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

###############################################################################
# utilities
###############################################################################

CONFIG_PATH = os.getenv("CONFIG") or os.path.join(os.path.dirname(__file__), "config.json")


def read_cfg():
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)


class PrettyJSON(json.JSONEncoder):
    def default(self, o):
        if hasattr(o, "content"):
            return {"type": o.__class__.__name__, "content": o.content}
        return super().default(o)


###############################################################################
# LLM + MCP tools
###############################################################################

a_stack = AsyncExitStack()


def get_llm():
    return ChatGoogleGenerativeAI(
        model="gemini-2.0-flash",
        temperature=0,
        max_retries=3,
        google_api_key=os.getenv("GOOGLE_API_KEY"),
    )


async def load_tools():
    await a_stack.__aenter__()
    tools = []
    for name, info in read_cfg()["mcpServers"].items():
        print(f"🔗 Starting MCP: {name}")
        params = StdioServerParameters(command=info["command"], args=info["args"], env=info["env"])
        r, w = await a_stack.enter_async_context(stdio_client(params))
        sess = await a_stack.enter_async_context(ClientSession(r, w))
        await sess.initialize()
        tools.extend(await load_mcp_tools(sess))
    if not tools:
        print("❌ MCP tools not loaded"); sys.exit(1)
    return tools


###############################################################################
# LangGraph state
###############################################################################

class AgentState(TypedDict):
    user_text: Annotated[str | None, LastValue]
    messages: Annotated[List[dict], LastValue]
    phase: Annotated[str, LastValue]

PHASES = ["init", "1nf", "2nf", "3nf", "sql", "report"]


def router_prompt(msgs: List[dict]) -> str:
    return (
        "你是一位資料庫正規化專家。請在 {'init','1NF','2NF','3NF','sql','report'} 中選擇下一步並只輸出單字。\n\n對話:\n"
        + json.dumps(msgs, ensure_ascii=False)
    )


def phase_prompt(phase: str) -> str:
    base = "你是 MySQL 專家助手，只能使用 execute_query 工具執行 SQL。\n"
    details = {
        "init": "提示使用者提供 raw_table_data (JSON) 以開始 1NF。",
        "1nf": "分析 raw_table_data 並轉成 1NF。",
        "2nf": "依完整主鍵拆除 partial dependency 產生 2NF。",
        "3nf": "移除傳遞依賴完成 3NF。",
        "sql": "將 3NF schema 轉為 CREATE TABLE DDL。這個階段請使用工具。",
        "report": "說明整個流程，以 'FINAL ANSWER' 開頭。",
    }
    return base + details.get(phase, "")


###############################################################################
# Build graph
###############################################################################

async def build_graph():
    _llm = get_llm()
    tools = await load_tools()

    async def router(state: AgentState):
        decision = (await _llm.ainvoke(router_prompt(state["messages"]))).content.strip().lower()
        if decision not in PHASES:
            decision = state["phase"]
        return {"phase": decision}

    agents_cache = {}

    async def phase_node(state: AgentState):
        ph = state["phase"]
        if ph not in agents_cache:
            agents_cache[ph] = initialize_agent(
                tools,
                _llm,
                agent=AgentType.STRUCTURED_CHAT_ZERO_SHOT_REACT_DESCRIPTION,
                agent_kwargs={"system_message": phase_prompt(ph)},
                verbose=False,
            )
        new_msgs = state["messages"] + [{"role": "user", "content": state["user_text"]}]
        ai_reply = await agents_cache[ph].ainvoke({"input": state["user_text"]})
        new_msgs.append({"role": "assistant", "content": ai_reply})
        return {"messages": new_msgs}

    g = StateGraph(AgentState)
    g.add_node("router", router)
    preNode = "router"
    for p in PHASES:
        g.add_node(p, phase_node)
        g.add_edge(preNode, p)
        preNode = p
        
    g.add_edge("report", END)
    g.set_entry_point("router")
    return g.compile()


###############################################################################
# CLI
###############################################################################

async def main():
    graph = await build_graph()
    state: AgentState = {"user_text": None, "messages": [], "phase": "init"}
    print("🚀 DBNormalizeBot route ready. 輸入 query 或 quit。")
    while True:
        q = input("Query: ").strip()
        if q.lower() == "quit":
            break
        state["user_text"] = q
        state = await graph.ainvoke(state)
        print(json.dumps(state["messages"][-1]["content"], indent=2, ensure_ascii=False, cls=PrettyJSON))
        if isinstance(state["messages"][-1]["content"], str) and state["messages"][-1]["content"].startswith("FINAL ANSWER"):
            state = {"user_text": None, "messages": [], "phase": "init"}
            print("🔄 重新開始…\n")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    finally:
        if a_stack:
            asyncio.run(a_stack.aclose())

