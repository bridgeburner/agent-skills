# Fixture: accepted sentinel crosses a closed consumer

Review boundary: one PR changes a delivery-import API. The stated product
outcome is: "Unknown carrier service labels should be accepted and reported;
they must not stop unrelated deliveries from loading."

The PR makes these changes:

- The API maps an unrecognized service label to `UNCLASSIFIED`, stores that
  value in `delivery_records.service_classes`, returns an `unknown_services`
  count, and retains the response for an admin receipt page.
- Conflict detection ignores `UNCLASSIFIED` when deciding whether recognized
  service classes disagree. A same-window `{PRIORITY, UNCLASSIFIED}` import is
  accepted with only the generic unknown count.
- The nightly loader still constructs a closed `ServiceClass` enum from every
  stored value. `PRIORITY + UNCLASSIFIED` raises while grouping a delivery.
  The exception is caught at the tenant batch boundary, so unrelated
  deliveries for that tenant are not loaded.
- A compatibility overload keeps old workers able to annotate a receipt
  without the new response. If a new worker writes `response_json` first, an
  old worker refuses to overwrite it; the route swallows that refusal. Import
  succeeds, but the admin page can display the earlier response until all
  workers converge. The fixture does not establish the durable winner for
  other write orders or the mechanism that refreshes a stale receipt.
- Responses smaller than 8 KiB are retained verbatim. One normal response
  shape contains `schema_errors[].fields`, whose values are source-authored
  column names. The adapter documentation says source column names never enter
  a durable audit surface. Tenant authorization and the 8 KiB bound are sound.
- `legacy_imports.raw_header` also retains a source-authored label, but that
  table and field pre-date the PR and are untouched by its diff.

Repository artifacts:

- The PR template has separate `Removed:` and `Avoided:` fields and says final
  PRs linked to a work item use `Fixes TASK-<number>` when merge should close
  the work item.
- This is the final PR linked to `TASK-482`, and merge is intended to close the
  work item. The PR body uses one `Removed/avoided:` bullet, omits the closing
  phrase, and claims: "No source-authored label is stored durably."
- Focused API tests prove the HTTP 200 response, stored `UNCLASSIFIED`, generic
  count, size bound, and tenant authorization. No test sends the stored value
  through the nightly loader or exercises mixed old/new workers.

Treat the multi-PR migration/version-number problem as out of scope for this
fixture. Remain read-only.
