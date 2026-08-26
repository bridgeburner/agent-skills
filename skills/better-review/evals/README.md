# Evaluation intent

`evals.json` contains qualitative review prompts, not a published benchmark.
Cases 1-3 cover the skill's general four-lane and synthesis behavior. Case 4 is
a targeted positive regression guard for a scoped feature whose implementation
mutates a process singleton; case 5 is the genuinely request-local negative
control.

Do not claim that case 4 discriminates the hardened skill from the prior skill
without repeated matched runs. During the August 2026 hardening pass, one
matched prior/current probe found that both versions detected the fixture's
ambient visibility, foreign-consumer, teardown-order, and contract-narrowing
risks. The hardened version added stronger final-boundary proof, but that single
probe is not benchmark evidence for the central regression.

Retain case 4 as a durable coverage prompt: future runs should fail it if a
review omits any of the listed ambient-effect expectations. Treat it as a
discriminating benchmark only after repeated matched runs show that the prior
configuration misses at least one core ambient expectation while the hardened
configuration consistently finds it. Report variance and keep case 5 as the
specificity control.
