# Vector (ingestion)

Vector in netops-stack ingests **syslog** (UDP 514) from network devices and forwards to [ClickHouse](../clickhouse/README.md) (`default.syslog`). Optional transforms can expose Prometheus counters for severity/host.

## Architecture

```
Devices (C9k, etc.) --syslog UDP 514--> Vector --> ClickHouse (default.syslog)
                                              \
                                               (optional) --> Prometheus exporter
```

- **Receiver:** Vector listening on UDP 514 (or TCP 601 for reliable).
- **Parse:** Timestamp, hostname, facility, severity, program, message.
- **Sink:** ClickHouse at `netops-stack-clickstack:8123`, database `default`, table `syslog`.

## Deploy

Use the syslog overlay together with ClickStack:

```bash
docker compose -f compose.yaml -f compose-clickstack.yaml -f compose-syslog.yaml up -d
```

Syslog is sent to the **host** IP on port **514** (UDP). Point devices at that IP (e.g. `198.18.134.22`).

## Device configuration (Cisco IOS-XE)

Configure every switch and core to send syslog to the Vector host.

**Example (pod switch or core):**

```text
configure terminal
logging host 198.18.134.22 transport udp port 514
logging trap informational
logging source-interface GigabitEthernet1
end
write memory
```

- Replace `198.18.134.22` with the host where the stack runs.
- `logging trap informational` sends severity 6 and below; use `debugging` (7) or `warning` (4) as needed.
- `logging source-interface` is optional (use management interface).

**Verify:** On device `show logging`; in ClickHouse query `default.syslog` (see [clickhouse/README.md](../clickhouse/README.md)).

## Config files

Vector config is in the repo root (e.g. `vector/vector.toml` or as defined in compose). Ensure `sources.syslog` (type `syslog`, mode `udp`, address `0.0.0.0:514`) and `sinks.clickhouse` (endpoint `http://netops-stack-clickstack:8123`, table `syslog`) match your compose service names.

## IPFIX / NetFlow / sFlow

Flow telemetry (IPFIX, NetFlow v9, sFlow) is handled by a **separate** container (see root [README](../README.md) and `compose-ipfix.yaml`), not by Vector. Ports: IPFIX 4739, NetFlow 2055, sFlow 6343. Point devices at the host IP and the corresponding port.
