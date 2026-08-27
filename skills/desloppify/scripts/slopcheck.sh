#!/usr/bin/env bash
# slopcheck — mechanical slop signals for a prose or HTML deliverable.
# Usage: slopcheck.sh <file> [file...]
# Exit 1 if any hard budget is exceeded. Signals are advisory, not verdicts.

set -uo pipefail

if [ $# -eq 0 ]; then
  echo "usage: slopcheck.sh <file> [file...]" >&2
  exit 2
fi

status=0

for f in "$@"; do
  if [ ! -r "$f" ]; then
    echo "slopcheck: cannot read $f" >&2
    status=1
    continue
  fi
  python3 - "$f" <<'PY' || status=1
import html
import re
import sys

path = sys.argv[1]
raw = open(path, encoding="utf-8", errors="replace").read()
is_html = path.lower().endswith((".html", ".htm")) or "<html" in raw[:2000].lower()

# --- extract body text and, for HTML, keep the markup around for structure checks
markup = raw
if is_html:
    body = re.sub(r"(?is)<script.*?</script>", " ", raw)
    body = re.sub(r"(?is)<style.*?</style>", " ", body)
    body = re.sub(r"(?is)<svg.*?</svg>", " ", body)
    body = re.sub(r"(?s)<[^>]+>", " ", body)
    text = html.unescape(body)
else:
    text = re.sub(r"(?s)```.*?```", " ", raw)          # fenced code
    text = re.sub(r"`[^`]*`", " ", text)                # inline code
    text = re.sub(r"^\s*\|.*$", " ", text, flags=re.M)  # tables

text = re.sub(r"[ \t]+", " ", text)
words = len(text.split())

# Punctuation is measured on running prose only. Headings and leading bold labels
# use dashes as structural separators, which says nothing about sentence rhythm.
if is_html:
    prose = re.sub(r"(?is)<h[1-6][^>]*>.*?</h[1-6]>", " ", raw)
    prose = re.sub(r"(?is)<script.*?</script>", " ", prose)
    prose = re.sub(r"(?is)<style.*?</style>", " ", prose)
    prose = re.sub(r"(?is)<svg.*?</svg>", " ", prose)
    prose = html.unescape(re.sub(r"(?s)<[^>]+>", " ", prose))
else:
    # running prose = lines that are not headings, table rows, quotes, or list
    # items. Those forms use a dash as a label separator, not as sentence rhythm.
    prose = "\n".join(
        ln for ln in text.splitlines()
        if not re.match(r"\s*(#{1,6}\s|\||>|[-*+]\s|\d+\.\s)", ln)
    )
per1k = (lambda n: (n * 1000.0 / words) if words else 0.0)

print(f"\n\033[1m{path}\033[0m  ({words} words{', html' if is_html else ''})")

fails = []
warns = []

def check(label, value, budget, unit="", hard=True):
    ok = value <= budget
    mark = "ok  " if ok else ("FAIL" if hard else "warn")
    colour = "\033[32m" if ok else ("\033[31m" if hard else "\033[33m")
    print(f"  {colour}{mark}\033[0m  {label:<34} {value:>7.1f}{unit}  (budget {budget}{unit})")
    if not ok:
        (fails if hard else warns).append(label)

# ---------- punctuation ----------
em = prose.count("—")
arrows = text.count("→")
middots = text.count("·")
check("em dashes per 1k words", per1k(em), 2.0)
check("arrows in prose", arrows, 0, hard=False)
check("middots in prose", middots, 0, hard=False)
if middots:
    print("        note: middots inside metadata rows and table cells are exempt; check placement")

# ---------- banned constructions ----------
banned = [
    (r"\bit'?s not (just |merely |only )?\w+[,.]? it'?s\b", "it's not X it's Y"),
    (r"\bnot (just|merely|simply) (a|an|about)\b", "not merely X"),
    (r"\bever[- ]evolving\b|\bfast[- ]paced\b|\blandscape of\b", "landscape cliche"),
    (r"\blet that sink in\b|\bhere'?s the (thing|kicker)\b", "TED filler"),
    (r"\bdelve\b|\bseamless(ly)?\b|\brobust\b|\bgame[- ]chang", "buzzword"),
    (r"\bleverag(e|es|ing)\b", "leverage as verb"),
    (r"\bunlock(s|ing)? the\b|\bsupercharg|\belevat(e|es|ing) your\b", "marketing verb"),
    (r"\bit'?s (worth noting|important to (note|understand)) that\b", "throat clearing"),
    (r"\bbest[- ]in[- ]class\b|\bat the end of the day\b", "filler phrase"),
    (r"\b(significantly|dramatically|incredibly|vastly) (better|faster|more|less|improv|reduc)", "adverb for a number"),
]
hits = []
for pat, name in banned:
    for m in re.finditer(pat, text, re.I):
        hits.append((name, m.group(0).strip()))
check("banned constructions", len(hits), 0)
for name, frag in hits[:12]:
    print(f"        \033[31m·\033[0m {name}: “{frag}”")
if len(hits) > 12:
    print(f"        … and {len(hits)-12} more")

# ---------- headings ----------
if is_html:
    heads = [re.sub(r"(?s)<[^>]+>", " ", h) for h in
             re.findall(r"(?is)<h[1-4][^>]*>(.*?)</h[1-4]>", markup)]
else:
    heads = [h.strip() for h in re.findall(r"(?m)^#{1,4}\s+(.+?)\s*$", raw)]
heads = [re.sub(r"\s+", " ", html.unescape(h)).strip() for h in heads]
# drop a leading section number ("3", "6.3", "12 ·") so it does not merge into the words
heads = [re.sub(r"^\d+(\.\d+)?\s*[.\u00b7:\u2014-]?\s*", "", h).strip() for h in heads]
heads = [h for h in heads if h]

# tricolon / counting cadence in headings
NUM = r"one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|fourteen"
def _tricolon(h):
    tail = h.split(":", 1)[-1]                      # text before a colon is a label
    if re.search(r"^[^,]{3,45},[^,]{3,45},[^,]{3,70}$", tail.strip()):
        return True
    found = {m.lower() for m in re.findall(rf"\b({NUM})\b", h, re.I)}
    return len(found) >= 2                          # two DIFFERENT count words = cadence
tri = [h for h in heads if _tricolon(h)]
check("tricolon/counting headings", len(tri), 2, hard=False)
for h in tri[:8]:
    print(f"        \033[31m·\033[0m {h[:90]}")

# slogan smell: heading with no concrete noun, or verb-y marketing shape
slogan = [h for h in heads if re.search(
    r"\b(done right|built to|made simple|reimagined|rethought|the future of|why it matters|what could bite|at a glance)\b", h, re.I)]
check("slogan headings", len(slogan), 0, hard=False)
for h in slogan[:8]:
    print(f"        \033[33m·\033[0m {h[:90]}")

print(f"  info  headings: {len(heads)}")

# ---------- html-only: decoration + colour ----------
if is_html:
    css = "\n".join(re.findall(r"(?s)<style>(.*?)</style>", raw))
    selectors = set(re.findall(r"(?m)^\s*([.#][\w][\w.\-]*)\s*(?:,|\{)", css))
    check("distinct CSS selectors", len(selectors), 60)

    nocss = re.sub(r"(?s)<style>.*?</style>", "", raw)
    nocss = re.sub(r"(?is)<script.*?</script>", "", nocss)
    # table cells/rows and svg internals carry structural classes, not decoration
    nocss = re.sub(r"(?is)<svg.*?</svg>", "", nocss)
    nocss = re.sub(r"(?i)<(td|th|tr)\b[^>]*>", r"<\1>", nocss)
    classed = re.findall(r'class="([^"]+)"', nocss)
    check("decorated elements per 1k words", per1k(len(classed)), 40.0)

    hexes = set(h.lower() for h in re.findall(r"#[0-9A-Fa-f]{6}\b", css))
    print(f"  info  distinct hex colours in CSS: {len(hexes)}")

    # literal colours inside SVG (theme bug)
    svg = "\n".join(re.findall(r"(?is)<svg.*?</svg>", raw))
    svg_hex = re.findall(r'(?:fill|stroke)="#[0-9A-Fa-f]{3,6}"', svg)
    check("literal hex inside <svg>", len(svg_hex), 0)
    if svg_hex:
        print("        \033[31m·\033[0m use currentColor or token-bound classes; literal hex breaks one theme")

    # colours defined only inside a media / [data-theme] block
    guarded = "\n".join(re.findall(r"(?s)@media[^{]*\{(.*?)\n\s*\}\s*\n", css)) + \
              "\n".join(re.findall(r"(?s)\[data-theme[^{]*\{(.*?)\}", css))
    base = re.sub(r"(?s)@media.*?\{.*?\n\s*\}\s*\n", "", css)
    gvars = set(re.findall(r"(--[\w-]+)\s*:", guarded))
    bvars = set(re.findall(r"(--[\w-]+)\s*:", base))
    orphan = sorted(gvars - bvars)
    check("tokens defined only in dark blocks", len(orphan), 0)
    for v in orphan[:8]:
        print(f"        \033[31m·\033[0m {v}")

    if not re.search(r"body\s*\{[^}]*background", css):
        print("  \033[33mwarn\033[0m  body has no explicit background (borrows host ground)")

if fails:
    print(f"  \033[31m=> {len(fails)} hard budget(s) exceeded\033[0m")
    sys.exit(1)
if warns:
    print(f"  \033[33m=> {len(warns)} advisory signal(s)\033[0m")
sys.exit(0)
PY
done

exit $status
