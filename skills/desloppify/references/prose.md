# Prose rules

## 1. Cadence

Uniform rhythm is the tell that survives longest, and the hardest to fake your
way out of. Models produce sentences of similar length and similar shape because
the average of the training distribution is a medium-length declarative.

The fix is not "write short sentences". It is to vary deliberately. A long
sentence that carries a chain of reasoning, followed by a short one that lands
it. Then a medium one. Then a fragment, if the fragment earns it.

Diagnostic: read three consecutive sentences aloud. If they share a shape,
rewrite one.

The same applies at paragraph level. Do not give every section three paragraphs
of four sentences. Some ideas need one line. Some need a table.

## 2. Tricolons and counting cadence

The strongest recognisable pattern in LLM prose is the three-part list used as a
rhetorical structure rather than as data.

Slop:
- "Four slivers, four switches, nothing deleted that still carries traffic"
- "Two PRs, a fixed commit stack, four switches"
- "Three things keep the large PR reviewable: a fixed commit stack, no
  deletions, and a single switch per component"
- "Simple, fast, and reliable"

Fixed:
- Delete the line if the section already says it.
- Or state the count plainly and put the items in a list, where the reader can
  actually use them.
- Or pick the one that matters and say only that.

The tell is not the number three. It is using enumeration as a rhythm. A real
list of three items in a bulleted list is fine and always was.

Counting cadence is the same failure in another dress: "One column, one
discovery query, one defer transition, one CLI command, one route." Say "the new
code is a column, a query, a transition, a CLI command and a route" once, or
list them.

## 3. Slogans and headings

A heading is an address label. Its job is to let a reader find the section
again and to tell them what is inside.

| Slop | Fixed |
| --- | --- |
| UI done right | UI release lane |
| Four Planes, One Tick | Scheduler target topology |
| Work is written down once and pulled | Producers insert rows; workers read them |
| The tracer bullet | S0: Scheduler Operations without a queue |
| What could bite | Risks and unverified provider facts |
| Built to last | Retention and upgrade path |

Test: could this heading appear on a conference slide with a stock photo behind
it? If yes, rewrite.

## 4. Heading plus deck

Giving every section a title *and* a subtitle that restates the title is
magazine chrome. It reads as filler, and doing it uniformly across every section
is a structural tell as strong as any phrase.

A deck earns its place only when it carries a fact the heading does not:

- Heading: `3. Today and target`
- Bad deck: "A look at where we are and where we are going"
- Good deck: "Six services, three runtime Jobs, five queues and Redis become
  three services, one Job and no queues."

If you cannot write a deck that adds a fact, do not write one.

## 5. Banned constructions

Remove on sight:

- "It's not X, it's Y." / "not merely" / "more than just" / "isn't about X, it's
  about Y"
- "In today's fast-paced / ever-evolving landscape"
- "Let that sink in." / "Here's the thing." / "But here's the kicker."
- Self-answered rhetorical questions ("So what does this mean? It means…")
- "Delve", "leverage" as a verb, "robust", "seamless", "unlock", "elevate",
  "supercharge", "game-changing", "best-in-class", "at the end of the day"
- "It's worth noting that", "It's important to understand that" — throat
  clearing; delete the clause and keep the sentence
- Closing paragraphs that summarise what the reader just read, unless the
  document is long enough that a summary is genuinely useful
- Bold-lead-in-then-colon on every bullet in a list, mechanically

Adverbs of emphasis ("significantly", "dramatically", "incredibly") almost
always replace a number. Use the number.

## 6. Punctuation

| Mark | Budget | Notes |
| --- | --- | --- |
| Em dash `—` | ≤ 1 per 500 words | Usually a period or a comma. Sometimes parens. |
| Arrow `→` | Diagrams and notation only | In prose, write "becomes" or "then". |
| Middot `·` | Metadata rows only | Never as a sentence connector. |
| Semicolon | Fine | Genuinely useful; under-used, not over-used. |
| Exclamation | 0 | In technical writing. |

The em dash rule is not because em dashes are bad. It is because a document with
one every third sentence has a rhythm problem the dash is hiding.

## 7. Anthropomorphism and abstraction drift

Systems do not want, own, ask, decide, or care.

| Slop | Fixed |
| --- | --- |
| Postgres owns the run | The run row holds all delivery state |
| A clock asks for capacity | Cloud Scheduler calls the tick every minute |
| The service is responsible for | The service does |
| This unlocks the ability to | This lets you |
| We surface visibility into | The page shows |

Related: prefer the concrete noun to the abstraction. "Copied wiring that
drifted" is worse than "five producers each carrying their own copy of the
worker URL, and two copies were wrong".

## 8. Voice and specificity

- Active voice with a real subject. "The tick counts due rows", not "due rows
  are counted".
- Replace every vague claim with a checkable fact. "Significantly reduces
  complexity" is nothing; "six services become three" is something.
- Name things the way the reader names them, not the way the system is built.
- State uncertainty at its real boundary. "Not observed in dev" is not "never
  happens". "Documented" is not "verified".

## 9. Structure

- Numbered sections only when order matters or when people will cite them.
  ("See §6" is a real use.)
- No emoji as section markers.
- No decorative eyebrows or kickers above every heading.
- Front-load. The first screen states what this is, who it is for, and what
  decision it supports.
- One idea per paragraph. If a paragraph has two, it is two paragraphs.
- Tables for anything with more than two parallel dimensions. Prose that
  enumerates parallel facts is nearly always a table trying to escape.

## 10. Rewriting versus writing

When de-slopping existing material, the failure mode is losing content while
improving tone. Guard against it:

1. Extract every fact from the original first (a list, a scratch file, whatever).
2. Rewrite.
3. Diff the fact list against the rewrite before shipping.

Presentation is the thing being changed. Substance is not.
