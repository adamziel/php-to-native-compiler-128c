# Swarm Agents

Target: 100 implementation/research workers plus one auditor when enabled. The supervisor and dashboard windows are outside the count.

Workers are launched in tmux session `phpc-swarm`. Each worker gets:

- unique lane id;
- isolated worktree under `/home/ubuntu/phpc-worktrees/<lane-id>`;
- unique cargo target directory under `/home/ubuntu/phpc-targets/<lane-id>`;
- handoff path under `swarm/handoffs/<lane-id>.md`;
- queue item and milestone.

## Initial Groups

- `INT-01` through `INT-08`: integration and safety.
- `ABI-01` through `ABI-12`: runtime ABI.
- `LINK-01` through `LINK-12`: linked native execution.
- `LOW-01` through `LOW-16`: native lowering.
- `PHPT-01` through `PHPT-16`: PHP core `.phpt` harness.
- `WP-01` through `WP-12`: WordPress compatibility.
- `SEM-01` through `SEM-10`: COW, references, objects.
- `SAPI-01` through `SAPI-08`: request/SAPI/streams/filesystem/sessions.
- `MINE-01` through `MINE-03`: defect mining and minimization.
- `DOC-01` through `DOC-03`: docs/dashboard/operations.
- `AUD-01`: independent auditor.

See `swarm/worker-prompts/` after launch for each lane prompt.
