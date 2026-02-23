# MCP troubleshooting demo (Phase 3)

**Goal:** Use an AI assistant (e.g. in Cursor) to troubleshoot the network by querying **NetBox** (Source of Truth), **Prometheus** (metrics from gnp-stack), and **ClickHouse** (syslog from Phase 2) via MCP.

## Roles of each source

| Source | MCP server | Role |
|--------|------------|------|
| **NetBox** | Existing NetBox MCP Server | SoT: sites, devices, interfaces, IPs, cables, links. “What is connected to Gi1/0/5 on core-01?” “Which device has 10.0.0.5?” |
| **Prometheus** | New or existing Prometheus MCP | Time-series: interface counters, drops, BGP, CPU. “Traffic on interface X last hour.” “Any errors on device Y?” |
| **ClickHouse** | New ClickHouse MCP | Logs: syslog. “Syslog from core-01 last 15 minutes.” “All CRITICAL/ERROR in last hour.” |

## User flow (example)

1. **User:** “Why might interface Gi1/0/5 on core-01 be dropping packets?”
2. **Assistant (via MCP):**
   - **NetBox:** Get device `core-01`, interface `Gi1/0/5`, linked neighbor, site.
   - **Prometheus:** Run PromQL for interface counters/discards for target matching `core-01` (or equivalent label from gnp-stack).
   - **ClickHouse:** Query syslog for host `core-01` (and optionally interface) in last 15–30 minutes.
3. **Assistant:** Summarize topology (from NetBox), metrics (from Prometheus), and recent logs (from ClickHouse) into a short answer.

## MCP server design

### NetBox

- Use your existing **NetBox MCP Server** (e.g. in Cursor). Ensure NetBox has devices/sites/interfaces aligned with CML and gnp-stack (management IPs, hostnames) so the assistant can correlate “core-01” in NetBox with the same target in Prometheus.

### Prometheus MCP

- **Tools (suggested):**
  - `query_prometheus`: run a PromQL query with optional time range (start/end or “last N minutes”).
  - Optionally `list_metric_names` or `suggest_queries` (e.g. “interface counters for device X”) to help the assistant form queries.
- **Implementation:** Small server (e.g. Python/TypeScript) that:
  - Calls Prometheus HTTP API: `GET /api/v1/query` and `GET /api/v1/query_range`.
  - Maps (query, start, end) from the tool input to the API; returns result as text or structured JSON for the assistant.
- **Security:** Read-only; no write or admin endpoints. Optional: allowlist of metric names or query patterns to avoid expensive queries.

### ClickHouse MCP

- **Tools (suggested):**
  - `query_syslog`: (device, since_minutes, severity_filter, limit) → run a parameterized SQL query against the syslog table (e.g. `WHERE host = ? AND timestamp >= now() - INTERVAL ? MINUTE`).
  - Or generic `query_clickhouse`: (read-only SQL) for flexibility, with strict allowlist (SELECT only, no DDL/DELETE).
- **Implementation:** Small server that:
  - Connects to ClickHouse (HTTP or native); runs parameterized or allowlisted SELECTs.
  - Returns rows (or summary) to the assistant.
- **Security:** Read-only; no DDL/DML. Prefer parameterized `query_syslog` to limit arbitrary SQL. Rate-limit if needed.

## Label alignment (gnp-stack ↔ NetBox)

- gNMIc uses **target** (e.g. device IP or hostname) in subscription and in emitted metrics. Ensure Prometheus metrics have a label that identifies the device (e.g. `target`, `device`, or `host`) so the assistant can map “core-01” from NetBox to the same device in Prometheus (e.g. by matching NetBox primary IP or name to that label).
- If gnp-stack uses IP as target, NetBox device primary IP can match; or maintain a small mapping (hostname ↔ IP) in config or NetBox custom fields.

## Deployment sketch

- **NetBox:** Already available via your NetBox MCP Server.
- **Prometheus:** Already running in gnp-stack; MCP server needs its URL (e.g. `http://prometheus:9090` in Docker, or cluster URL in K8s).
- **ClickHouse:** Add as a service (Docker/K8s) when you add syslog (Phase 2); same instance used for MCP in Phase 3.
- **MCP servers:** Run Prometheus MCP and ClickHouse MCP alongside your existing NetBox MCP (e.g. in Cursor MCP config) so the assistant can call all three.

## Summary

- **NetBox MCP:** SoT (existing).
- **Prometheus MCP:** PromQL tool(s) over gnp-stack Prometheus.
- **ClickHouse MCP:** Syslog (and optional other tables) via parameterized or allowlisted read-only queries.
- Align device identity (hostname/IP) between NetBox and Prometheus labels so the assistant can correlate topology with metrics and logs.
