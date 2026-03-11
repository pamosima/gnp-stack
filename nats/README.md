# NATS

NATS is the **message bus** between gNMIc and downstream processors (e.g. Prometheus exporter, optional writers). Used when the stack runs the gNMIc → NATS → Prometheus pipeline.

## Role

- gNMIc publishes telemetry to NATS subjects.
- Subscribers (in the same compose) consume and expose metrics or forward to ClickHouse as configured.
- No direct user configuration required for basic deployment; config is in the compose and component configs (gNMIc, Prometheus).

## Related

- [gNMIc](../gnmic/README.md) — Publisher.
- [Prometheus](../prometheus/README.md) — Consumer in the default pipeline.
