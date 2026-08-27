# Reading the audit

```
scripts/slopcheck.sh <file.md|file.html> [more files...]
```

Exit 0 if every hard budget holds, 1 otherwise. Works on Markdown and HTML.
For Markdown it strips fenced code, inline code and tables before counting. For
HTML it strips `<script>`, `<style>` and `<svg>` for the prose counts but keeps
the markup for structure counts.

The script is a smoke detector. A clean report does not mean the writing is
good. A flagged line is sometimes correct. But an unexamined red report always
means something is wrong.

## Hard budgets

These fail the run. Fix them or state the exception out loud.

**em dashes per 1k words — budget 2.0**
Counted on running prose only. Headings, table rows, block quotes and list items
are excluded, because those forms use a dash as a label separator (`file.md — what
it is`) rather than as sentence rhythm, and counting them is a false positive.
Above this budget, the document has a rhythm problem that the dash is papering over.
The fix is usually not swapping dashes for commas; it is that the sentences
underneath are all the same shape. Go and vary them.

**banned constructions — budget 0**
Literal string matches for the phrases in `prose.md` §5. Every hit prints with
its surrounding fragment. These have no legitimate use in a technical
deliverable.

**distinct CSS selectors — budget 60**
Counts `.class` and `#id` selectors defined in `<style>`. Over 60 means most
ideas got their own bespoke component. The cure is deletion, not consolidation:
find the components that a paragraph, list or table would have carried and
remove them.

**decorated elements per 1k words — budget 40**
Counts elements carrying a `class` attribute, excluding table cells and rows and
excluding SVG internals, because those are structural rather than decorative.
Over 40 means emphasis has stopped being scarce, and the reader can no longer
tell what matters.

**literal hex inside `<svg>` — budget 0**
A `fill="#1F7A4D"` inside an inline SVG renders in exactly one theme and is
near-invisible in the other. Use `currentColor` for structure and CSS classes
bound to your tokens for the one or two meaning colours. This is the single most
common bug in hand-authored diagrams and it is invisible until someone with the
other theme opens the page.

**tokens defined only in dark blocks — budget 0**
A custom property whose only definition sits inside `@media (prefers-color-scheme: dark)`
or `[data-theme="dark"]` is undefined in the un-stamped default state, which is
what most viewers see. The page then renders one theme's text on the other
theme's ground. Every token must have a definition on bare `:root`.

## Advisory signals

These print but do not fail. They need judgement.

**arrows and middots in prose**
Legitimate inside diagrams, notation, metadata rows and table cells. The script
cannot tell where they sit, so it reports the raw count. Look at where they
actually are. A metadata line reading `scheduler 5b07216 · design rev D` is fine.
A sentence reading `count due rows → start the difference` is not.

**tricolon / counting headings — budget 2**
Flags headings that are comma-triples, or that carry two different count words.
This check has known false positives: "altius-scheduler PR, one PR of eight
commits" trips it without being cadence. Treat it as a prompt to read your
heading list end to end, which is the actual point. Reading all your headings in
sequence is the fastest way to spot the heading-plus-deck pattern too.

**slogan headings**
Literal matches for a small set of marketing shapes. It will not catch every
slogan. The human test in `prose.md` §3 still applies: could this heading sit on
a conference slide with a stock photo behind it?

**body has no explicit background**
HTML only. A transparent body borrows the host page's ground, so a light-designed
page renders on a dark ground. Set `background` on `body` from a token.

## Info lines

**headings: N** — sanity check against document length. Ninety-four headings in
a 5,700-word document means most sections have a title and a restated subtitle.

**distinct hex colours in CSS: N** — includes both theme palettes, so roughly
double your actual palette size. Around 26 is a three-colour plus neutrals
system. Around 48 is a seven-colour system, and that is a legend the reader has
to memorise.

## Calibration reference

Measured on one real before/after pair, two technical documents of about 6,000
words each:

| Signal | Before | After |
| --- | --- | --- |
| em dashes per 1k | 3.0 / 7.1 | 0.5 / 1.0 |
| tricolon headings | 6 / 4 | 0 / 5 |
| distinct CSS selectors | 76 / 45 | 15 / 13 |
| decorated per 1k words | 83 / 45 | 12.8 / 12.5 |
| distinct hex colours | 48 / 48 | 26 / 26 |
| headings | 94 / 59 | 28 / 51 |
| hard budgets exceeded | 3 / 2 | 0 / 0 |

The decoration ratio moved by roughly 6x and the selector count by 3–5x. Those
two are what the reader actually feels.
