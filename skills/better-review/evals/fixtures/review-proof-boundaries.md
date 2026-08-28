# Review proof-boundaries fixture

Use this fixture to check whether a review turns three common proof gaps into
mechanical review questions without assuming a particular provider or codebase.

## Proposed change

The parent change adds a scheduled machine caller for an internal route and
sets a worker-capacity configuration value to zero for the first activation.
The child change raises that value and switches the execution handoff.

The PR includes a contract script. The script checks that a capacity setting is
present in one configuration file, but the resource was moved to a sibling file.
The script is runnable by hand and is not invoked by the repository's required
CI check. The PR body says the exact value is enforced.

The machine caller is authorized at the service boundary. The application has
several routes, but there is no test showing that the machine principal is
allowed on its intended route and rejected on the adjacent human and operation
routes. An inventory comment still says the human identity is the only invoker.

The child PR is stacked on the parent. The handoff says to retarget the child to
the default branch after the parent is squash-merged. It does not require
rebuilding on the resulting parent, comparing patch identity, checking the
final file/resource scope, or rerunning CI and the infrastructure plan.

## Review request

Review the proposed change with better-review. Remain read-only. Decide whether
the PR is ready and state the smallest proof or refinement needed for each gap.
