# Goal: PHP-to-Native Compiler Swarm

Build a truthful PHP-to-native compiler that can compile and run broad PHP as a native executable, pass an expanding subset of the PHP core `.phpt` test suite, and run WordPress through real bootstrap and request flows.

The work must be supervised as a long-running, high-discipline swarm of 110 agents. The supervisor owns planning, queueing, worker health, integration, testing, dashboards, and progress accounting. Worker sessions must stay active, useful, and mapped to hard compiler milestones.

## Definition Of Done

The project is successful when:

- `phpc run` remains a reliable interpreter reference for supported PHP.
- `phpc compile` can produce linked native executables, not only IR or assembly snapshots.
- Native execution matches `phpc run` and system PHP for committed fixtures.
- A meaningful, documented subset of php-src `.phpt` tests runs through the compiler harness.
- WordPress can be bootstrapped and exercised through pinned real entrypoints, with blockers reduced to general PHP/compiler gaps.
- Progress is measured by primary-integrated, tested behavior only, not scaffolding, local-only patches, generated fixtures, or activity volume.

## Primary Milestones

1. Consolidate copy-on-write semantics into shared runtime mechanisms.
2. Make the native runtime ABI a real PHP value ABI.
3. Add linked native execution.
4. Expand native lowering until it catches up with `phpc run`.
5. Build a scalable PHP differential test harness around php-src `.phpt` tests.
6. Build a real WordPress compatibility harness.
7. Keep object, request/SAPI, stream, filesystem, session, and database work general.
8. Optimize only after truthful native execution exists.

## Non-Negotiables

- No destructive git commands.
- Do not revert or overwrite another lane's dirty work.
- Do not count bridge calls, wrappers, fixture generation, probes, or shell-outs as native compiler progress.
- No case-by-case PHP semantic patches unless they create a shared mechanism or unblock a named milestone.
- Keep one independent auditor active at all times.
- Keep durable status in `progress.md` and a browsable generated dashboard in `progress.html`.
- Every worker gets an isolated worktree and a unique `CARGO_TARGET_DIR`.
- Run tests periodically and record failures honestly.

## Required Evidence

Every completed slice must include:

- A named milestone.
- A minimized repro or fixture.
- A code change integrated into the primary branch or queued with an explicit integration note.
- Focused tests.
- Updated docs or status when behavior changes.
- A verification record with commands, pass/fail state, and current blocker.

## High-Level Swarm Shape

The supervising session is outside the 110-agent count. The 110 supervised agents start with this allocation:

- 1 auditor/critic.
- 8 integration and release-safety agents.
- 12 runtime ABI agents.
- 12 native linked-execution and linker agents.
- 16 native lowering agents.
- 16 PHP core `.phpt` harness and differential-testing agents.
- 12 WordPress compatibility agents.
- 10 object/model/reference/COW agents.
- 8 SAPI/request/stream/filesystem/session agents.
- 8 defect-mining and minimization agents.
- 7 documentation, dashboard, progress, and operations agents.

The exact allocation may change as blockers move, but every live worker must be attached to a current queue item and a milestone.
