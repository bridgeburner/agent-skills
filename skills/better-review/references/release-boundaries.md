# Release and configuration boundaries

Read this reference when a change crosses environments or identities, changes
machine access or route bindings, claims an exact configuration value, or is a
stacked PR. Skip the sections whose trigger is absent.

- Trace one operation through requester, authorizer, handoff identities,
  mutation authority, and final consumer. Separate valid grants in adjacent
  environments do not prove that any actor can complete the operation.
- For a machine principal, route, binding, or protected resource, build the
  smallest relevant principal-by-route allow/deny check. Inspect only directly
  coupled inventories, comments, outputs, and runbooks for stale identity or
  invoker claims.
- For a configuration contract, trace `source of truth -> exact expected value
  -> assertion -> workflow/job invocation -> required check`. Presence-only or
  hand-run checks do not prove the value is enforced; an absence test must cover
  every path that could violate the claim.
- For a stacked PR, establish the actual parent head and ancestry before
  reviewing the delta. After a squash merge, rebuild on the resulting parent,
  then compare patch identity, final file/resource scope, and fresh applicable
  checks or plans. Retargeting alone is not proof.
