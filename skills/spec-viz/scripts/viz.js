// spec-viz — runtime markdown renderer + annotation overlay
//
// Loads each .md referenced by a [data-component][data-source] placeholder,
// parses it once, then renders each placeholder using the named component.
// After rendering, attaches the annotation gutter, the side pane, theme/edit
// controls, the export modal, and diagram fullscreen.
//
// Storage shape:
//   localStorage[stateKey] = {
//     blocks: { [annoId]: { reactions: {like,dislike,question}, note, edits } },
//     theme: "dark" | "light",
//     editMode: bool
//   }
// stateKey defaults to "spec-viz:state"; override with <body data-viz-storage-key="...">.

// ============================================================
// Configuration helpers
// ============================================================

function stateKey() { return document.body.dataset.vizStorageKey || "spec-viz:state"; }
function pageSlug() { return document.body.dataset.vizPage || "page"; }
function pageOrder() {
  const v = document.body.dataset.vizPageOrder;
  return v ? v.split(",").map(s => s.trim()) : null;
}

// ============================================================
// State management
// ============================================================

function loadState() {
  try {
    const raw = localStorage.getItem(stateKey());
    if (!raw) return { blocks: {}, theme: "dark", editMode: false };
    const s = JSON.parse(raw);
    if (!s.blocks) s.blocks = {};
    return s;
  } catch (e) {
    return { blocks: {}, theme: "dark", editMode: false };
  }
}

function saveState() { localStorage.setItem(stateKey(), JSON.stringify(state)); }

const state = (() => {
  // Load lazily but synchronously at first use. We need document.body to exist
  // to read stateKey() from data attributes. If this script is loaded with
  // defer or at the end of body, that's already the case.
  return null;
})();

let _state = null;
function getState() {
  if (_state === null) _state = loadState();
  return _state;
}

function getBlockState(id) {
  const s = getState();
  if (!s.blocks[id]) s.blocks[id] = { reactions: {}, note: "", edits: {} };
  return s.blocks[id];
}

function commit() { saveState(); refreshStat(); refreshPane(); }
function saveState() { localStorage.setItem(stateKey(), JSON.stringify(getState())); }

// ============================================================
// Markdown parsing
// ============================================================

