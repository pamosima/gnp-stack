# gNMI vs syslog, and open-source MCP stack

This note answers: **Is gNMI enough, or do I need syslog?** and how to use **open-source tools** instead of Catalyst Center and Splunk with your [network-mcp-docker-suite](https://github.com/pamosima/network-mcp-docker-suite).

---

## Is gNMI enough or do I need syslog?

### What gNMI (streaming telemetry) gives you

| Capability | Example |
|------------|--------|
| **State and counters** | Interface up/down, admin/oper status, bytes in/out, errors, discards |
| **Periodic metrics** | CPU, memory, BGP sessions, route counts, traffic rate |
| **On-change state** | Oper state, link flaps (as state updates) |
| **Structured, model-driven** | OpenConfig paths; easy to map into Prometheus and Grafana |

**Good for:** Dashboards, capacity planning, “show me traffic on this interface,” “is BGP up?,” “any discards in the last hour?” Your **Prometheus MCP** server can answer these from gnp-stack data.

### What gNMI does *not* give you

| Gap | Example |
|-----|--------|
| **Discrete event messages** | “*At 14:32 the device said:* Interface Gi1/0/5 changed state to down” |
| **Audit and security events** | Login/logout, config change, who ran what, license alerts |
| **Device narrative** | Many issues are first reported as syslog; the device tells you *what happened* in text form |
| **Non-telemetry logs** | ACL hits, auth failures, SNMP traps (if forwarded as syslog), etc. |

So: **gNMI is enough for “what is the state and what are the numbers?”**  
**Syslog is needed for “what did the device say happened?”** (events, messages, audit trail).

### Practical recommendation

- **Start with gNMI only** if your demo is focused on **metrics and state**: NetBox (SoT) + Prometheus (from gnp-stack) + IOS XE MCP (CLI) is already strong. You can add a **Prometheus MCP** server to the suite and get “show interface stats,” “any errors/discards,” “BGP state” without syslog.
- **Add syslog** when you want **full troubleshooting and event narrative**: “Show me what the device reported in the last 15 minutes,” “any CRITICAL/ERROR from this host,” “link down messages.” Then add **Vector → ClickHouse (or Loki)** and a **ClickHouse/Loki MCP** server.

**Summary:** gNMI is enough for **metrics/state visibility**. For **event-based troubleshooting and “what did the device say?”**, add **syslog** (open-source stack below).

---

## Replacing Catalyst Center and Splunk with open-source

Your suite today: Meraki, **Catalyst Center**, IOS XE, ThousandEyes, ISE, **Splunk**, NetBox.  
Goal: keep the same *capabilities* (assurance, metrics, logs, SoT) using **open-source** where possible.

### Catalyst Center → open-source “assurance + telemetry” stack

There is no single open-source Catalyst Center clone. Replace it with a **combination** that gives you inventory, topology, and live metrics:

| Catalyst Center role | Open-source replacement |
|----------------------|--------------------------|
| **Inventory / SoT** | **NetBox** (already in your suite) — sites, devices, interfaces, cables, IPs |
| **Live metrics / assurance** | **gnp-stack** — gNMI → NATS → Prometheus (C9k via `gnmic-ingestor-iosxe.yaml`) |
| **Direct device access** | **IOS XE MCP Server** (already in your suite) — SSH, show commands, config |
| **Dashboards** | **Grafana** (in gnp-stack) — Prometheus datasource |

So: **NetBox (MCP) + gnp-stack (Prometheus) + IOS XE (MCP)** gives you “inventory + real-time metrics + device CLI” without Catalyst Center. Add a **Prometheus MCP** server so the AI can run PromQL (e.g. “interface counters for device X,” “discards in last hour”).

### Splunk → open-source log store and MCP

| Splunk role | Open-source replacement |
|-------------|--------------------------|
| **Log ingestion** | **Vector** or **Fluentd** — receive syslog (UDP/TCP 514) |
| **Log storage and query** | **ClickHouse** or **Grafana Loki** |
| **MCP for logs** | **ClickHouse MCP** or **Loki MCP** — “syslog from device X last N minutes,” “errors in last hour” |

- **ClickHouse:** Strong for analytics and SQL; we already designed syslog → Vector → ClickHouse in [SYSLOG-DESIGN.md](SYSLOG-DESIGN.md). Add a small **ClickHouse MCP** server with a `query_syslog` (or read-only SQL) tool.
- **Loki:** Grafana-native, LogQL; good if you standardize on Grafana. You’d add a **Loki MCP** server that runs LogQL queries.

Either way, you get **open-source log storage + MCP** instead of Splunk.

---

## Resulting open-source MCP stack (with your suite)

Conceptually, after the swap:

| Capability | Component | MCP server (in your suite or new) |
|------------|-----------|-----------------------------------|
| **SoT / DCIM** | NetBox | NetBox MCP (existing) |
| **Live metrics** | gnp-stack → Prometheus | **Prometheus MCP** (new; add to suite) |
| **Device CLI** | IOS XE | IOS XE MCP (existing) |
| **Logs / events** | Syslog → ClickHouse or Loki | **ClickHouse MCP** or **Loki MCP** (new; add to suite) |
| **Cloud / SD-WAN** | Meraki | Meraki MCP (existing) |
| **Monitoring** | ThousandEyes | ThousandEyes MCP (existing) |
| **Identity** | ISE | ISE MCP (existing) |

You keep **Meraki, NetBox, IOS XE, ThousandEyes, ISE**; you **add** Prometheus MCP (and optionally ClickHouse/Loki MCP). Catalyst Center and Splunk are replaced by **gnp-stack + NetBox + optional syslog pipeline** as above.

---

## Direct answers

1. **Is gNMI enough?**  
   **Yes** for metrics and state (dashboards, “show counters,” “BGP up?”).  
   **Add syslog** when you want event narrative and “what did the device say?” for troubleshooting.

2. **Do I need syslog?**  
   **Optional for a first demo;** **recommended** for a complete troubleshooting story (NetBox + Prometheus + device events).

3. **Open-source instead of Catalyst Center:**  
   Use **NetBox (SoT) + gnp-stack (Prometheus from gNMI) + IOS XE MCP**. Add **Prometheus MCP** to the [network-mcp-docker-suite](https://github.com/pamosima/network-mcp-docker-suite) so the AI can query metrics.

4. **Open-source instead of Splunk:**  
   Use **Vector (or Fluentd) → ClickHouse or Loki**. Add **ClickHouse MCP** or **Loki MCP** to the suite so the AI can query logs. Only needed if you add syslog.
