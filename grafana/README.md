# Grafana

Grafana provides **dashboards** over Prometheus (and optional datasources). It is part of the base stack.

## Config

- **Provisioning:** `grafana/provisioning/` — datasources and dashboard providers.
- **Dashboards:** `grafana/dashboards/` — JSON dashboards (e.g. netops-stack metrics, gNMIc).

## Deploy

Started with the base compose. Default port 3000 (or as mapped in compose). Log in and add or import dashboards; provisioning may auto-load datasources and dashboards from the repo.

## Related

- [Prometheus](../prometheus/README.md) — Primary metrics source.
- [ClickHouse](../clickhouse/README.md) — Optional datasource for logs/metrics when using ClickStack.
