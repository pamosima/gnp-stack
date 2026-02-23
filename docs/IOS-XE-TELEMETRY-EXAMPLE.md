# IOS-XE telemetry subscription example (dial-out)

Reference for the Cisco IOS-XE **dial-out** telemetry configuration you provided, and how it maps to gnp-stack (dial-in vs dial-out).

## Example configuration (device-side)

```
telemetry ietf subscription 101
 encoding encode-kvgpb
 filter xpath /process-cpu-ios-xe-oper:cpu-usage/cpu-utilization/five-seconds
 source-address 198.18.130.10
 stream yang-push
 update-policy periodic 500
 receiver ip address 198.18.133.102 57000 protocol grpc-tcp
```

### Line-by-line

| Line | Meaning |
|------|--------|
| `telemetry ietf subscription 101` | Subscription ID 101 (IETF dial-out subscription). |
| `encoding encode-kvgpb` | Encode telemetry as Key-Value Google Protocol Buffers. |
| `filter xpath /process-cpu-ios-xe-oper:cpu-usage/cpu-utilization/five-seconds` | Only send CPU utilization (5-second). Uses IOS-XE native YANG path. |
| `source-address 198.18.130.10` | Source IP used by the device when opening the gRPC connection (useful with multiple interfaces). |
| `stream yang-push` | Push model (device pushes to receiver). |
| `update-policy periodic 500` | Send every **500 centiseconds** = **5 seconds**. |
| `receiver ip address 198.18.133.102 57000 protocol grpc-tcp` | **Collector**: device connects to **198.18.133.102** on port **57000** using gRPC over TCP. |

So the **telemetry receiver** (collector) must **listen** on `198.18.133.102:57000` (or the IP of the host where the receiver runs). The device **initiates** the connection to that address.

---

## Dial-out vs dial-in (gnp-stack)

| Mode | Who connects | Device config | Collector (gnp-stack) |
|------|----------------|----------------|----------------------|
| **Dial-in** (current gnp-stack) | Collector → device | gNMI enabled (port 57400); no `receiver` needed | gNMIc **subscribe** with `targets:` (device IP:57400). |
| **Dial-out** | Device → collector | `receiver ip address <collector-ip> <port> protocol grpc-tcp` | gNMIc **listen** on `<collector-ip>:<port>`. |

- Your example is **dial-out**: the device pushes to **198.18.133.102:57000**.
- gnp-stack’s **gnmic-ingestor** today uses **dial-in**: it connects to each device (e.g. 198.18.170.201:57400 for Pod 1) and subscribes. No `receiver` on the device for that.

---

## Using this example in your lab

### Option A: Keep dial-in (current gnp-stack)

- Do **not** add `receiver ip address ...` on the device.
- Ensure **gNMI** is enabled on the device (port **57400**).
- Point gnp-stack’s **gnmic-ingestor** at the device (e.g. NAT addresses 198.18.170.201–205 or 10.99.x.11) as in `gnmic-ingestor-iosxe.yaml`.
- gNMIc uses **Subscribe** RPC and OpenConfig/native paths defined in the ingestor config.

### Option B: Use dial-out (device pushes to gnp-stack)

1. **Receiver host**  
   Use the host where the collector runs, e.g. **gnp-stack host 198.18.134.22**. Then either:
   - Use **198.18.134.22** in `receiver ip address`, or
   - If the example must stay **198.18.133.102**, run the listener on 198.18.133.102 (different interface or host).

2. **Listener port**  
   Example uses **57000**. Start gNMIc in **listen** mode on that port:

   ```bash
   gnmic listen -a 0.0.0.0:57000
   ```

   (Add `--tls-cert` / `--tls-key` if you use TLS.)

3. **Device config** (per pod switch)  
   Adapt and apply on each CML switch (e.g. via IOS-XE MCP or console):

   ```
   telemetry ietf subscription 101
    encoding encode-kvgpb
    filter xpath /process-cpu-ios-xe-oper:cpu-usage/cpu-utilization/five-seconds
    source-address 10.99.1.1
    stream yang-push
    update-policy periodic 500
    receiver ip address 198.18.134.22 57000 protocol grpc-tcp
   ```

   - Use the switch’s **management IP** (or VLAN interface) for `source-address` (e.g. 10.99.1.1 for the gateway on Pod 1; the switch itself is 10.99.1.11, so `source-address 10.99.1.11` if you want the switch as source).  
   - Replace **198.18.134.22** with your actual gnp-stack/receiver host if different.  
   - Subscription ID (101) and port (57000) can stay or be changed consistently on device and listener.

4. **Integrate with gnp-stack**  
   gNMIc `listen` can write to files or other outputs; to feed **NATS/Prometheus** you’d need to run this listener and either:
   - configure it to produce output that another process (or gNMIc pipeline) sends to NATS, or  
   - extend the gnp-stack design to run a dial-out listener and forward into the same NATS streams.  
   (Current gnp-stack docs assume dial-in only.)

---

## More XPath filters (IOS-XE native)

If you add more dial-out subscriptions, typical IOS-XE native paths include:

- **Interfaces:**  
  `/interfaces/interface/state` (or OpenConfig-style paths depending on platform)
- **BGP:**  
  `/network-instances/network-instance/protocols/protocol/bgp/...`
- **Memory:**  
  `/memory-ios-xe-oper:memory-statistics/memory-statistic`

For **dial-in** with gnp-stack, equivalent data is often subscribed via **OpenConfig paths** in `gnmic-ingestor-iosxe.yaml` (e.g. `/interfaces/interface[name=*]/state/counters`), which gNMIc translates to the device.

---

## Quick reference

| Item | Example value | Your lab (suggestion) |
|------|----------------|------------------------|
| Receiver IP | 198.18.133.102 | **198.18.134.22** (gnp-stack host) |
| Receiver port | 57000 | **57000** (or free port on collector) |
| Source address | 198.18.130.10 | Per-pod switch IP (e.g. 10.99.1.11 for Pod 1) or gateway 10.99.x.1 |
| Update interval | 500 (5 s) | 500 or 1500 (15 s) to align with gnp-stack sample intervals |