function slugify(s) {
  return String(s).toLowerCase().trim()
    .replace(/[^\w\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function escapeHtml(s) {
  return String(s == null ? "" : s).replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"})[c]);
}

function stripMarkdown(s) {
  return String(s == null ? "" : s)
    .replace(/`([^`]+)`/g, "$1")
    .replace(/\*\*([^*]+)\*\*/g, "$1")
    .replace(/\*([^*]+)\*/g, "$1")
    .replace(/_([^_]+)_/g, "$1")
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1");
}

function renderInline(text) {
  if (text == null) return "";
  let s = escapeHtml(text);
  // Code spans first — protect them from other markup
  const codes = [];
  s = s.replace(/`([^`]+)`/g, (_, c) => { codes.push(c); return ` CODE${codes.length - 1} `; });
  // Bold **text**
  s = s.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
  // Italic *text* (no leading asterisk, non-greedy)
  s = s.replace(/(^|[^*])\*([^*\s][^*]*?)\*(?!\*)/g, "$1<em>$2</em>");
  // Italic _text_
  s = s.replace(/(^|[^_])_([^_\s][^_]*?)_(?!_)/g, "$1<em>$2</em>");
  // Links [text](url). Rewrite sibling .md links to .html so cross-doc references
  // inside the viz navigate to the rendered page instead of the raw markdown.
  s = s.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_, label, href) => {
    const rewritten = href.replace(/^([^?#]*?)\.md(?=$|[?#])/, "$1.html");
    return `<a href="${rewritten}">${label}</a>`;
  });
  // Restore code spans
  s = s.replace(/ CODE(\d+) /g, (_, i) => `<code>${codes[i]}</code>`);
  return s;
}

function splitRow(line) {
  let t = line.trim();
  if (t.startsWith("|")) t = t.slice(1);
  if (t.endsWith("|")) t = t.slice(0, -1);
  return t.split("|").map(c => c.trim());
}

function parseTable(lines, start) {
  const headers = splitRow(lines[start]);
  const rows = [];
  let i = start + 2; // skip the separator row
  while (i < lines.length && lines[i].trim().startsWith("|")) {
    rows.push(splitRow(lines[i]));
    i++;
  }
  return { headers, rows, endLine: i };
}

function parseMarkdown(text) {
  const lines = text.split(/\r?\n/);
  const sections = [];
  const sectionsBySlug = {};
  let current = null;
  let pageTitle = null;
  const pageLede = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];

    const h1 = line.match(/^#\s+(.+)$/);
    if (h1 && pageTitle === null) { pageTitle = h1[1].trim(); i++; continue; }

    const hN = line.match(/^(#{2,4})\s+(.+)$/);
    if (hN) {
      current = {
        level: hN[1].length,
        title: hN[2].trim(),
        slug: slugify(hN[2].trim()),
        paragraphs: [],
        tables: [],
        codeBlocks: [],
      };
      sections.push(current);
      sectionsBySlug[current.slug] = current;
      i++;
      continue;
    }

    if (line.trim().startsWith("|") && i + 1 < lines.length && /^\s*\|[\s\-:|]+\|\s*$/.test(lines[i+1])) {
      const t = parseTable(lines, i);
      if (current) current.tables.push(t);
      i = t.endLine;
      continue;
    }

    if (/^```/.test(line)) {
      const lang = line.replace(/^```/, "").trim();
      const start = i + 1;
      let end = start;
      while (end < lines.length && !/^```\s*$/.test(lines[end])) end++;
      const block = { lang, content: lines.slice(start, end).join("\n") };
      if (current) current.codeBlocks.push(block);
      i = end + 1;
      continue;
    }

    if (line.trim()) {
      if (current) current.paragraphs.push(line.trim());
      else pageLede.push(line.trim());
    }
    i++;
  }
  return { sections, sectionsBySlug, pageTitle, pageLede: pageLede.join(" ") };
}

// ============================================================
// Component renderers
//   signature: render(el, md, anchor, pageSlug) -> void (writes to el.innerHTML)
// ============================================================

function renderEmpty(el, msg) {
  el.innerHTML = `<div class="ann-empty">${escapeHtml(msg)}</div>`;
}

function firstTable(md, anchor) {
  const section = md && md.sectionsBySlug[anchor];
  return section && section.tables[0] ? { section, table: section.tables[0] } : null;
}

function renderGlossaryTable(el, md, anchor, pSlug) {
  const t = firstTable(md, anchor);
  if (!t) return renderEmpty(el, `No table at #${anchor}`);
  const { table } = t;
  let html = `<table><thead><tr>`;
  for (const h of table.headers) html += `<th>${escapeHtml(h)}</th>`;
  html += `</tr></thead><tbody>`;
  for (const row of table.rows) {
    const term = stripMarkdown(row[0]);
    const annoId = `${pSlug}:gloss-${slugify(term)}`;
    const annoLabel = `glossary · ${term}`;
    html += `<tr class="block" data-anno-id="${escapeHtml(annoId)}" data-anno-label="${escapeHtml(annoLabel)}">`;
    html += `<td><strong>${renderInline(row[0].replace(/^\*\*([^*]+)\*\*$/, "$1"))}</strong></td>`;
    for (let i = 1; i < row.length; i++) html += `<td>${renderInline(row[i])}</td>`;
    html += `</tr>`;
  }
  html += `</tbody></table>`;
  el.innerHTML = html;
}

function renderCardGrid(el, md, anchor, pSlug) {
  const t = firstTable(md, anchor);
  if (!t) return renderEmpty(el, `No table at #${anchor}`);
  const { table } = t;
  const cardType = el.dataset.cardType || "";
  const cols = el.dataset.cols || "2";
  // body-col: column index that becomes card-body (default 2). "none" skips body
  // entirely — col 2+ becomes meta. Useful when the source has only ID+Title+Meta
  // (e.g. Goals: ID | Goal | Verification).
  const bodyColRaw = el.dataset.bodyCol || "2";
  const bodyCol = bodyColRaw === "none" ? -1 : parseInt(bodyColRaw, 10);
  const metaStart = bodyCol < 0 ? 2 : bodyCol + 1;

  let html = `<div class="card-grid cols-${escapeHtml(cols)}">`;
  for (const row of table.rows) {
    const rawId = row[0] || "";
    const id = stripMarkdown(rawId).replace(/\s+/g, "");
    const title = row[1] || "";
    const annoId = `${pSlug}:${id || slugify(stripMarkdown(title))}`;
    const annoLabel = `${id} · ${stripMarkdown(title)}`;
    const cardElId = id ? ` id="${escapeHtml(id)}"` : "";
    html += `<div class="card ${escapeHtml(cardType)} block"${cardElId} data-anno-id="${escapeHtml(annoId)}" data-anno-label="${escapeHtml(annoLabel)}">`;
    html += `<div class="card-header"><span class="card-id">${renderInline(rawId)}</span><span class="card-title">${renderInline(title)}</span></div>`;
    if (bodyCol >= 0 && row[bodyCol] !== undefined) {
      html += `<div class="card-body">${renderInline(row[bodyCol])}</div>`;
    }
    if (row.length > metaStart) {
      const metaParts = [];
      for (let i = metaStart; i < row.length; i++) {
        if (row[i]) {
          metaParts.push(`<div class="kv"><span class="k">${escapeHtml(table.headers[i] || "")}</span><span class="v">${renderInline(row[i])}</span></div>`);
        }
      }
      if (metaParts.length) html += `<div class="card-meta">${metaParts.join("")}</div>`;
    }
    html += `</div>`;
  }
  html += `</div>`;
  el.innerHTML = html;
}

function renderReqGrid(el, md, anchor, pSlug) {
  const t = firstTable(md, anchor);
  if (!t) return renderEmpty(el, `No table at #${anchor}`);
  const { table } = t;
  const cols = el.dataset.cols || "2";
  // Auto-detect columns: ID, Title, Given, When, Then, [Verification]
  // or:                  ID, Title, Body (legacy 3-col fallback to card-grid behavior)
  const hasGWT = table.headers.length >= 5;
  if (!hasGWT) return renderCardGrid(el, md, anchor, pSlug);

  let html = `<div class="card-grid cols-${escapeHtml(cols)}">`;
  for (const row of table.rows) {
    const [id, title, given, when, then, verification] = row;
    const cleanId = stripMarkdown(id || "").replace(/\s+/g, "");
    const annoId = `${pSlug}:${cleanId}`;
    const annoLabel = `${stripMarkdown(id)} · ${stripMarkdown(title)}`;
    const cardElId = cleanId ? ` id="${escapeHtml(cleanId)}"` : "";
    html += `<div class="card req block"${cardElId} data-anno-id="${escapeHtml(annoId)}" data-anno-label="${escapeHtml(annoLabel)}">`;
    html += `<div class="card-header"><span class="card-id">${renderInline(id || "")}</span><span class="card-title">${renderInline(title || "")}</span></div>`;
    html += `<div class="card-body"><div class="gwt">`;
    html += `<span class="label">Given</span><span>${renderInline(given || "")}</span>`;
    html += `<span class="label">When</span><span>${renderInline(when || "")}</span>`;
    html += `<span class="label">Then</span><span>${renderInline(then || "")}</span>`;
    html += `</div></div>`;
    if (verification) {
      html += `<div class="card-meta"><div class="kv"><span class="k">Verify</span><span class="v">${renderInline(verification)}</span></div></div>`;
    }
    html += `</div>`;
  }
  html += `</div>`;
  el.innerHTML = html;
}

function renderShapeTable(el, md, anchor, pSlug) {
  const t = firstTable(md, anchor);
  if (!t) return renderEmpty(el, `No table at #${anchor}`);
  const { table } = t;
  const prefix = el.dataset.idPrefix || anchor || "row";
  let html = `<table><thead><tr>`;
  for (const h of table.headers) html += `<th>${escapeHtml(h)}</th>`;
  html += `</tr></thead><tbody>`;
  for (const row of table.rows) {
    const idText = stripMarkdown(row[0] || "");
    const annoId = `${pSlug}:${slugify(prefix)}-${slugify(idText)}`;
    const annoLabel = `${anchor} · ${idText}`;
    html += `<tr class="block" data-anno-id="${escapeHtml(annoId)}" data-anno-label="${escapeHtml(annoLabel)}">`;
    for (const cell of row) html += `<td>${renderInline(cell)}</td>`;
    html += `</tr>`;
  }
  html += `</tbody></table>`;
  el.innerHTML = html;
}

function renderTierStack(el, md, anchor, pSlug) {
  const t = firstTable(md, anchor);
  if (!t) return renderEmpty(el, `No table at #${anchor}`);
  const { table } = t;
  let tier = 1;
  let html = `<div class="tier-stack">`;
  for (const row of table.rows) {
    const [name, fields, behavior] = row;
    const slug = slugify(stripMarkdown(name || ""));
    const annoId = `${pSlug}:tier-${slug}`;
    const annoLabel = `tier · ${stripMarkdown(name)}`;
    html += `<div class="tier-row t-${tier} block" data-anno-id="${escapeHtml(annoId)}" data-anno-label="${escapeHtml(annoLabel)}">`;
    html += `<div class="tier-name">${renderInline(name || "")}</div>`;
    html += `<div class="tier-fields">${renderInline(fields || "")}</div>`;
    html += `<div class="tier-behavior">${renderInline(behavior || "")}</div>`;
    html += `</div>`;
    tier++;
  }
  html += `</div>`;
  el.innerHTML = html;
}

function renderStateList(el, md, anchor, pSlug) {
  const t = firstTable(md, anchor);
  if (!t) return renderEmpty(el, `No table at #${anchor}`);
  const { table } = t;
  let html = `<div class="state-list">`;
  for (const row of table.rows) {
    const [name, meaning, next] = row;
    const slug = slugify(stripMarkdown(name || ""));
    const annoId = `${pSlug}:state-${slug}`;
    const annoLabel = `state · ${stripMarkdown(name)}`;
    html += `<div class="state block" data-anno-id="${escapeHtml(annoId)}" data-anno-label="${escapeHtml(annoLabel)}">`;
    html += `<div class="name">${renderInline(name || "")}</div>`;
    html += `<div class="desc">${renderInline(meaning || "")}</div>`;
    if (next) html += `<div class="next">→ ${renderInline(next)}</div>`;
    html += `</div>`;
  }
  html += `</div>`;
  el.innerHTML = html;
}

function matrixCellClass(v) {
  const t = String(v || "").toLowerCase().trim();
  if (["✓","yes","y","allowed","ok","✅","true"].includes(t)) return "cell-allowed";
  if (["✗","no","n","rejected","❌","false"].includes(t)) return "cell-rejected";
  if (["?","maybe","conditional","partial","later","future"].includes(t)) return "cell-conditional";
  if (!t || t === "-" || t === "—" || t === "n/a") return "cell-na";
  return "";
}

function renderMatrix(el, md, anchor, pSlug) {
  const t = firstTable(md, anchor);
  if (!t) return renderEmpty(el, `No table at #${anchor}`);
  const { table } = t;
  let html = `<div class="matrix-wrap"><table class="matrix"><thead><tr>`;
  for (let i = 0; i < table.headers.length; i++) {
    const cls = i === 0 ? "row-header" : "";
    html += `<th class="${cls}">${escapeHtml(table.headers[i])}</th>`;
  }
  html += `</tr></thead><tbody>`;
  for (const row of table.rows) {
    const rowHeader = stripMarkdown(row[0] || "");
    const annoId = `${pSlug}:matrix-${slugify(rowHeader)}`;
    const annoLabel = `matrix · ${rowHeader}`;
    html += `<tr class="block" data-anno-id="${escapeHtml(annoId)}" data-anno-label="${escapeHtml(annoLabel)}">`;
    for (let i = 0; i < row.length; i++) {
      const cls = i === 0 ? "row-header" : matrixCellClass(row[i]);
      html += `<td class="${cls}">${renderInline(row[i] || "")}</td>`;
    }
    html += `</tr>`;
  }
  html += `</tbody></table></div>`;
  el.innerHTML = html;
}

function renderDetailsBlock(el, md, anchor, pSlug) {
  const section = md && md.sectionsBySlug[anchor];
  if (!section) return renderEmpty(el, `No section at #${anchor}`);
  const annoId = `${pSlug}:details-${anchor}`;
  const annoLabel = `${section.title} (future/deferred)`;
  const label = el.dataset.label || "Future";
  let html = `<div class="card deferred block" data-anno-id="${escapeHtml(annoId)}" data-anno-label="${escapeHtml(annoLabel)}">`;
  html += `<div class="card-header"><span class="card-id">${escapeHtml(label)}</span><span class="card-title">${escapeHtml(section.title)}</span></div>`;
  if (section.paragraphs.length) {
    html += `<div class="card-body">${renderInline(section.paragraphs[0])}</div>`;
  }
  html += `</div>`;
  const hasMore = section.paragraphs.length > 1 || section.tables.length > 0 || section.codeBlocks.length > 0;
  if (hasMore) {
    html += `<details><summary>Show details</summary>`;
    for (let i = 1; i < section.paragraphs.length; i++) html += `<p>${renderInline(section.paragraphs[i])}</p>`;
    for (const table of section.tables) {
      html += `<table><thead><tr>`;
      for (const h of table.headers) html += `<th>${escapeHtml(h)}</th>`;
      html += `</tr></thead><tbody>`;
      for (const row of table.rows) {
        html += `<tr>`;
        for (const cell of row) html += `<td>${renderInline(cell)}</td>`;
        html += `</tr>`;
      }
      html += `</tbody></table>`;
    }
    for (const cb of section.codeBlocks) {
      html += `<pre><code>${escapeHtml(cb.content)}</code></pre>`;
    }
    html += `</details>`;
  }
  el.innerHTML = html;
}

function renderKeyValueCard(el, md, anchor, pSlug) {
  // Render a section that has a 2-col Field/Value table as a single card with the
  // section title as card-title and table rows as labeled kv pairs in card-body.
  // Useful for sections like "## S1. ONets Model Metadata Extraction" whose body
  // is a Goal/Inputs/Procedure/Acceptance/Blocks shape.
  const section = md && md.sectionsBySlug[anchor];
  if (!section) return renderEmpty(el, `No section at #${anchor}`);
  const cardType = el.dataset.cardType || "spike";
  const explicitId = el.dataset.id || "";
  const titleText = section.title;
  const annoId = `${pSlug}:${explicitId || anchor}`;
  const annoLabel = `${explicitId || anchor} · ${titleText}`;
  const cardElId = explicitId ? ` id="${escapeHtml(explicitId)}"` : "";
  let html = `<div class="card ${escapeHtml(cardType)} block"${cardElId} data-anno-id="${escapeHtml(annoId)}" data-anno-label="${escapeHtml(annoLabel)}">`;
  html += `<div class="card-header">`;
  if (explicitId) html += `<span class="card-id">${escapeHtml(explicitId)}</span>`;
  html += `<span class="card-title">${renderInline(titleText)}</span></div>`;
  if (section.tables[0]) {
    const table = section.tables[0];
    // If the table has 2 cols (Field/Value), render as kv block in body
    if (table.headers.length === 2) {
      html += `<div class="card-body">`;
      // Optional: pull out the last row as card-meta if it looks like a "Blocks" or "Verify" row
      const rows = table.rows.slice();
      const lastRow = rows[rows.length - 1];
      const lastKey = lastRow ? stripMarkdown(lastRow[0]).toLowerCase() : "";
      const moveToMeta = lastRow && /^(blocks?|verify|verification|next)$/.test(lastKey);
      const bodyRows = moveToMeta ? rows.slice(0, -1) : rows;
      for (const row of bodyRows) {
        const [k, v] = row;
        html += `<p><strong>${renderInline(k)}.</strong> ${renderInline(v)}</p>`;
      }
      html += `</div>`;
      if (moveToMeta) {
        html += `<div class="card-meta"><div class="kv"><span class="k">${renderInline(lastRow[0])}</span><span class="v">${renderInline(lastRow[1])}</span></div></div>`;
      }
    } else {
      // Fallback for non-2-col tables: just dump the table inside the card body
      html += `<div class="card-body">`;
      html += `<table><thead><tr>`;
      for (const h of table.headers) html += `<th>${escapeHtml(h)}</th>`;
      html += `</tr></thead><tbody>`;
      for (const row of table.rows) {
        html += `<tr>`;
        for (const cell of row) html += `<td>${renderInline(cell)}</td>`;
        html += `</tr>`;
      }
      html += `</tbody></table></div>`;
    }
  } else if (section.paragraphs.length) {
    html += `<div class="card-body">`;
    for (const p of section.paragraphs) html += `<p>${renderInline(p)}</p>`;
    html += `</div>`;
  }
  html += `</div>`;
  el.innerHTML = html;
}

function renderDiagramInline(el) {
  // Hand-authored inline SVG. The shell author provides the <svg> directly inside
  // <div data-component="diagram-inline">. We add chrome and the fullscreen hook.
  if (!el.classList.contains("diagram-wrap") && !el.classList.contains("svg-stage")) {
    el.classList.add("diagram-wrap");
  }
}

const COMPONENT_REGISTRY = {
  "glossary-table": renderGlossaryTable,
  "card-grid":      renderCardGrid,
  "req-grid":       renderReqGrid,
  "shape-table":    renderShapeTable,
  "tier-stack":     renderTierStack,
  "state-list":     renderStateList,
  "policy-table":   renderShapeTable,   // alias
  "crosswalk":      renderShapeTable,   // alias
  "matrix":         renderMatrix,
  "details-block":  renderDetailsBlock,
  "keyvalue-card":  renderKeyValueCard,
  "diagram-inline": renderDiagramInline,
};

async function renderComponents() {
  const placeholders = Array.from(document.querySelectorAll("[data-component]"));
  if (!placeholders.length) return;

  const pSlug = pageSlug();
  const sources = new Map();
  for (const el of placeholders) {
    if (el.dataset.component === "diagram-inline") continue; // no source needed
    const src = (el.dataset.source || "").split("#")[0];
    if (src && !sources.has(src)) {
      sources.set(src, fetch(src)
        .then(r => { if (!r.ok) throw new Error(`Fetch ${src}: HTTP ${r.status}`); return r.text(); })
        .then(parseMarkdown)
        .catch(err => { console.error("[spec-viz]", err); return null; }));
    }
  }
  await Promise.all(sources.values());

  for (const el of placeholders) {
    const name = el.dataset.component;
    const fn = COMPONENT_REGISTRY[name];
    if (!fn) {
      console.warn(`[spec-viz] Unknown component: ${name}`);
      el.innerHTML = `<div class="ann-empty">Unknown component: ${escapeHtml(name)}</div>`;
      continue;
    }
    const [src, anchor] = (el.dataset.source || "").split("#");
    const md = src ? await sources.get(src) : null;
    try {
      fn(el, md, anchor, pSlug);
    } catch (err) {
      console.error(`[spec-viz] Render ${name} @ #${anchor}:`, err);
      el.innerHTML = `<div class="ann-empty">Render error: ${escapeHtml(err.message)}</div>`;
    }
  }
}

// ============================================================
// Stat (top bar count)
// ============================================================

function refreshStat() {
  const s = getState();
  let likes = 0, dislikes = 0, questions = 0, notes = 0, edits = 0;
  for (const id in s.blocks) {
    const b = s.blocks[id];
    if (b.reactions?.like) likes++;
    if (b.reactions?.dislike) dislikes++;
    if (b.reactions?.question) questions++;
    if (b.note && b.note.trim()) notes++;
    if (b.edits) edits += Object.keys(b.edits).length;
  }
  const stat = document.getElementById("ann-stat");
  if (stat) {
    stat.innerHTML = `<strong>${likes}</strong> 👍 · <strong>${dislikes}</strong> 👎 · <strong>${questions}</strong> ❓ · <strong>${notes}</strong> 💬 · <strong>${edits}</strong> ✎`;
  }
}

// ============================================================
// Block decoration (gutter, reactions, notes, editable cells)
// ============================================================

function setupBlocks() {
  document.querySelectorAll(".block").forEach(block => {
    const id = block.dataset.annoId;
    if (!id) return;

    const bs = getBlockState(id);
    if (bs.reactions?.like) block.classList.add("has-like");
    if (bs.reactions?.dislike) block.classList.add("has-dislike");
    if (bs.reactions?.question) block.classList.add("has-question");
    if (bs.edits && Object.keys(bs.edits).length) block.classList.add("has-edit");

    if (!block.querySelector(":scope > .block-gutter")) {
      const gutter = document.createElement("div");
      gutter.className = "block-gutter";
      gutter.innerHTML = `
        <button class="like" data-r="like" title="Like (👍)">👍</button>
        <button class="dislike" data-r="dislike" title="Dislike (👎)">👎</button>
        <button class="question" data-r="question" title="Question (❓)">❓</button>
        <button class="note" data-r="note" title="Add note (💬)">💬</button>
      `;
      if (block.tagName === "TR") {
        const lastCell = block.lastElementChild;
        if (lastCell) { lastCell.style.position = "relative"; lastCell.appendChild(gutter); }
      } else {
        block.appendChild(gutter);
      }
      if (block.tagName === "TR") {
        block.addEventListener("mouseenter", () => gutter.style.opacity = "1");
        block.addEventListener("mouseleave", () => gutter.style.opacity = "0");
      }
      gutter.querySelectorAll("button").forEach(btn => {
        const r = btn.dataset.r;
        if (r === "note") {
          if (bs.note && bs.note.trim()) btn.classList.add("active");
          btn.addEventListener("click", e => { e.stopPropagation(); toggleNote(block); });
        } else {
          if (bs.reactions?.[r]) btn.classList.add("active", r);
          btn.addEventListener("click", e => { e.stopPropagation(); toggleReaction(block, r); });
        }
      });
    }

    block.querySelectorAll(".editable").forEach(el => {
      const editId = el.dataset.editId;
      if (!editId) return;
      const stored = bs.edits?.[editId];
      if (stored && stored.current !== stored.original) {
        el.textContent = stored.current;
        el.classList.add("edited");
      } else if (!el.dataset.original) {
        el.dataset.original = el.textContent;
      }
      el.addEventListener("blur", () => {
        if (!document.body.classList.contains("edit-mode")) return;
        const current = el.textContent;
        const original = el.dataset.original || current;
        if (!bs.edits) bs.edits = {};
        if (current === original) {
          delete bs.edits[editId];
          el.classList.remove("edited");
        } else {
          bs.edits[editId] = { original, current };
          el.classList.add("edited");
        }
        if (bs.edits && Object.keys(bs.edits).length) block.classList.add("has-edit");
        else block.classList.remove("has-edit");
        commit();
      });
    });
  });
}

function toggleReaction(block, kind) {
  const id = block.dataset.annoId;
  const bs = getBlockState(id);
  if (!bs.reactions) bs.reactions = {};
  bs.reactions[kind] = !bs.reactions[kind];
  block.classList.toggle("has-" + kind, !!bs.reactions[kind]);
  const btn = block.querySelector(`.block-gutter button[data-r="${kind}"]`);
  if (btn) { btn.classList.toggle("active", !!bs.reactions[kind]); btn.classList.toggle(kind, !!bs.reactions[kind]); }
  commit();
}

function toggleNote(block) {
  const id = block.dataset.annoId;
  const bs = getBlockState(id);
  let panel = block.querySelector(":scope > .note-input");
  if (!panel) {
    panel = document.createElement("div");
    panel.className = "note-input";
    panel.innerHTML = `
      <textarea placeholder="Your note about this block…"></textarea>
      <div class="note-actions">
        <button class="btn" data-act="cancel">Cancel</button>
        <button class="btn primary" data-act="save">Save</button>
      </div>
    `;
    if (block.tagName === "TR") {
      const cols = block.children.length;
      const noteRow = document.createElement("tr");
      noteRow.className = "note-row";
      noteRow.dataset.parentId = id;
      const td = document.createElement("td");
      td.colSpan = cols; td.style.padding = "0";
      td.appendChild(panel);
      noteRow.appendChild(td);
      block.after(noteRow);
    } else {
      block.appendChild(panel);
    }
    const ta = panel.querySelector("textarea");
    ta.value = bs.note || "";
    panel.querySelector('[data-act="cancel"]').addEventListener("click", () => panel.classList.remove("open"));
    panel.querySelector('[data-act="save"]').addEventListener("click", () => {
      bs.note = ta.value.trim();
      const btn = block.querySelector('.block-gutter button[data-r="note"]');
      if (btn) btn.classList.toggle("active", !!bs.note);
      panel.classList.remove("open");
      commit();
    });
  }
  panel.classList.toggle("open");
  const ta = panel.querySelector("textarea");
  if (panel.classList.contains("open")) { ta.value = bs.note || ""; ta.focus(); }
}

// ============================================================
// Annotation side pane
// ============================================================

function refreshPane() {
  const pane = document.getElementById("ann-pane");
  if (!pane) return;
  const s = getState();
  const items = [];
  for (const id in s.blocks) {
    const b = s.blocks[id];
    const reacted = b.reactions?.like || b.reactions?.dislike || b.reactions?.question;
    const noted = b.note && b.note.trim();
    const edited = b.edits && Object.keys(b.edits).length;
    if (!reacted && !noted && !edited) continue;
    const el = document.querySelector(`[data-anno-id="${CSS.escape(id)}"]`);
    if (!el) continue;
    items.push({ id, label: el.dataset.annoLabel || id, b, el });
  }
  if (!items.length) {
    pane.innerHTML = `<h3>Annotations on this page</h3><div class="ann-empty">Hover a block, then 👍 👎 ❓ or 💬 to mark it.</div>`;
    return;
  }
  let html = `<h3>On this page</h3>`;
  for (const it of items) {
    const r = it.b.reactions || {};
    const reactions = [];
    if (r.like) reactions.push("👍");
    if (r.dislike) reactions.push("👎");
    if (r.question) reactions.push("❓");
    const cls = r.dislike ? "dislike" : (r.question ? "question" : (r.like ? "like" : (it.b.edits && Object.keys(it.b.edits).length ? "edit" : "")));
    const hasNote = it.b.note && it.b.note.trim();
    const editsCount = it.b.edits ? Object.keys(it.b.edits).length : 0;
    html += `
      <div class="ann-card ${cls} ${hasNote ? 'has-note' : ''}" data-target="${escapeHtml(it.id)}">
        <div class="ann-label">${escapeHtml(it.label)}</div>
        <div class="ann-reactions">${reactions.join(" ")} ${editsCount ? `<span title="${editsCount} edits">✎ ${editsCount}</span>` : ""}</div>
        ${hasNote ? `<div class="ann-note">${escapeHtml(it.b.note)}</div>` : ""}
      </div>
    `;
  }
  pane.innerHTML = html;
  pane.querySelectorAll(".ann-card").forEach(card => {
    card.addEventListener("click", () => {
      const target = card.dataset.target;
      const el = document.querySelector(`[data-anno-id="${CSS.escape(target)}"]`);
      if (el) {
        document.querySelectorAll(".block.focused").forEach(b => b.classList.remove("focused"));
        el.classList.add("focused");
        el.scrollIntoView({ behavior: "smooth", block: "center" });
        setTimeout(() => el.classList.remove("focused"), 2000);
      }
    });
  });
}

// ============================================================
// Edit mode + theme
// ============================================================

function setEditMode(on) {
  const s = getState();
  s.editMode = on;
  document.body.classList.toggle("edit-mode", on);
  document.querySelectorAll(".editable").forEach(el => { el.contentEditable = on ? "true" : "false"; });
  const btn = document.getElementById("btn-edit");
  if (btn) btn.classList.toggle("active", on);
  saveState();
}

function setTheme(t) {
  const s = getState();
  s.theme = t;
  document.documentElement.dataset.theme = t;
  const btn = document.getElementById("btn-theme");
  if (btn) btn.textContent = t === "dark" ? "☀ Light" : "☾ Dark";
  saveState();
}

// ============================================================
// Export
// ============================================================

function exportMarkdown() {
  const today = new Date().toISOString().slice(0,10);
  const lines = [`# Spec annotations — ${today}`, ""];
  const groups = {};
  const s = getState();
  for (const id in s.blocks) {
    const b = s.blocks[id];
    const reacted = b.reactions?.like || b.reactions?.dislike || b.reactions?.question;
    const noted = b.note && b.note.trim();
    const edited = b.edits && Object.keys(b.edits).length;
    if (!reacted && !noted && !edited) continue;
    const [page] = id.split(":");
    (groups[page] = groups[page] || []).push({ id, b });
  }
  const order = pageOrder();
  const pages = Object.keys(groups).sort((a, b) => {
    if (order) {
      const ai = order.indexOf(a), bi = order.indexOf(b);
      return (ai === -1 ? 99 : ai) - (bi === -1 ? 99 : bi);
    }
    return a.localeCompare(b);
  });
  if (!pages.length) lines.push("_No annotations yet._");
  for (const page of pages) {
    lines.push(`## ${page}.md`, "");
    for (const { id, b } of groups[page]) {
      const label = document.querySelector(`[data-anno-id="${CSS.escape(id)}"]`)?.dataset.annoLabel || id;
      lines.push(`### ${label}  \`${id}\``);
      const r = [];
      if (b.reactions?.like) r.push("👍 like");
      if (b.reactions?.dislike) r.push("👎 dislike");
      if (b.reactions?.question) r.push("❓ question");
      if (r.length) lines.push(`**${r.join(", ")}**`, "");
      if (b.note && b.note.trim()) lines.push("> " + b.note.split("\n").join("\n> "), "");
      if (b.edits && Object.keys(b.edits).length) {
        lines.push("**Edits:**", "");
        for (const editId in b.edits) {
          const e = b.edits[editId];
          lines.push(`- _${editId}_`);
          lines.push("  ```diff");
          lines.push("  - " + (e.original || "").replace(/\n/g, "\n  - "));
          lines.push("  + " + (e.current || "").replace(/\n/g, "\n  + "));
          lines.push("  ```");
        }
        lines.push("");
      }
      lines.push("");
    }
  }
  showExportModal(lines.join("\n"));
}

function showExportModal(md) {
  let modal = document.getElementById("export-modal");
  if (!modal) {
    modal = document.createElement("div");
    modal.className = "modal-backdrop"; modal.id = "export-modal";
    modal.innerHTML = `
      <div class="modal">
        <h3>Export annotations</h3>
        <textarea readonly></textarea>
        <div class="modal-actions">
          <button class="btn" data-act="close">Close</button>
          <button class="btn" data-act="copy">Copy</button>
          <button class="btn primary" data-act="download">Download .md</button>
        </div>
      </div>
    `;
    document.body.appendChild(modal);
    modal.addEventListener("click", e => { if (e.target === modal) modal.classList.remove("open"); });
    modal.querySelector('[data-act="close"]').addEventListener("click", () => modal.classList.remove("open"));
    modal.querySelector('[data-act="copy"]').addEventListener("click", () => {
      const ta = modal.querySelector("textarea");
      ta.select(); navigator.clipboard.writeText(ta.value);
      const btn = modal.querySelector('[data-act="copy"]');
      btn.textContent = "Copied!"; setTimeout(() => btn.textContent = "Copy", 1200);
    });
    modal.querySelector('[data-act="download"]').addEventListener("click", () => {
      const ta = modal.querySelector("textarea");
      const blob = new Blob([ta.value], { type: "text/markdown" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a"); a.href = url;
      a.download = `${pageSlug()}-annotations-${new Date().toISOString().slice(0,10)}.md`;
      a.click(); URL.revokeObjectURL(url);
    });
  }
  modal.querySelector("textarea").value = md;
  modal.classList.add("open");
}

function resetAll() {
  if (!confirm("Clear all reactions, notes, and edits? This cannot be undone.")) return;
  const s = getState();
  s.blocks = {};
  saveState();
  location.reload();
}

// ============================================================
// Misc
// ============================================================

function setActiveNav() {
  const page = (location.pathname.split("/").pop() || "index.html").replace(".html", "");
  document.querySelectorAll(".topbar nav a").forEach(a => {
    const target = (a.getAttribute("href") || "").replace(".html", "");
    if (target === page) a.classList.add("active");
  });
}

function initMermaid() {
  if (typeof mermaid !== "undefined") {
    const dark = getState().theme === "dark";
    mermaid.initialize({
      startOnLoad: false,
      theme: dark ? "dark" : "default",
      themeVariables: dark ? {
        background: "#161b22", primaryColor: "#1c232c", primaryTextColor: "#c9d1d9",
        primaryBorderColor: "#3b475a", lineColor: "#8b949e",
        secondaryColor: "#2a3441", tertiaryColor: "#1c232c", fontSize: "13px"
      } : {
        background: "#ffffff", primaryColor: "#f6f8fa", primaryTextColor: "#1f2328",
        primaryBorderColor: "#d0d7de", lineColor: "#656d76", fontSize: "13px"
      }
    });
    mermaid.run({ querySelector: ".mermaid" });
  }
}

function openDiagramFullscreen(wrap) {
  const svg = wrap.querySelector("svg");
  if (!svg) return;
  const captionEl = wrap.querySelector(".diagram-caption");

  const overlay = document.createElement("div");
  overlay.className = "diagram-fs-overlay";
  overlay.setAttribute("role", "dialog");
  overlay.setAttribute("aria-modal", "true");
  overlay.setAttribute("aria-label", svg.getAttribute("aria-label") || "Diagram");

  const closeBtn = document.createElement("button");
  closeBtn.className = "diagram-fs-close"; closeBtn.type = "button";
  closeBtn.setAttribute("aria-label", "Close fullscreen"); closeBtn.textContent = "✕";

  const stage = document.createElement("div");
  stage.className = "diagram-fs-stage";
  const svgClone = svg.cloneNode(true);
  svgClone.removeAttribute("width"); svgClone.removeAttribute("height");
  if (!svgClone.hasAttribute("preserveAspectRatio")) svgClone.setAttribute("preserveAspectRatio", "xMidYMid meet");
  stage.appendChild(svgClone);

  overlay.appendChild(closeBtn); overlay.appendChild(stage);
  if (captionEl) {
    const cap = document.createElement("div");
    cap.className = "diagram-fs-caption"; cap.innerHTML = captionEl.innerHTML;
    overlay.appendChild(cap);
  }
  const hint = document.createElement("div");
  hint.className = "diagram-fs-hint"; hint.textContent = "ESC or click backdrop to close";
  overlay.appendChild(hint);

  function dismiss() {
    overlay.remove(); document.removeEventListener("keydown", onKey);
    document.body.style.overflow = "";
  }
  function onKey(e) { if (e.key === "Escape") dismiss(); }

  overlay.addEventListener("click", (e) => { if (e.target === overlay) dismiss(); });
  closeBtn.addEventListener("click", (e) => { e.stopPropagation(); dismiss(); });
  document.addEventListener("keydown", onKey);
  document.body.style.overflow = "hidden";
  document.body.appendChild(overlay);
}

function setupDiagramFullscreen() {
  document.querySelectorAll(".diagram-wrap, .svg-stage").forEach(wrap => {
    if (wrap.dataset.fsBound) return;
    wrap.dataset.fsBound = "1";

    const btn = document.createElement("button");
    btn.className = "diagram-expand-btn"; btn.type = "button";
    btn.setAttribute("aria-label", "Expand diagram to fullscreen");
    btn.title = "Expand to fullscreen"; btn.textContent = "⛶";
    btn.addEventListener("click", (e) => { e.stopPropagation(); openDiagramFullscreen(wrap); });
    wrap.appendChild(btn);

    wrap.addEventListener("click", (e) => {
      if (e.target.closest("a, .block-gutter, .editable, .note-input, button")) return;
      openDiagramFullscreen(wrap);
    });
  });
}

// ============================================================
// Init
// ============================================================

document.addEventListener("DOMContentLoaded", async () => {
  setActiveNav();
  setTheme(getState().theme || "dark");

  await renderComponents();

  setupBlocks();
  if (getState().editMode) setEditMode(true);
  refreshStat();
  refreshPane();
  initMermaid();
  setupDiagramFullscreen();
  setTimeout(setupDiagramFullscreen, 250);

  document.getElementById("btn-theme")?.addEventListener("click", () => setTheme(getState().theme === "dark" ? "light" : "dark"));
  document.getElementById("btn-edit")?.addEventListener("click", () => setEditMode(!getState().editMode));
  document.getElementById("btn-export")?.addEventListener("click", exportMarkdown);
  document.getElementById("btn-reset")?.addEventListener("click", resetAll);
});
