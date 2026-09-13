# Ambient effects

Read this reference when a change mutates process-wide, runtime-wide,
host-wide, environment, registry, singleton, or other shared state. Skip it for
state owned by one request or operation that has no shared observer.

- Trace the effect across its actual visibility domain, including plugins,
  diagnostics, workers, and other consumers that bypass the feature's public
  API. Correct authority to mutate shared state does not prove compatibility.
- Establish the narrowest valid lifetime and explicit ownership. Check partial
  installation, overlap, concurrent users, duplicate cleanup, process death,
  restart, and both teardown orders. Cleanup must remove only its own effect;
  it must not restore a stale snapshot, overwrite an intervening mutation, or
  resurrect a stopped owner.
- Compare the feature-local behavior with what foreign consumers observe at
  each transition. A test that starts and stops one owner in isolation does not
  prove shared-state compatibility.
- If the effect cannot be made safely ambient, prefer a request-local or
  explicitly owned mechanism. State the smallest source-backed proof needed to
  establish containment or compatibility.
