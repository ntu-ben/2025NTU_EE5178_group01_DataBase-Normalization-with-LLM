# ✅ MCP Plan: Relational Database Normalization (1NF to 3NF)

## 🎯 Objective
Utilize an LLM to assist in transforming a raw, non-normalized table into a set of normalized tables through the 1st, 2nd, and 3rd Normal Forms. This process aims to reduce redundancy, enforce data integrity, and improve query performance.

---

## 🗂 Step-by-Step Control Plan

### STEP 0 – Initialization
**Goal**: Define global context and import user input.

```json
{
  "step": "init",
  "input_required": ["table_name", "raw_table_data"],
  "actions": [
    "Parse table name and tabular data",
    "Validate headers and identify possible primary keys"
  ],
  "LLM_instruction": "You are a database architect. Analyze a flat table and prepare it for normalization up to 3NF."
}
```

---

### STEP 1 – First Normal Form (1NF)
**Goal**: Ensure atomic values and remove repeating groups.

```json
{
  "step": "1NF",
  "input_from": "init",
  "actions": [
    "Identify multi-valued or composite fields",
    "Transform the table to remove repeating groups",
    "Propose a revised schema with atomic attributes"
  ],
  "LLM_instruction": "Analyze the raw table and ensure all fields are atomic (1NF). Return a new table with no repeating groups or nested attributes."
}
```

---

### STEP 2 – Second Normal Form (2NF)
**Goal**: Eliminate partial dependencies based on composite keys.

```json
{
  "step": "2NF",
  "input_from": "1NF",
  "actions": [
    "Determine the correct primary key (single or composite)",
    "Identify fields that depend only on part of the key",
    "Decompose table to remove partial dependencies"
  ],
  "LLM_instruction": "Based on the 1NF output, apply 2NF. Identify and isolate partial dependencies into separate tables and define appropriate keys."
}
```

---

### STEP 3 – Third Normal Form (3NF)
**Goal**: Eliminate transitive dependencies.

```json
{
  "step": "3NF",
  "input_from": "2NF",
  "actions": [
    "Detect non-key attributes that depend on other non-key attributes",
    "Split tables to remove transitive dependencies",
    "Define all foreign key relationships"
  ],
  "LLM_instruction": "From the 2NF schema, perform 3NF. Remove transitive dependencies and generate final table definitions with keys."
}
```

---

### STEP 4 – SQL Schema Generation
**Goal**: Output normalized schema in SQL (DDL) format.

```json
{
  "step": "generate_sql",
  "input_from": "3NF",
  "actions": [
    "Define each table with CREATE TABLE statements",
    "Declare primary and foreign keys"
  ],
  "LLM_instruction": "Generate SQL DDL statements to create the normalized schema from step 3NF."
}
```

---

### STEP 5 – Summary Report
**Goal**: Provide a final report of the normalization steps and rationale.

```json
{
  "step": "summary_report",
  "input_from": ["1NF", "2NF", "3NF"],
  "actions": [
    "Summarize transformations at each step",
    "List all new tables and relationships",
    "Provide data integrity improvement explanation"
  ],
  "LLM_instruction": "Provide a narrative summary of the normalization process, including the reasoning behind table splits and integrity enforcement."
}
```

## Input Template for Users

```json
{
  "table_name": "Orders",
  "raw_table_data": [
    {
      "OrderID": "001",
      "CustomerName": "Alice",
      "CustomerAddress": "Taipei",
      "ProductName": "Pencil",
      "ProductCategory": "Stationery",
      "Quantity": 2,
      "Price": 20
    }
  ]
}
```

---

## Output Expectation

Example for 3NF:

```json
{
  "tables": {
    "Customers": ["CustomerID", "CustomerName", "CustomerAddress"],
    "Products": ["ProductID", "ProductName", "ProductCategory", "Price"],
    "Orders": ["OrderID", "CustomerID", "ProductID", "Quantity"]
  },
  "keys": {
    "Customers": "CustomerID (PK)",
    "Products": "ProductID (PK)",
    "Orders": "OrderID (PK), CustomerID (FK), ProductID (FK)"
  },
  "explanation": "Customers and Products are extracted to remove transitive dependencies. Orders now references both."
}
```


