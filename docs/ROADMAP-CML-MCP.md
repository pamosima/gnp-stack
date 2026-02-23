# Roadmap: CML C9k Observability → Syslog → MCP Troubleshooting Demo

This document outlines a three-phase path to use gnp-stack with **Cisco CML (Catalyst 9000)** and extend it with **syslog** and an **MCP-based troubleshooting demo** using **NetBox** as SoT and **Prometheus + ClickHouse** as information sources.

**Related:** For **“Is gNMI enough or do I need syslog?”** and **replacing Catalyst Center and Splunk with open-source** in your [network-mcp-docker-suite](https://github.com/pamosima/network-mcp-docker-suite), see [GNMI-VS-SYSLOG-AND-OPEN-SOURCE-MCP.md](GNMI-VS-SYSLOG-AND-OPEN-SOURCE-MCP.md).

### Reference lab

The CML topology and workflow used for this roadmap are documented in the Cisco Learning Lab:

- **[LTROPS-2341: Build a Flexible Network Automation Workflow with GitLab CI/CD, Cisco Catalyst Center, NetBox and Ansible](https://cl-ltr.ciscolabs.com/77b0d88058/)**

The lab covers Catalyst Center, NetBox (SoT), Ansible, NetBox dynamic inventory, pyATS, and GitLab CI/CD across multiple pods. gnp-stack (Phase 1) adds **streaming telemetry** from C9k nodes; the MCP troubleshooting demo (Phase 3) uses **NetBox as SoT** and **Prometheus (+ optional ClickHouse)** as information sources.

---

## Phase 1: gnp-stack with Cisco CML (C9k) for observability

**Goal:** Ingest gNMI streaming telemetry from Catalyst 9000 nodes in Cisco CML into the existing pipeline (NATS → Prometheus → Grafana).

### Differences from containerlab

- **CML** does not use Docker/containerlab labels, so the **Docker loader** in gnp-stack cannot discover C9k nodes.
- Use **static `targets`** in the gNMIc ingestor: list CML node IPs (and optional port). gNMI on IOS-XE uses port **57400** by default.

### What was added in this repo

| Item | Purpose |
|------|--------|
| `gnmic/gnmic-ingestor-iosxe.yaml` | Standalone ingestor config for Cisco IOS-XE (C9k) with static targets. Point this at your CML C9k management IPs. |
| `gnmic/gnmic-emitter-iosxe.yaml` | Emitter config that includes the **iosxe** JetStream stream (in addition to srl/eos). Use this as your single emitter, or merge the `iosxe` input and processor into `gnmic-emitter.yaml`. |
| `compose-iosxe.yaml` (optional) | Example Compose overlay that runs the IOS-XE ingestor and uses the combined emitter. |

### C9k prerequisites (on the switches)

1. Enable gRPC/gNMI and configure credentials:
   - **Port:** 57400 (default).
   - **Auth:** username/password (and optionally TLS).
2. Configure **dial-in** subscriptions (IOS-XE subscribes to paths and streams to the collector) or use **dynamic subscriptions** from gNMIc. This repo assumes gNMIc initiates **Subscribe** RPCs (dial-in from collector to device).

### OpenConfig paths used (IOS-XE)

- Interfaces: state/counters, oper-status, admin-status (same style as EOS).
- Optional: BGP, system/resources; add more in `gnmic-ingestor-iosxe.yaml` as needed.

### How to run (Phase 1)

1. **CML:** Ensure C9k nodes have gNMI enabled and reachability from the host running Docker (e.g. shared management network 192.168.60.0/24).
2. **Targets:** Edit `gnmic/gnmic-ingestor-iosxe.yaml` and set the `targets:` block to your CML C9k IPs (and port if not 57400). Use env-based or file-based secrets for passwords in production.
3. **Compose:**
   - Either merge IOS-XE subscriptions and `nats-iosxe-out` into the main `gnmic-ingestor.yaml` and add the iosxe input/processor to `gnmic-emitter.yaml`, then `docker compose up -d`.
   - Or use the optional `compose-iosxe.yaml` (if added) to run a dedicated IOS-XE ingestor and the combined emitter.
4. **Grafana:** Use existing Prometheus datasource; add dashboards for the new IOS-XE metrics (same pattern as EOS/SRL).

---

## Phase 2: Extend with syslog

**Goal:** Ingest syslog from C9k (and optionally other devices) into the observability stack and, later, make it queryable for the MCP troubleshooting demo.

### Design options

| Option | Pros | Cons |
|-------|------|------|
| **Syslog → Vector/Fluentd → ClickHouse** | Good for search/analytics; keeps logs out of Prometheus. | New component; ClickHouse to be added in Phase 3 anyway. |
| **Syslog → Prometheus (via parsing/metrics)** | Reuse existing stack; only state/severity as metrics. | Not full log search; only aggregated metrics. |
| **Syslog → Loki** | Native log stack; Grafana integration. | Extra stack (Loki + optional Promtail). |

**Recommended for your demo:** **Syslog → Vector (or Fluentd) → ClickHouse**. Centralize logs in ClickHouse so the MCP server can query both metrics (Prometheus) and logs (ClickHouse) in Phase 3.

### Suggested layout (Phase 2)

1. **Syslog receiver:** Vector or Fluentd listening on UDP/TCP syslog (e.g. 514).
2. **Parse & normalize:** Extract facility, severity, hostname, program, message; optional structured fields (interface, VLAN, etc.).
3. **Sink:** ClickHouse table(s) for log events (timestamp, host, severity, message, raw, etc.).
4. **Optional:** Forward a subset (e.g. severity ≥ warning) to Prometheus as counters for alerting.

A short **design note** is in `docs/SYSLOG-DESIGN.md` (target schema, Vector config sketch, C9k syslog config hints).

---

## Phase 3: MCP troubleshooting demo (NetBox SoT + Prometheus + ClickHouse)

**Goal:** Use an **MCP server** as the integration point for an AI/assistant to troubleshoot the network, with **NetBox** as Source of Truth and **Prometheus** and **ClickHouse** as information sources.

### Roles

| Source | Role in troubleshooting |
|-------|---------------------------|
| **NetBox (MCP)** | SoT: devices, sites, links, cables, IPs, VLANs. “What is connected to this port?” “Which device is at this IP?” |
| **Prometheus (MCP or queries)** | Time-series metrics from gnp-stack (interfaces, BGP, CPU, etc.). “Show traffic on this interface.” “Any drops in the last hour?” |
| **ClickHouse** | Logs (syslog). “Show syslog from this device in the last 15 minutes.” “All CRITICAL/ERROR in the last hour.” |

### MCP architecture (conceptual)

- You already have **NetBox MCP Server** in Cursor; use it for SoT (sites, devices, interfaces, IPs).
- **Prometheus:** Expose via an MCP server that can run PromQL (or HTTP API) so the assistant can query metrics (e.g. by device/interface labels from gnp-stack).
- **ClickHouse:** Expose via an MCP server that runs SQL (or HTTP) so the assistant can query syslog (and any other tables).

Flow for the assistant:

1. **User:** “Why is interface Gi1/0/5 on switch core-01 dropping packets?”
2. **Assistant (via MCP):**
   - NetBox: get device `core-01`, interface `Gi1/0/5`, linked device/port, site.
   - Prometheus: query interface counters/drops for that device/interface (gnp-stack labels).
   - ClickHouse: query syslog for `core-01` (and maybe interface) in the last N minutes.
3. **Assistant:** Summarize topology, metrics, and recent logs into an answer.

### Implementation outline

- **NetBox:** Use existing NetBox MCP server; ensure devices/sites/interfaces match what CML and gnp-stack use (naming, management IPs).
- **Prometheus MCP:** Implement a small MCP server that:
  - Has a tool “query_prometheus” (PromQL + optional time range).
  - Optionally “list_metric_names” or “suggest_queries” for interfaces/drops.
- **ClickHouse MCP:** Implement a small MCP server that:
  - Has a tool “query_clickhouse” (read-only SQL) or “query_syslog” (predefined query with device/time/severity).
  - Ensures queries are scoped (e.g. no DROP TABLE) and optionally rate-limited.

Details and tool schemas are in `docs/MCP-TROUBLESHOOTING-DEMO.md`.

---

## Summary

| Phase | Deliverable |
|-------|-------------|
| **1** | C9k telemetry in gnp-stack via static-target gNMIc ingestor and iosxe emitter; dashboards in Grafana. |
| **2** | Syslog pipeline (e.g. Vector → ClickHouse) and optional Prometheus counters; C9k syslog configured. |
| **3** | MCP-based troubleshooting: NetBox (SoT) + Prometheus (metrics) + ClickHouse (logs) as MCP tools/resources for an AI assistant. |

Start with Phase 1 (this repo’s new gnmic configs), then add syslog (Phase 2) and MCP servers for Prometheus and ClickHouse (Phase 3).
