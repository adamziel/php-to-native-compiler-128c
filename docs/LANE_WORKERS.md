# Lane Workers

Workers are assigned one queue item at a time. They should:

- inspect current state before editing;
- keep changes small;
- add focused tests;
- update handoff notes in `swarm/handoffs/`;
- avoid unrelated formatting;
- stop and report precise blockers.

The supervisor integrates work after focused verification.

