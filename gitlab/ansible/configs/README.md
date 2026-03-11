# Configs directory

- **`desired/`** — Desired config per host for the **apply** pipeline.
  - Add or edit `desired/<hostname>.txt` (e.g. `desired/sw11-1.txt`) with the config block to apply (IOS-XE format).
  - Trigger the GitLab pipeline with **dry-run** first; review the diff, then run **manual apply**.
  - When troubleshooting with MCP (e.g. IOS-XE), the assistant can suggest changes; you (or the GitLab MCP server) update the file here and trigger the pipeline.

Use **rollback** (to `baseline/<hostname>.txt`) to restore the last baseline instead of applying from `desired/`.
