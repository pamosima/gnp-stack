# ClickStack (HyperDX) — single ClickHouse for the stack

[ClickStack](https://clickhouse.com/docs/use-cases/observability/clickstack) is ClickHouse’s observability stack: HyperDX UI, OpenTelemetry collector, and ClickHouse for logs, traces, and metrics.

gnp-stack uses **ClickStack as the only ClickHouse** (default port 8123). Syslog (Vector) and Prometheus remote_write/read use `gnp-stack-clickstack:8123` (or `:9363` for Prometheus).

## Ports

| Port  | Service           | Note                          |
|-------|-------------------|-------------------------------|
| 8080  | HyperDX UI        | Open http://\<host\>:8080     |
| 8123  | ClickHouse HTTP   | Default; syslog, queries      |
| 9363  | ClickHouse Prometheus | /metrics, /write, /read   |
| 4317  | OTLP gRPC         | Traces/logs/metrics ingest   |
| 4318  | OTLP HTTP         | Traces/logs/metrics ingest   |
| 24225 | Fluentd           | Log ingest                    |
| 8888  | Collector metrics | Scrape for monitoring         |
| 13133 | Health            | Collector health check        |

## Deploy

With the base stack already up:

```bash
docker compose -f compose.yaml -f compose-clickstack.yaml up -d
```

Or with full stack (IOS-XE, IPFIX, syslog):

```bash
docker compose -f compose.yaml -f compose-iosxe.yaml -f compose-ipfix.yaml \
  -f compose-clickstack.yaml -f compose-syslog.yaml up -d
```

## First use

1. Open **http://\<host\>:8080** (e.g. http://198.18.134.22:8080). If you use port **8081** (e.g. because 8080 is in use), open http://\<host\>:8081 and set **HYPERDX_APP_URL** (see below) so login redirects work.
2. Create a user (username + password meeting the requirements).
3. HyperDX will create data sources for the local ClickHouse (logs, traces, metrics, sessions).
4. Send OTLP data to **\<host\>:4317** (gRPC) or **\<host\>:4318** (HTTP), or use the [sample data / local collector](https://clickhouse.com/docs/use-cases/observability/clickstack/getting-started/oss) docs.

**Login redirects to localhost:** The HyperDX UI may redirect to `http://localhost:8080` after login; that fails when you open the UI by IP (e.g. http://198.18.134.22:8081). **Workaround:** use an SSH tunnel so that “localhost” in the browser is the server:

```bash
# Forward local 8080 and 8081 to the server’s HyperDX port (8081 on host when using -p 8081:8080)
ssh -L 8080:127.0.0.1:8081 -L 8081:127.0.0.1:8081 user1@198.18.134.22
```

Then open **http://localhost:8081** in your browser and log in. The redirect to `http://localhost:8080/search` will use the other tunnel and still reach the same app.

## Data

- **ClickHouse** is inside the ClickStack container; host port **8123** (HTTP) and **9363** (Prometheus). All syslog and Prometheus TimeSeries data live here.
- **default.syslog** is created by `clickstack-syslog-init` when using `compose-syslog.yaml`; you can also create it manually (e.g. run the SQL in `clickhouse/init/syslog.sql` against ClickHouse).
