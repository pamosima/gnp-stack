# Ansible playbooks for netops-stack orchestrator

Config collection (and later diff/apply) for the [Orchestrator](docs/ORCHESTRATOR-ANSIBLE-GITLAB.md) extension. **Inventory is NetBox only** (no static host file), aligned with the [LTROPS-2341](https://github.com/tspuhler/LTROPS-2341) pattern (GitLab CI/CD, NetBox, Ansible).

## Layout

| Path | Purpose |
|------|---------|
| `playbooks/collect_configs.yml` | Collect running config from all NetBox devices; write to `collected/<hostname>.txt`. |
| `inventory/nb_inventory.yml` | NetBox dynamic inventory (plugin config). |
| `group_vars/all.yml` | Default connection vars (network_cli, cisco.ios.ios, user from env). |
| `requirements.yml` | Galaxy collections: `cisco.ios`, `ansible.netcommon`, `netbox.netbox`. |

## Prerequisites

1. **Install collections** (from repo root):
   ```bash
   ansible-galaxy collection install -r ansible/requirements.yml
   ```

2. **NetBox:** Devices must have **status: active** and a **primary IP** (used as `ansible_host`). Set **platform** (e.g. Cisco IOS) in NetBox so the correct network OS is used, or rely on `group_vars/all.yml` default (`cisco.ios.ios`).

3. **Environment variables** (never commit):
   - **NetBox:** `NETBOX_URL`, `NETBOX_TOKEN`. Optional: `NETBOX_VERIFY_SSL=false` for self-signed.
   - **SSH:** `ANSIBLE_USER`, and either `ANSIBLE_PASSWORD` or `ANSIBLE_SSH_PRIVATE_KEY_FILE`.

## Run collect locally

From repo root:

```bash
# All devices (NetBox query_filters: status=active)
ansible-playbook ansible/playbooks/collect_configs.yml -i ansible/inventory/nb_inventory.yml

# Limit by hostname or NetBox group (sites_*, device_roles_*)
ansible-playbook ansible/playbooks/collect_configs.yml -i ansible/inventory/nb_inventory.yml -l core-01

# Custom output directory (e.g. for CI)
COLLECTED_DIR=collected ansible-playbook ansible/playbooks/collect_configs.yml -i ansible/inventory/nb_inventory.yml
```

Configs are written to `collected/<hostname>.txt`.

## GitLab CI (LTROPS-2341 style)

In **netops-stack/orchestrator**, set CI/CD variables (masked): `NETBOX_URL`, `NETBOX_TOKEN`, `ANSIBLE_USER`, `ANSIBLE_PASSWORD` (or use SSH key in the runner image). Then run:

```yaml
collect_configs:
  stage: collect
  script:
    - ansible-playbook -i ./ansible/inventory/nb_inventory.yml ./ansible/playbooks/collect_configs.yml
  artifacts:
    paths:
      - collected/
```

Use a Docker image that has Ansible plus the `cisco.ios` and `netbox.netbox` collections (e.g. build from [LTROPS-2341 docker/](https://github.com/tspuhler/LTROPS-2341) or similar).

See [ORCHESTRATOR-ANSIBLE-GITLAB.md](ORCHESTRATOR-ANSIBLE-GITLAB.md) for the full pipeline design (scheduled collect, diff, MCP-triggered dry-run).
