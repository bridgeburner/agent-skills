# Request-local wrapper control fixture

Each request constructs and owns its operation table. The table is neither
exported nor stored outside the request context:

```text
function executeRequest(input, metrics):
    requestOperations = { execute: platformExecute }
    requestOperations.execute = measured(requestOperations.execute, metrics)
    return requestOperations.execute(input)
```

Concurrent requests receive different table objects. Plugins and diagnostics
use `platformExecute` directly; no shared registry, module singleton, process
hook, environment value, or host resource is changed.
