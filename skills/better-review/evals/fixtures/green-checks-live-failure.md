# Green checks, failed live path

Unit, integration, CI, ephemeral-VM, schema, artifact, and deployment checks
pass. The required local product run starts at the real entry point but fails
before the terminal result, so it produces no positive assertion and no
drop/omission/quarantine/wrong-attribution assertion.

A required security review also exits with infrastructure failure and writes an
empty report. The author treats both results as no findings and marks the PR
ready. The user has not changed the live-local acceptance bar.
