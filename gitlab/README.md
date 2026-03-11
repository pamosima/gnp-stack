# GitLab CI/CD + Ansible (Orchestrator)

This folder contains the **Orchestrator** extension for netops-stack: GitLab CI/CD pipelines and Ansible playbooks for config collection, compare (drift), apply (dry-run then manual), and rollback. Pipelines can be triggered via API (e.g. from the [NetOps MCP Server](../netops-mcp-server/README.md)) for AI-driven workflows.

## Repository layout

Push the **contents** of `gitlab/` to your GitLab project (this folder becomes the repo root there).

| Path | Purpose |
|------|--------|
| `.gitlab-ci.yml` | Pipeline: collect → verify (compare, apply dry-run, rollback verify) → deploy (manual apply/rollback). |
| `ansible/playbooks/collect_configs.yml` | Collect running config; write to `configs/baseline/<hostname>.txt`. |
| `ansible/playbooks/compare_configs.yml` | Compare running vs baseline; uses shared `diff_baseline.yml`. |
| `ansible/playbooks/diff_baseline.yml` | Shared: diff running vs baseline, write `configs/baseline/<hostname>.diff` when different. |
| `ansible/playbooks/rollback_configs.yml` | Rollback devices to baseline; optional Cisco configure replace from URL. |
| `ansible/playbooks/apply_config.yml` | Apply desired config from `ansible/configs/desired/<hostname>.txt`; dry-run then manual apply. |
| `ansible/inventory/` | NetBox dynamic inventory (`nb_inventory.yml`). |
| `Dockerfile`, `requirements.yml` | Ansible runner image. |

Credentials (SSH, NetBox token, device passwords) must **not** be in the repo: use GitLab CI/CD variables (masked).

---

## Pipeline setup

1. **Create project** on GitLab (e.g. `netops-stack/network-automation`).
2. **Push this folder** as the repo (or add GitLab as remote and push `gitlab/` contents to the project root).
3. **CI/CD variables** (Settings → CI/CD → Variables): add `NETBOX_URL`, `NETBOX_TOKEN`, `ANSIBLE_USER`, `ANSIBLE_PASSWORD` (masked). Optionally `GITLAB_PUSH_TOKEN` for committing baseline configs or removing .diff after rollback.
4. **Default image:** Build from this repo: `docker build -f gitlab/Dockerfile gitlab/ -t your-registry/ansible:latest`. Set the project’s default image or use `ANSIBLE_IMAGE` variable.
5. **Schedules:** For periodic collect, create a schedule (e.g. daily) with variable `COLLECT_PIPELINE=true`.

---

## When pipelines run

| Intent | Variables | Jobs |
|--------|-----------|------|
| **Compare** (drift vs repo baseline) | `COMPARE_ONLY=true` or `PIPELINE_TYPE=compare` | `compare_configs` |
| **Collect** | `PIPELINE_TYPE=collect` or `COLLECT_PIPELINE=true` | `collect_configs` |
| **Apply** (dry-run → manual apply) | `DRY_RUN_PIPELINE=true`, `PIPELINE_TYPE=apply`, optional `TARGET_HOST=sw11-1` | `apply_dry-run`, manual `apply_config` |
| **Rollback** (dry-run → manual apply) | `ROLLBACK_PIPELINE=true`, `PIPELINE_TYPE=rollback`, optional `TARGET_HOST=sw11-1` | `rollback_verify`, manual `rollback_apply` |

Trigger via GitLab UI (Run pipeline with variables) or API (e.g. NetOps MCP server with `GITLAB_TOKEN`). After rollback_apply, the pipeline removes `.diff` files from the repo (commit and push).

---

## Rollback options

### Default: Ansible ios_config replace block

- Playbook applies the baseline with `ios_config` `replace: block`.
- For config present on device but **absent** from baseline (e.g. extra `vlan 999`), the playbook parses the diff and runs “no vlan” (and similar) before applying the baseline.

### Optional: Cisco configure replace

For **true replace** (device adds and removes to match a full config file) and optional confirmed rollback:

- Set CI variables: `ROLLBACK_USE_CONFIGURE_REPLACE=true`, `ROLLBACK_BASELINE_URL_BASE=http://<gitlab>/<project>/-/raw/main/ansible/configs/baseline` (or a URL the device can reach).
- The playbook runs `configure replace <url> force` on the device. The baseline must be a **complete** Cisco IOS XE config; the device must be able to fetch the URL (HTTP).
- **Confirmed rollback:** On device, `configure replace flash:file time 5` then `configure confirm` within 5 minutes, or the device reverts automatically. See [Cisco Configuration Replace](https://www.cisco.com/c/en/us/td/docs/switches/lan/c9000/mgmt/config-replace/configuration-replace.html).

### Optional: NETCONF/YANG path

For candidate datastore and confirmed commit, an optional NETCONF-based rollback playbook can be added (separate connection and playbook) using `netconf_config` and Cisco IOS-XE NETCONF (port 830). Requires NETCONF enabled on devices and `ansible.netcommon.netconf`; see Cisco Programmability Configuration Guide for IOS XE.

---

## MCP integration

The [NetOps MCP Server](../netops-mcp-server/README.md) can trigger pipelines with the variables above and fetch job logs/artifacts. Set `GITLAB_URL` and `GITLAB_TOKEN` (project or personal access token with `api` scope) in the MCP server `.env`. Use `gitlab_trigger_gitlab_pipeline`, `gitlab_get_gitlab_pipeline_status`, `gitlab_play_gitlab_job`, and `gitlab_get_gitlab_job_logs` for dry-run and rollback flows.

---

## Related

- [LTROPS-2341](https://github.com/tspuhler/LTROPS-2341) — Reference GitLab CI/CD + Ansible + NetBox + pyATS demo.
- Root [README.md](../README.md) — Architecture and quick start.
