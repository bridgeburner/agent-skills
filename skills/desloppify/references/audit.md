# Reading the audit

Run the optional smoke check with one or more deliverables:

```bash
scripts/slopcheck.sh <file.md|file.html> [more files...]
```

The script strips code and structural markup before inspecting prose. For HTML
it also inspects CSS and SVG structure. It reports:

- punctuation and stock-phrase signals;
- heading patterns and slogan candidates;
- CSS selector and decorated-element density;
- color literals in SVG and theme tokens with no base definition; and
- an explicit background warning for HTML.

Some checks have built-in thresholds and can make the command exit non-zero.
Those thresholds are triage signals, not a style law or a completion gate.
Inspect the flagged source in context. Keep a correct choice when the document's
audience or subject warrants it, and fix the underlying clarity problem when a
flag points to one. Do not swap punctuation or delete content solely to make the
counter pass.

The report's heading count, color count, and advisory signals are useful for a
quick scan. A clean report does not establish that the writing is good, and a
flagged line does not establish that it is wrong. The reader's ability to find
the claim and act on it is the final check.

For a rewrite, compare the facts in the source with the revised file. The audit
checks presentation; it cannot tell you whether a fact, caveat, or requirement
was lost.
