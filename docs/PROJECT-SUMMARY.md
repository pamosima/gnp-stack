# gnp-stack — Short project summary

**TL;DR for a friend:** I'm trying to build an open-source observability stack to use for AI troubleshooting with MCP.

**What we're building:** A simple, composable observability stack so you can run **streaming telemetry** (and related data) without the usual integration pain — and plug it into AI/MCP for troubleshooting.

---

## The idea

Most network monitoring is still SNMP and “poll every 5 minutes.” Streaming telemetry (gNMI, etc.) is better but usually means stitching together many pieces. This project is a **single repo with Docker Compose** that gives you:

- **gNMIc** — subscribe to device streams (interfaces, BGP, whatever the box exports)
- **NATS** — message bus between collectors and backends
- **Prometheus + Grafana** — metrics and dashboards
- **ClickHouse** (via **ClickStack**) — one place for logs, metrics, and traces, with a proper UI (HyperDX)

You pick the pieces you need with different compose files and run them on any Linux host (e.g. a lab server or VM).

---

## What’s in the box

| Layer | Role |
|-------|------|
| **Ingestion** | gNMIc (gNMI streaming), Vector (syslog on UDP 514), optional IPFIX |
| **Storage** | ClickStack = ClickHouse + HyperDX UI (default port 8123); Prometheus for scrape cache + remote_write to ClickHouse |
| **Visualisation** | Grafana (dashboards), HyperDX (logs/traces/metrics in one UI) |

Optional overlays:

- **IOS-XE (C9k)** — ingestor config for Catalyst 9k so you can pull telemetry from CML or real devices
- **Syslog** — network devices → Vector → ClickHouse `default.syslog`; query in HyperDX or any ClickHouse client
- **MCP** — demo/tooling for an MCP-based troubleshooting flow (e.g. “show me logs for this device”)

No hardcoded credentials; configs are env/compose so you can point at your own devices and users.

---

## Why it exists

To get **“point and shoot” streaming telemetry** similar to what people expect from SNMP tooling today — one place to clone, configure, and run, instead of assembling and maintaining a custom pipeline from scratch.

---

## TL;DR

**gnp-stack** = open-source observability stack (gNMIc + NATS + Prometheus + Grafana + ClickStack) for streaming telemetry and logs, wired for **AI troubleshooting with MCP** — one place to clone, configure, and run.

**Deploy:** Set `GNP_STACK_HOST` in `.env` (copy from `.env.example`).
