# 2025NTU_EE5178_group01_DataBase-Normalization-with-LLM

# DB Normalize Bot (MCP + LLM)

A tiny demo that lets an LLM agent talk to **your local MySQL** through an
[MCP server](https://github.com/openai/mcp).
Type natural-language requests ( `show db` / `describe users` / `select * …` )
and the bot automatically calls the **`execute_query`** tool.

---

## 1 . Set up `config.json`

1.  Copy **`config-example.json`** → **`config.json`**

    ```bash
    cp config-example.json config.json
    ```

2.  Edit the *env* section so it matches **your** local MySQL:

    | key            | value (example)       |
    |----------------|-----------------------|
    | `MYSQL_HOST`   | `localhost`           |
    | `MYSQL_PORT`   | `3306`                |
    | `MYSQL_USER`   | `root`                |
    | `MYSQL_PASS`   | **your-password-here**|
    | `MYSQL_DB`     | `mcp_test_db`         |

    ```jsonc
    {
      "MYSQL_HOST": "localhost",
      "MYSQL_PORT": "3306",
      "MYSQL_USER": "root",
      "MYSQL_PASS": "<enter>",
      "MYSQL_DB":   "<enter>",
      "ALLOW_INSERT_OPERATION": "true",
      "ALLOW_UPDATE_OPERATION": "true",
      "ALLOW_DELETE_OPERATION": "false"
    }
    ```

---

## 2 . Run the agent

```bash
# (create venv / install deps first, if you haven’t)
python agent.py

