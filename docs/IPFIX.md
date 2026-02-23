# IPFIX / NetFlow / sFlow integration

Optional flow telemetry using the [Untersander gnp-stack-ipfix](https://github.com/Untersander/gnp-stack/pkgs/container/gnp-stack%2Fgnp-stack-ipfix) container image. It fits alongside the existing gNMIc–NATS–Prometheus stack so you can collect both streaming telemetry and flow export from the same host.

## Enable in this repo

1. **Start the stack with the IPFIX overlay:**

   ```bash
   docker compose -f compose.yaml -f compose-ipfix.yaml up -d
   ```

   With IOS-XE as well:

   ```bash
   docker compose -f compose.yaml -f compose-iosxe.yaml -f compose-ipfix.yaml up -d
   ```

2. **Ports** (host → container):

   | Protocol | Port (UDP) | Purpose        |
   |----------|------------|----------------|
   | IPFIX    | 4739       | Flow export    |
   | NetFlow v9 | 2055    | Flow export    |
   | sFlow    | 6343       | Sampled flows  |
   | HTTP     | 8081       | Prometheus metrics (scraped by Prometheus) |

3. **Prometheus** already has a scrape job for `gnp-stack-ipfix:8081` when the IPFIX service is running. No extra config needed.

## Pointing devices at the collector

Use the **host** IP where the stack runs (e.g. `198.18.134.22` in the lab). Configure each device to send IPFIX/NetFlow/sFlow to that IP and the port above.

**Cisco IOS-XE (example):**

```text
flow exporter GNP-STACK
 destination 198.18.134.22
 transport udp 4739
 source <interface>
!
flow monitor FM-IPFIX
 exporter GNP-STACK
 record netflow ipv4 original-input
!
interface GigabitEthernet1
 ip flow monitor FM-IPFIX input
```

**sFlow (e.g. Cisco, Arista):** set the collector to `198.18.134.22:6343`.

## Image and releases

- **Image:** `ghcr.io/untersander/gnp-stack/gnp-stack-ipfix:0.0.1`
- **Source / package:** [gnp-stack/gnp-stack-ipfix](https://github.com/Untersander/gnp-stack/pkgs/container/gnp-stack%2Fgnp-stack-ipfix) (Untersander fork of gnp-stack; release `gnp-stack-ipfix-0.0.1`).

If the container uses a different metrics port than 8081, change the `ports` and Prometheus scrape target in `compose-ipfix.yaml` and `prometheus/prometheus.yaml` to match.

## Grafana

Flow metrics from the IPFIX container will appear in Prometheus. You can add a new dashboard or panels that query the job `job="ipfix"` (or the metric names the image exposes). The existing gNMIc dashboards are unchanged.
