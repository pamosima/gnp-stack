# gnp-stack

gNMIc–NATS–Prometheus observability stack for network streaming telemetry and logs. One repo, Docker Compose, optional syslog and IPFIX — built to plug into AI/MCP troubleshooting.

## What’s in the box

- **Ingestion:** gNMIc (gNMI streaming), Vector (syslog UDP 514), optional IPFIX/NetFlow/sFlow
- **Storage:** ClickStack (ClickHouse + HyperDX UI), Prometheus (scrape + remote_write to ClickHouse)
- **Visualisation:** Grafana, HyperDX (logs, traces, metrics)

You choose which pieces to run via compose overlays. See [docs/CLICKSTACK.md](docs/CLICKSTACK.md) for deployment and ports.

## Quick start

1. Copy [.env.example](.env.example) to `.env` and set `GNP_STACK_HOST` to the IP or hostname where you run the stack.

2. Base + ClickStack (HyperDX, ClickHouse, Prometheus integration):
   ```bash
   docker compose -f compose.yaml -f compose-clickstack.yaml up -d
   ```
   Open http://\<host\>:8080 for HyperDX; create a user on first use.

3. Full stack with IOS-XE, IPFIX, and syslog:
   ```bash
   docker compose -f compose.yaml -f compose-iosxe.yaml -f compose-ipfix.yaml \
     -f compose-clickstack.yaml -f compose-syslog.yaml up -d
   ```

## Extensions

- **C9k / IOS-XE:** [docs/ROADMAP-CML-MCP.md](docs/ROADMAP-CML-MCP.md), `gnmic/gnmic-ingestor-iosxe.yaml`, overlay `compose-iosxe.yaml`
- **Syslog:** [docs/SYSLOG-DESIGN.md](docs/SYSLOG-DESIGN.md), [docs/SYSLOG-DEVICE-CONFIG.md](docs/SYSLOG-DEVICE-CONFIG.md), overlay `compose-syslog.yaml`
- **MCP troubleshooting:** [docs/MCP-TROUBLESHOOTING-DEMO.md](docs/MCP-TROUBLESHOOTING-DEMO.md)
- **gNMI, syslog, and open-source MCP:** [docs/GNMI-VS-SYSLOG-AND-OPEN-SOURCE-MCP.md](docs/GNMI-VS-SYSLOG-AND-OPEN-SOURCE-MCP.md)

## Background

More on the motivation and history: [ARCHAEOLOGY.md](ARCHAEOLOGY.md).

## Contributing and license

- **Contributing:** See [CONTRIBUTING.md](CONTRIBUTING.md) for how to submit changes and open pull requests.
- **Code of conduct:** This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
- **License:** This project is licensed under the Cisco Sample Code License, Version 1.1 — see the [LICENSE](LICENSE) file for details. This is example code for demonstration and learning; it is not officially supported by Cisco and is not intended for production use without proper testing and customization.
