# Syslog configuration for all pods and core

Configure every **pod switch** (sw11-1 … sw15-1) and the **core** (c8k-core01) to send syslog to the gnp-stack Vector receiver at **198.18.134.22** on port **514** (UDP).

**Prerequisites:** Vector is running (`compose-syslog.yaml`); devices have IP reachability to 198.18.134.22.

---

## Syslog server

| Setting   | Value              |
|----------|--------------------|
| Host     | **198.18.134.22** |
| Port     | **514** (UDP)      |
| Receiver | Vector → ClickHouse |

---

## 1. Pod switches (sw11-1 … sw15-1)

Same configuration on all five pod switches. Apply via CLI (SSH to each) or use the Ansible playbook below.

### IOS-XE CLI (copy-paste on each pod switch)

```text
configure terminal
logging host 198.18.134.22 transport udp port 514
logging trap informational
logging source-interface GigabitEthernet1
end
write memory
```

- **`logging host 198.18.134.22 transport udp port 514`** — sends syslog to the Vector host on UDP 514.
- **`logging trap informational`** — sends severity 6 (informational) and below (0–6); adjust to `debugging` (7) or `warning` (4) as needed.
- **`logging source-interface GigabitEthernet1`** — optional; use the management interface so logs use a consistent source IP. Replace with your switch’s management interface (e.g. `Vlan1` or `GigabitEthernet1`).

**Per-pod access:** Use the management or NAT address for your pod so the gnp-stack host can reach the device.

---

## 2. Core (c8k-core01)

Apply on **c8k-core01** (198.18.170.200).

### IOS-XE CLI (copy-paste on core)

```text
configure terminal
logging host 198.18.134.22 transport udp port 514
logging trap informational
logging source-interface GigabitEthernet1
end
write memory
```

Use the core’s management or WAN interface for `logging source-interface` if different (e.g. the interface toward 198.18.x).

---

## 3. Verify

- **On device:** `show logging` — confirm host 198.18.134.22 and trap level.
- **On gnp-stack host:** Query ClickHouse (ClickStack) at http://198.18.134.22:8123:
  ```sql
  SELECT host, severity, message, timestamp
  FROM default.syslog
  ORDER BY timestamp DESC
  LIMIT 20;
  ```
  Use the device hostname or source IP as `host` (Vector may use source IP or parsed hostname).

---

## 4. Optional: Ansible playbook

If your lab uses Ansible and you have an inventory with the pod switches and core, you can apply syslog with the playbook in **`ansible/syslog-all-devices.yaml`** (see below). Run from a host that can reach 198.18.170.201–205 and 198.18.170.200 (e.g. 198.18.134.22 or the lab Code Server).

---

## Device summary

| Device   | Role    | IP (from 198.18.x)  | Apply syslog config |
|----------|---------|----------------------|----------------------|
| sw11-1   | Pod 1   | 198.18.170.201       | Yes (same as pods)  |
| sw12-1   | Pod 2   | 198.18.170.202       | Yes                 |
| sw13-1   | Pod 3   | 198.18.170.203       | Yes                 |
| sw14-1   | Pod 4   | 198.18.170.204       | Yes                 |
| sw15-1   | Pod 5   | 198.18.170.205       | Yes                 |
| c8k-core01 | Core  | 198.18.170.200       | Yes (core block)    |
