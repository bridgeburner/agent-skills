# Request instrumentation review fixture

The worker exposes a supported `executeRequest()` API. A shared operations
module also exists because plugins and diagnostics use the same runtime:

```text
sharedOperations = { execute: platformExecute }

function executeRequest(input):
    return sharedOperations.execute(input)

function enableMetrics(metrics):
    previous = sharedOperations.execute
    sharedOperations.execute = measured(previous, metrics)

function disableMetrics():
    sharedOperations.execute = previous
```

Worker startup calls `enableMetrics`; shutdown calls `disableMetrics`. Tests
start one worker, call `executeRequest`, stop the worker, and assert that
`sharedOperations.execute` equals `platformExecute` afterward.

Two existing consumers do not call `executeRequest`:

```text
plugin.run(input) = sharedOperations.execute(input)
diagnostics.isNative() = (sharedOperations.execute == platformExecute)
```

The review description says plugins that import the operations module directly
are outside the supported request-executor contract. Multiple workers can share
one runtime and can stop in a different order from the order they started.
