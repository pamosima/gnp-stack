# GitLab pipeline setup (netops-stack/orchestrator)

Use this after you have created the **netops-stack/orchestrator** project on GitLab. The pipeline is LTROPS-2341 style: NetBox inventory, collect stage, verify (dry-run), deploy (manual).

## Push this repo to GitLab

If this code lives in GitHub and you want the same content in GitLab:

```bash
# Add GitLab as a remote (use your group/project URL)
git remote add gitlab https://gitlab.com/netops-stack/orchestrator.git
# Or self-hosted: git remote add gitlab https://gitlab.example.com/netops-stack/orchestrator.git

# Push main (and any other branches you use)
git push gitlab main
```

If you prefer to start from a fresh GitLab project, clone this repo and change the remote:

```bash
git clone https://github.com/pamosima/gnp-stack.git netops-orchestrator && cd netops-orchestrator
git remote set-url origin https://gitlab.com/netops-stack/orchestrator.git
git push -u origin main
```

## GitLab CI/CD variables (masked)

In **Settings → CI/CD → Variables**, add:

| Variable            | Type    | Masked | Purpose                          |
|---------------------|---------|--------|----------------------------------|
| `NETBOX_URL`        | Variable| ✓      | NetBox API URL                   |
| `NETBOX_TOKEN`      | Variable| ✓      | NetBox API token                 |
| `ANSIBLE_USER`      | Variable| ✓      | SSH user for devices             |
| `ANSIBLE_PASSWORD`  | Variable| ✓      | SSH password (or use key in image) |
| `ANSIBLE_IMAGE`     | Variable| —      | Docker image with Ansible + cisco.ios + netbox.netbox |

**ANSIBLE_IMAGE** is required: use an image that has `ansible`, `cisco.ios`, and `netbox.netbox` collections (e.g. build from [LTROPS-2341 docker/](https://github.com/tspuhler/LTROPS-2341) or your own Dockerfile).

## When the pipeline runs

- **collect_configs:** Runs when pipeline source is **schedule**, **trigger** (with `COLLECT_PIPELINE=true`), **web** (with `COLLECT_PIPELINE=true`), or **api**. Artifact: `collected/` (7 days).
- **apply_dry-run:** Runs when `DRY_RUN_PIPELINE=true` (trigger or web). Artifact: `ansible/ansible_dry_run_output.log` for GitLab MCP.
- **apply_config:** Manual only (click "Play" in GitLab).

## Scheduled collect

In **CI/CD → Schedules**, create a schedule (e.g. daily 02:00) and set variable `COLLECT_PIPELINE=true` so the collect job runs.
