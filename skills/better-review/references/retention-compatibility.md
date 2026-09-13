# Retention and compatibility

Read this reference when a diff makes a response, request, event, diagnostic,
JSON/blob, or other source-authored object durable, or when old and new writers
or readers may overlap. Skip it when neither retention nor version overlap is a
claim or behavior in the change.

- Recursively inventory source-authored fields in normal and truncation paths.
  Check the actual bound, authorization, redaction, UI/API exposure, deletion,
  retention period, and documentation claim. Do not stop at the headline field
  that motivated storage.
- Classify each material fact as introduced, changed, a pre-existing
  contradiction of a public claim, or unrelated. A pre-existing value may not
  be a regression, but it still requires a global claim such as “none” or
  “never” to be narrowed or proved.
- For a compatibility overload, fallback, optional field, best-effort write,
  or rolling deployment, enumerate the meaningful writer/reader orderings only
  when they apply: old/new, concurrent, and retry order. For each, state the
  durable winner, user-visible result, and recovery or convergence mechanism.
  Mark unsupported cells unproven rather than assuming overwrite or retry
  behavior.
- Match evidence to the retention or compatibility claim. A schema, artifact,
  or focused test does not establish user-visible convergence or safe deletion
  unless it reaches that boundary.
