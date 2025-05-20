#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Agent Route3nf **v7**
- 每個 phase 以 system_message 注入專屬 prompt（OPENAI_FUNCTIONS agent 需用 `system_message` 而非 `prefix`）。
- 不再把上一輪 ai_reply 回寫 user_text，避免訊息遞增。
- router ↔ phase 仍保持線性（init→1nf→…），但可輕鬆改成迴圈。
"""

import asyncio
import json
import os
import sys
from contextlib import AsyncExitStack
from typing import List, TypedDict
from typing_extensions import Annotated

from dotenv import load_dotenv
from langchain.agents import initialize_agent, AgentType
from langchain_openai import ChatOpenAI
from langgraph.graph import END, StateGraph
from langgraph.channels import LastValue
from langchain_mcp_adapters.tools import load_mcp_tools
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

load_dotenv()

CONFIG_PATH = os.getenv("CONFIG") or os.path.join(os.path.dirname(__file__), "config.json")

a_stack = AsyncExitStack()

###############################################################################
# Helpers
###############################################################################

def read_cfg():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

class PrettyJSON(json.JSONEncoder):
    def default(self, o):
        if hasattr(o, "content"):
            return {"type": o.__class__.__name__, "content": o.content}
        return super().default(o)

###############################################################################
# LLM
###############################################################################

def get_llm():
    return ChatOpenAI(
        model="gpt-4o",
        temperature=0,
        max_retries=3,
        openai_api_key=os.getenv("OPENAI_API_KEY"),
    )

###############################################################################
# Load MCP tools
###############################################################################

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
# Phase prompts
###############################################################################

PHASES = ["init", "1nf", "2nf", "3nf", "sql", "report"]

def router_prompt(msgs: List[dict]) -> str:
    return (
        "你是一位資料庫正規化專家。請在 {'init','1NF','2NF','3NF','sql','report'} 中選擇下一步並只輸出單字。\n\n對話:\n"
        + json.dumps(msgs, ensure_ascii=False)
    )

def phase_prompt(phase: str) -> str:
    base = "你是 MySQL 專家助手，只能使用 execute_query 工具執行 SQL。\n"
    details = {
        "init":   "提示使用者提供 raw_table_data (JSON) 以開始 1NF。",
        "1nf":    "分析 raw_table_data 並轉成 1NF（僅輸出 JSON）。",
        "2nf":    "依完整主鍵拆除 partial dependency 產生 2NF（僅輸出 JSON）。",
        "3nf":    "移除傳遞依賴完成 3NF（僅輸出 JSON）。",
        "sql":    "將 3NF schema 轉為 CREATE TABLE DDL，並以 mysql_query 執行。僅輸出 Action JSON。",
        "report": "說明整個流程，以 'FINAL ANSWER' 開頭。",
    }
    return base + details.get(phase, "")

###############################################################################
# LangGraph state
###############################################################################

class AgentState(TypedDict):
    user_text: Annotated[str | None, LastValue]
    messages:  Annotated[List[dict], LastValue]
    phase:     Annotated[str, LastValue]

###############################################################################
# Build graph
###############################################################################

async def build_graph():
    llm   = get_llm()
    tools = await load_tools()

    # Router node
    async def router(state: AgentState):
        phase_decision = (await llm.ainvoke(router_prompt(state["messages"]))).content.strip().lower()
        if phase_decision not in PHASES:
            phase_decision = state["phase"]
        return {"phase": phase_decision}

    # Phase node cache
    agents_cache = {}

    async def phase_node(state: AgentState):
        ph = state["phase"]
        if ph not in agents_cache:
            agents_cache[ph] = initialize_agent(
                tools, llm,
                agent=AgentType.OPENAI_FUNCTIONS,
                agent_kwargs={"system_message": phase_prompt(ph)},  # ← 關鍵
                verbose=False,
            )

        last_input = state["user_text"] or ""
        messages = state["messages"] + [{"role": "user", "content": last_input}]
        ai_reply = await agents_cache[ph].ainvoke({"input": last_input})
        messages.append({"role": "assistant", "content": ai_reply})

        # 線性下一階段
        next_idx   = PHASES.index(ph) + 1
        next_phase = PHASES[next_idx] if next_idx < len(PHASES) else "report"

        return {"messages": messages, "user_text": None, "phase": next_phase}

    # Wire graph (linear: init→1nf→…)
    g = StateGraph(AgentState)
    g.add_node("router", router)
    prev = "router"
    for p in PHASES:
        g.add_node(p, phase_node)
        g.add_edge(prev, p)
        prev = p
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

