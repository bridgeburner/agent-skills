# Building Principles — Supplementary

These principles are sound but niche. They live here to keep the main skill concise.

## Represent Knowledge in Data
Fold policy, configuration, and domain rules into data structures rather than control flow. The program becomes an interpreter of data rather than a hard-coded encoding of assumptions.

**Agent rule:** When you see a long if/elif chain encoding domain rules, ask: "Could this be a lookup table or data-driven dispatch?"
