# netops-stack

Copyright (c) 2026 Cisco and/or its affiliates. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

Deploy netops-stack via Docker Compose on a single container host.

## Docker Compose Deployment
```bash
git clone https://github.com/pamosima/netops-stack.git
cd netops-stack
docker compose -f compose.yaml -f compose-clickstack.yaml up -d
```
(See [README.md](README.md) for overlay options; set `NETOPS_STACK_HOST` in `.env`.)

### Configuration
You can customize the deployment by modifying the compose files before starting the stack.
You can find the configuration files for each component in the following directories:
- gNMIc ingestor: `gnmic/`
- gNMIc emitter: `gnmic/`
- NATS: `nats/`
- Prometheus: `prometheus/`
- Grafana: `grafana/`
