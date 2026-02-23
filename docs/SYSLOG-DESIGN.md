# Syslog extension design (Phase 2)

This note outlines how to add **syslog** ingestion to the observability stack so logs can later be queried by the MCP troubleshooting demo (Phase 3).

## Goals

- Ingest syslog from Cisco C9k (and optionally other devices) in the same environment as gnp-stack.
- Store logs in **ClickHouse** for querying (e.g. by device, time, severity).
- Optional: expose severity/count metrics to **Prometheus** for alerting.

## Architecture

```
Devices (C9k, etc.) --syslog UDP/TCP--> Vector/Fluentd --> ClickHouse
                                                    \
                                                     (optional) --> Prometheus (counters)
```

- **Receiver:** Vector or Fluentd listening on syslog port (e.g. UDP 514, or TCP 601 for reliable).
- **Parse:** Extract timestamp, hostname, facility, severity, program, message; optional structured fields.
- **Sink:** ClickHouse table(s). Same ClickHouse can later serve the MCP server for “show logs for device X in last N minutes.”

## ClickHouse schema (sketch)

```sql
CREATE TABLE IF NOT EXISTS syslog (
  timestamp DateTime64(3),
  host String,
  facility UInt8,
  severity String,
  program String,
  message String,
  raw String,
  received_at DateTime64(3) DEFAULT now64(3)
) ENGINE = MergeTree()
ORDER BY (host, timestamp)
TTL timestamp + INTERVAL 30 DAY;
```

- Add indexes or secondary ordering if you need to query by `severity` or `program` often.

## Vector config (sketch)

```toml
[sources.syslog]
type = "syslog"
mode = "udp"
address = "0.0.0.0:514"

[sinks.clickhouse]
type = "clickhouse"
inputs = ["syslog"]
endpoint = "http://gnp-stack-clickstack:8123"
database = "default"
table = "syslog"
encoding = "json"
skip_unknown_fields = true
```

- Adjust `endpoint` to your ClickHouse URL. For production, add compression and batching; consider TCP syslog for reliability.

## Cisco C9k syslog config (on device)

- Set logging host to the Vector/Fluentd host IP and port (e.g. 514).
- Optionally set severity (e.g. `logging trap informational`).
- Ensure management connectivity from C9k to the syslog receiver.

## Integration with gnp-stack

- **Compose overlay:** Use `compose-syslog.yaml` together with `compose-clickstack.yaml`. Vector listens on UDP 514 and writes to `default.syslog` on ClickStack (`gnp-stack-clickstack`).
- **Deploy:** `docker compose -f compose.yaml -f compose-clickstack.yaml -f compose-syslog.yaml up -d`
- **Send syslog to:** host IP on port **514** (UDP), e.g. on C9k: `logging host 198.18.134.22`

## Optional: Prometheus counters

- In Vector, add a transform that increments counters by `host` and `severity` (e.g. `syslog_events_total{host="core-01", severity="error"}`) and expose them via a `prometheus_exporter` sink, then scrape that from Prometheus. This gives “how many errors in last 5m” for alerting without storing full logs in Prometheus.
