export const meta = {
  name: 'pr-disposition',
  description: 'Triage one PR\'s new review findings against its tracker, verify pushbacks adversarially, implement accepted fixes, then push and respond',
  whenToUse: 'Dispatched by the pr-monitor skill for a single PR that has new review activity and a guarded worktree mapping. One in-flight run per PR.',
  phases: [
    { title: 'Ground', detail: 'read child tracker, parent goal, and the current diff' },
    { title: 'Triage', detail: 'classify each finding as fix / pushback / insufficient_context' },
    { title: 'Verify', detail: 'adversarially refute each pushback with distinct lenses' },
    { title: 'Implement', detail: 'apply accepted fixes, test, commit, push (single agent, one worktree)' },
    { title: 'Respond', detail: 'post one top-level comment and record outward actions' },
  ],
}

// ---------------------------------------------------------------- inputs

const input = args || {}
const PR = input.pr
const REPO = input.repo
const WORKTREE = input.worktree
const BRANCH = input.branch
const CHILD_TRACKER = input.childTracker
const PARENT_TRACKER = input.parentTracker
const HEAD_SHA = input.headSha
const REPORT_ONLY = input.reportOnly === true
const FINDINGS = Array.isArray(input.findings) ? input.findings : []

// BRANCH is required because the worktree guard is a string comparison against it — a
// guard with no right-hand side silently passes and lets a fix land on another PR's
// branch. CHILD_TRACKER is required because it is the only durable dedup store; without
// it, "did I already post this?" has nowhere to look and comments duplicate.
const missing = ['pr', 'repo', 'worktree', 'branch', 'headSha', 'childTracker']
  .filter(k => !input[k])
if (missing.length) {
  throw new Error('pr-disposition missing required args: ' + missing.join(', ') +
    '. Refusing to run — each of these is load-bearing for a safety check, not optional metadata.')
}
if (!FINDINGS.length) {
  log('No findings passed — nothing to disposition.')
  return { pr: PR, branch: BRANCH, headSha: HEAD_SHA, verdicts: [], implemented: null, responded: false, cycleComplete: true, blockers: [], nextAction: 'evaluate-merge-gate', note: 'no findings' }
}

// A single PR maps to a single worktree, so all editing is serialized through one
// agent. Never fan out the Implement phase: concurrent agents in one worktree corrupt
// each other's index. Never use isolation:'worktree' either — that creates an ephemeral
// throwaway checkout, the opposite of this PR's persistent owning worktree.

const MAX_PUSHBACK_VERIFY = 4
const REFUTE_LENSES = ['correctness', 'security-and-data-exposure', 'does-the-premise-hold']

// Dedup keys must be head-INDEPENDENT. Keying an "already responded" record to a head SHA
// is self-defeating, because a successful cycle pushes and therefore moves the head — so
// the next lookup always misses and the comment posts again. Key on the finding's own
// identity instead, which survives both a head move and a context compaction.
function findingKey(finding, i) {
  const text = typeof finding === 'string'
    ? finding
    : [finding && finding.path, finding && finding.line, finding && finding.author,
       finding && finding.body || finding && finding.summary].filter(Boolean).join(' ')
  const norm = String(text || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '')
  return 'pr' + PR + '/f' + (i + 1) + '/' + (norm.slice(0, 48) || 'unlabelled')
}

const FINDING_KEYS = FINDINGS.map(findingKey)

const CONTEXT = [
  'PR: #' + PR + ' in ' + REPO,
  'Head branch: ' + BRANCH,
  'Head SHA: ' + HEAD_SHA,
  'Owning worktree: ' + WORKTREE,
  'Child tracker: ' + CHILD_TRACKER,
  'Parent tracker: ' + (PARENT_TRACKER || '(none recorded)'),
].join('\n')

// The agent guarded this mapping at tick time, but Ground + Triage + refutation can take
// many minutes, during which the user may check out another branch in this worktree. This
// re-guard closes that window, so it must be at least as strict as the tick-time one.
const WORKTREE_GUARD = [
  'GUARD — run both checks before making ANY edit:',
  '',
  '  git -C ' + WORKTREE + ' rev-parse --abbrev-ref HEAD',
  '      must print exactly: ' + BRANCH,
  '',
  '  git -C ' + WORKTREE + ' status --porcelain',
  '      must print nothing. Pre-existing uncommitted changes are not yours to commit.',
  '',
  'If either check fails: set guardFailed=true, make NO edits, do not commit, do not push,',
  'and return immediately. A mismatch means the worktree no longer owns PR #' + PR + ', so',
  'editing would land this fix on branch "' + BRANCH + '"\'s replacement — i.e. on a',
  'different PR. Never "fix" the mismatch by checking out ' + BRANCH + ' yourself; the',
  'user may be mid-task in that worktree.',
  '',
  'All git and push operations use -C ' + WORKTREE + ' and target branch ' + BRANCH + '.',
].join('\n')

// ---------------------------------------------------------------- schemas

const GROUNDING_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['trackerPresent', 'declaredScope', 'nonGoals', 'priorDecisions', 'diffSummary', 'coverageGaps'],
  properties: {
    trackerPresent: { type: 'boolean', description: 'Whether a child tracker with real content was found' },
    declaredScope: { type: 'string' },
    nonGoals: { type: 'array', items: { type: 'string' } },
    priorDecisions: {
      type: 'array',
      description: 'Decisions already recorded in the tracker that a reviewer finding might collide with',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['decision', 'rationale', 'source'],
        properties: {
          decision: { type: 'string' },
          rationale: { type: 'string' },
          source: { type: 'string', description: 'File and line or event ts' },
        },
      },
    },
    diffSummary: { type: 'string' },
    coverageGaps: {
      type: 'array',
      description: 'Areas the reviewer touches that the tracker does NOT cover',
      items: { type: 'string' },
    },
  },
}

const TRIAGE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['verdict', 'rationale', 'evidence', 'groundedInTracker'],
  // pushbackGround is deliberately not globally required (it is meaningless for a fix),
  // but a pushback without it is rejected in code below — schema optionality must not
  // become a way to smuggle an ungrounded dismissal past the rubric.
  properties: {
    verdict: { type: 'string', enum: ['fix', 'pushback', 'insufficient_context'] },
    rationale: { type: 'string' },
    evidence: { type: 'string', description: 'Specific file:line, commit, event ts, or test. Required for pushback.' },
    groundedInTracker: { type: 'boolean' },
    pushbackGround: {
      type: 'string',
      enum: ['premise-wrong', 'already-handled', 'out-of-scope', 'speculative', 'regresses-recorded-decision'],
    },
    proposedFix: { type: 'string' },
    openQuestion: { type: 'string', description: 'For insufficient_context: the specific question for the user' },
  },
}

const REFUTE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['refuted', 'reasoning'],
  properties: {
    refuted: { type: 'boolean', description: 'true = the pushback is wrong and the reviewer is right' },
    reasoning: { type: 'string' },
  },
}

const IMPL_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['applied', 'testsRun', 'testsPassed', 'committed', 'pushed'],
  properties: {
    applied: { type: 'array', items: { type: 'string' } },
    filesChanged: { type: 'array', items: { type: 'string' } },
    testsRun: { type: 'array', items: { type: 'string' } },
    testsPassed: { type: 'boolean' },
    committed: { type: 'boolean' },
    commitSha: { type: 'string' },
    pushed: { type: 'boolean' },
    recordedPush: { type: 'boolean', description: 'Whether pr.push.completed was appended to the child tracker events.jsonl' },
    guardFailed: { type: 'boolean', description: 'true if the worktree HEAD guard failed and nothing was edited' },
    remainingRisks: { type: 'array', items: { type: 'string' } },
    blockers: { type: 'array', items: { type: 'string' } },
  },
}

const RESPOND_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['posted', 'commentBody'],
  properties: {
    posted: { type: 'boolean' },
    commentBody: { type: 'string' },
    reviewRequested: { type: 'boolean' },
    recordedEvent: { type: 'boolean', description: 'Whether the outward action was appended to the child tracker events.jsonl' },
  },
}

// ---------------------------------------------------------------- 1. ground

phase('Ground')

const grounding = await agent([
  'Build the grounding context for disposing of review findings on this PR.',
  '',
  CONTEXT,
  '',
  'Do all of the following, reading files in full rather than skimming:',
  '1. Read the child tracker goal.md (declared scope and non-goals), tasks.md, and',
  '   events.jsonl. If the path does not exist or is effectively empty, set',
  '   trackerPresent=false — do not invent grounding.',
  '2. Read the parent tracker goal.md if a path was given.',
  '3. Read the CURRENT diff at the current head: gh pr diff ' + PR + ' --repo ' + REPO,
  '4. Read the affected source files in full, not only the diff hunks.',
  '',
  'Extract every decision already recorded in the tracker that a reviewer might now be',
  'questioning, with its rationale and where you found it. Then list coverageGaps: areas',
  'the review touches that the tracker does NOT record any reasoning about.',
  '',
  'coverageGaps is the most important field. Downstream triage is forbidden from pushing',
  'back on anything in it, so under-reporting a gap causes a wrongful dismissal of a',
  'reviewer. When unsure whether the tracker really covers something, call it a gap.',
].join('\n'), {
  label: 'ground:pr-' + PR,
  phase: 'Ground',
  schema: GROUNDING_SCHEMA,
  effort: 'medium',
})

if (!grounding) {
  throw new Error('Grounding failed for PR #' + PR + '; refusing to triage findings without grounding.')
}

log('Grounded PR #' + PR + ' — tracker ' + (grounding.trackerPresent ? 'present' : 'MISSING') +
    ', ' + (grounding.priorDecisions || []).length + ' prior decisions, ' +
    ((grounding.coverageGaps || []).length) + ' coverage gaps, ' + FINDINGS.length + ' findings')

// If there is no tracker, or grounding surfaced no prior decisions, then there is no
// recorded reasoning for a pushback to stand on — so pushback is forbidden outright for
// this run rather than merely discouraged. The previous formulation rendered an absent
// coverageGaps list as "GAPS: (none)", which told triage the exact inverse of the truth:
// that nothing was off-limits.
const NO_GROUNDING = grounding.trackerPresent !== true ||
  !(grounding.priorDecisions || []).length

const GROUND_BRIEF = [
  'Declared scope: ' + grounding.declaredScope,
  'Non-goals: ' + ((grounding.nonGoals || []).join('; ') || '(none recorded)'),
  'Tracker present: ' + grounding.trackerPresent,
  'Prior recorded decisions:',
  ...((grounding.priorDecisions || []).length
    ? grounding.priorDecisions.map(d => '  - ' + d.decision + ' — ' + d.rationale + ' [' + d.source + ']')
    : ['  (NONE RECORDED — no decision history to ground a pushback on)']),
  'Tracker coverage GAPS — pushback is FORBIDDEN in these areas:',
  ...((grounding.coverageGaps || []).length
    ? grounding.coverageGaps.map(g => '  - ' + g)
    : ['  (none itemised — see the blanket rule below if it applies)']),
  '',
  NO_GROUNDING
    ? 'PUSHBACK IS FORBIDDEN FOR THIS ENTIRE RUN. ' +
      (grounding.trackerPresent !== true
        ? 'This PR has no child tracker, '
        : 'The tracker records no prior decisions, ') +
      'so there is no recorded reasoning any pushback could cite. Every finding must be ' +
      'either "fix" or "insufficient_context". A pushback here would be refusal with no ' +
      'evidence behind it, which costs far more than an unnecessary fix.'
    : 'Pushback is permitted only outside the gap list above, and only with concrete ' +
      'evidence you have personally verified.',
  '',
  'Diff summary: ' + grounding.diffSummary,
].join('\n')

if (NO_GROUNDING) {
  log('PR #' + PR + ': no usable tracker grounding (present=' + grounding.trackerPresent +
      ', priorDecisions=' + (grounding.priorDecisions || []).length +
      ') — pushback disabled for this run; findings resolve to fix or insufficient_context.')
}

// ------------------------------------------------- 2+3. triage, then verify pushbacks

// pipeline, not parallel: each finding flows triage -> verify independently, so a
// finding needing three refuters does not hold up a finding that was a clean fix.
let pushbackVerifyBudget = MAX_PUSHBACK_VERIFY

const disposed = await pipeline(
  FINDINGS,

  (finding, _orig, i) => agent([
    'Classify ONE reviewer finding on this PR as fix / pushback / insufficient_context.',
    '',
    CONTEXT,
    '',
    '--- GROUNDING ---',
    GROUND_BRIEF,
    '',
    '--- FINDING ---',
    typeof finding === 'string' ? finding : JSON.stringify(finding, null, 2),
    '',
    '--- RUBRIC ---',
    'Read the rubric in full and apply it exactly:',
    '  ~/.claude/skills/pr-monitor/references/disposition.md',
    '',
    'Treat the finding as a hypothesis. Verify it against the real code at the current',
    'head before deciding — read the files, do not rely on the diff summary.',
    '',
    'Hard constraints:',
    '- "pushback" requires a specific pushbackGround AND concrete evidence (file:line,',
    '  commit, or event). No evidence means no pushback.',
    '- If the finding falls in a tracker coverage gap listed above, you MUST return',
    '  insufficient_context or fix. Never pushback there.',
    '- If the fix is smaller than the argument against it, return fix. Cheap compliance',
    '  beats relitigating trivia.',
    '- A wrong pushback costs far more than a wrong fix. Under genuine uncertainty,',
    '  the reviewer is right.',
  ].join('\n'), {
    label: 'triage:' + PR + '#' + (i + 1),
    phase: 'Triage',
    schema: TRIAGE_SCHEMA,
    effort: 'high',
  }).then(t => ({ finding, index: i, triage: t })),

  async (result) => {
    if (!result || !result.triage) return result
    if (result.triage.verdict !== 'pushback') return result

    // Enforce the cardinal rule in code, not only in the rubric prose. A pushback that
    // cannot name a ground, admits it is not tracker-grounded, or arrives in a run with no
    // grounding at all becomes insufficient_context and goes to the user. These fields
    // were previously required by the schema and then read by nothing.
    const ungrounded = NO_GROUNDING ||
      result.triage.groundedInTracker !== true ||
      !result.triage.pushbackGround
    if (ungrounded) {
      const why = NO_GROUNDING
        ? 'the run has no usable tracker grounding'
        : result.triage.groundedInTracker !== true
          ? 'triage reported groundedInTracker=false'
          : 'triage named no pushbackGround'
      log('Rejecting ungrounded pushback on PR #' + PR + ' finding ' + (result.index + 1) +
          ' (' + why + ') — escalating to the user instead.')
      return {
        ...result,
        triage: {
          ...result.triage,
          verdict: 'insufficient_context',
          openQuestion: 'Triage wanted to push back on this, but ' + why + ', so it was ' +
            'not permitted to. Original rationale: ' + result.triage.rationale +
            ' — your call on whether this is genuinely out of scope or should be fixed.',
        },
        ungroundedPushbackRejected: true,
      }
    }

    if (pushbackVerifyBudget <= 0) {
      log('Pushback verification budget exhausted — demoting finding ' + (result.index + 1) +
          ' on PR #' + PR + ' from pushback to insufficient_context and escalating to the user.')
      return {
        ...result,
        triage: {
          ...result.triage,
          verdict: 'insufficient_context',
          openQuestion: 'Triage proposed pushback but the per-run verification budget (' +
            MAX_PUSHBACK_VERIFY + ') was exhausted, so it was not adversarially checked. ' +
            'Original ground: ' + (result.triage.pushbackGround || 'unstated') + '. ' +
            'Original rationale: ' + result.triage.rationale,
        },
        budgetDemoted: true,
      }
    }
    pushbackVerifyBudget -= 1

    // Perspective-diverse refutation: distinct lenses catch failure modes that
    // redundant identical skeptics cannot.
    const votes = await parallel(REFUTE_LENSES.map(lens => () => agent([
      'You are refuting a proposed PUSHBACK against a code reviewer. Your job is to show',
      'the reviewer is RIGHT and the pushback is wrong. Examine it through this lens:',
      '  ' + lens,
      '',
      CONTEXT,
      '',
      '--- REVIEWER FINDING ---',
      typeof result.finding === 'string' ? result.finding : JSON.stringify(result.finding, null, 2),
      '',
      '--- PROPOSED PUSHBACK ---',
      'Ground: ' + (result.triage.pushbackGround || '(unstated)'),
      'Rationale: ' + result.triage.rationale,
      'Evidence offered: ' + result.triage.evidence,
      '',
      '--- GROUNDING ---',
      GROUND_BRIEF,
      '',
      'Verify the offered evidence actually says what the pushback claims — open the cited',
      'file and line. Fabricated or misread evidence means refuted=true.',
      '',
      'Set refuted=true if the reviewer is right, if the evidence does not hold up, or if',
      'you cannot confirm the pushback. Default to refuted=true under uncertainty: the',
      'cost of wrongly dismissing a correct reviewer is much higher than the cost of',
      'making a fix that turns out to be unnecessary.',
    ].join('\n'), {
      label: 'refute:' + PR + '#' + (result.index + 1) + ':' + lens,
      phase: 'Verify',
      schema: REFUTE_SCHEMA,
      effort: 'xhigh',
    })))

    const counted = votes.filter(Boolean)
    const refutations = counted.filter(v => v.refuted).length
    // Survives only on a majority failing to refute. A dead/failed verifier counts
    // against the pushback: fewer than 2 usable votes cannot clear it.
    const survives = counted.length >= 2 && refutations < Math.ceil(counted.length / 2)

    if (survives) {
      log('Pushback on PR #' + PR + ' finding ' + (result.index + 1) + ' survived ' +
          counted.length + ' lenses (' + refutations + ' refuted).')
      return { ...result, verified: true, refutations, voters: counted.length }
    }

    log('Pushback on PR #' + PR + ' finding ' + (result.index + 1) + ' REFUTED (' +
        refutations + '/' + counted.length + ') — converting to fix.')
    return {
      ...result,
      triage: {
        ...result.triage,
        verdict: 'fix',
        rationale: 'Proposed pushback was refuted on adversarial review (' + refutations + '/' +
          counted.length + ' lenses). Refutation: ' +
          counted.filter(v => v.refuted).map(v => v.reasoning).join(' | '),
        proposedFix: result.triage.proposedFix || 'Address the reviewer finding as stated.',
      },
      verified: true,
      refutations,
      voters: counted.length,
      convertedFromPushback: true,
    }
  },
)

const results = disposed.filter(Boolean).filter(r => r.triage)
const dropped = FINDINGS.length - results.length
if (dropped > 0) {
  log('WARNING: ' + dropped + ' of ' + FINDINGS.length + ' findings on PR #' + PR +
      ' failed triage and were dropped. They are NOT dispositioned and must be re-run.')
}

const toFix = results.filter(r => r.triage.verdict === 'fix')
const toPush = results.filter(r => r.triage.verdict === 'pushback')
const toEscalate = results.filter(r => r.triage.verdict === 'insufficient_context')

log('PR #' + PR + ' disposition: ' + toFix.length + ' fix, ' + toPush.length +
    ' pushback, ' + toEscalate.length + ' escalate' + (dropped ? ', ' + dropped + ' dropped' : ''))

// ---------------------------------------------------------------- 4. implement

let impl = null

if (REPORT_ONLY) {
  log('--report-only: skipping implement, commit, push, and comment for PR #' + PR + '.')
} else if (toFix.length) {
  phase('Implement')
  impl = await agent([
    'Implement the accepted review fixes for this PR in its owning worktree.',
    '',
    CONTEXT,
    '',
    WORKTREE_GUARD,
    '',
    '--- ACCEPTED FINDINGS ---',
    ...toFix.map((r, n) => [
      (n + 1) + '. ' + (typeof r.finding === 'string' ? r.finding : JSON.stringify(r.finding)),
      '   Rationale: ' + r.triage.rationale,
      '   Proposed fix: ' + (r.triage.proposedFix || '(derive the smallest root-cause fix)'),
    ].join('\n')),
    '',
    '--- HOW ---',
    'Work only inside ' + WORKTREE + '. Never edit any other worktree or repo.',
    '',
    '1. Add a task to the child tracker tasks.md for each finding BEFORE editing.',
    '2. Implement the smallest ROOT-CAUSE fix for each. If a reviewer identified a',
    '   symptom, fix the cause. Do not bundle unrelated cleanups — it makes re-review',
    '   harder and invites new findings.',
    '3. Test narrowest-first: the specific failing case, then the file/module suite, then',
    '   the relevant broader checks. Run the repo formatter and linter before committing.',
    '4. If a test fails and you cannot fix it, stop, set testsPassed=false, list it in',
    '   blockers, and do NOT commit or push. A red push wastes a reviewer cycle.',
    '5. Commit with a message describing the fixes only — no references to agentic tools.',
    '6. BEFORE pushing, check ' + CHILD_TRACKER + '/events.jsonl for a `pr.push.attempting`',
    '   or `pr.push.completed` event covering these finding keys:',
    ...FINDING_KEYS.map(k => '     ' + k),
    '   An `attempting` with no `completed` means a previous cycle may already have pushed:',
    '   run `git -C ' + WORKTREE + ' status -sb` and `git -C ' + WORKTREE + ' log origin/' +
      BRANCH + '..HEAD` to see whether the commits are already upstream. Do not blind-push.',
    '7. Append `pr.push.attempting`, then push to ' + BRANCH + ', then append',
    '   `pr.push.completed` with the commit SHA. Write-ahead ordering is required: pushing',
    '   first and dying before recording leaves no trace, and the next cycle re-does the',
    '   work and dismisses the approval a second time.',
    '8. Append events.jsonl entries for tasks, tests, and the commit as you go.',
    '   Get timestamps with: date -u +%Y-%m-%dT%H:%M:%SZ',
    '',
    'Pushing is outward-facing and dismisses existing approvals. Push exactly once, only',
    'after tests pass. Set recordedPush=true only if step 7\'s completed event was written.',
  ].join('\n'), {
    label: 'implement:pr-' + PR,
    phase: 'Implement',
    schema: IMPL_SCHEMA,
    effort: 'high',
  })

  if (!impl) {
    log('Implement agent failed on PR #' + PR + '. No comment will be posted; the tick must retry.')
    return { pr: PR, branch: BRANCH, headSha: HEAD_SHA, grounding, verdicts: results, implemented: null, responded: false, cycleComplete: false, blockers: ['the implement agent died; no fixes were verified as applied'], nextAction: 'retry-disposition', error: 'implement-failed' }
  }
  if (impl.guardFailed) {
    log('Worktree HEAD guard FAILED for PR #' + PR + ' — stale mapping, nothing edited.')
    return { pr: PR, branch: BRANCH, headSha: HEAD_SHA, grounding, verdicts: results, implemented: impl, responded: false, cycleComplete: false, blockers: ['worktree ' + WORKTREE + ' no longer owns branch ' + BRANCH + ' (or is dirty); nothing was edited'], nextAction: 'report-drift', error: 'worktree-guard-failed' }
  }
  if (!impl.testsPassed || !impl.pushed) {
    log('PR #' + PR + ' not pushed (testsPassed=' + impl.testsPassed + ', pushed=' + impl.pushed +
        '). Skipping the response comment so it cannot describe unpushed work.')
    return { pr: PR, branch: BRANCH, headSha: HEAD_SHA, grounding, verdicts: results, implemented: impl, responded: false, cycleComplete: false, blockers: ((impl.blockers || []).length ? impl.blockers : ['fixes did not pass tests and were not pushed']), nextAction: 'needs-attention', error: 'fixes-incomplete' }
  }
}

// ---------------------------------------------------------------- 5. respond

if (REPORT_ONLY) {
  return { pr: PR, branch: BRANCH, headSha: HEAD_SHA, grounding, verdicts: results, implemented: null, responded: false, cycleComplete: true, blockers: [], nextAction: 'report-only', reportOnly: true, dropped }
}

phase('Respond')

const respond = await agent([
  'Post exactly ONE top-level comment on this PR summarizing the disposition, then',
  'request re-review.',
  '',
  CONTEXT,
  '',
  '--- FIXED ---',
  ...(toFix.length ? toFix.map((r, n) => (n + 1) + '. ' +
      (typeof r.finding === 'string' ? r.finding : JSON.stringify(r.finding)) +
      '\n   Root cause: ' + r.triage.rationale) : ['(none)']),
  impl ? 'Commit: ' + (impl.commitSha || '(unrecorded)') + '\nTests: ' + (impl.testsRun || []).join(', ') : '',
  impl && (impl.remainingRisks || []).length ? 'Remaining risks: ' + impl.remainingRisks.join('; ') : '',
  '',
  '--- PUSHING BACK (each survived adversarial review) ---',
  ...(toPush.length ? toPush.map((r, n) => (n + 1) + '. ' +
      (typeof r.finding === 'string' ? r.finding : JSON.stringify(r.finding)) +
      '\n   Ground: ' + (r.triage.pushbackGround || '') +
      '\n   Reasoning: ' + r.triage.rationale +
      '\n   Evidence: ' + r.triage.evidence) : ['(none)']),
  '',
  '--- NEEDS THE AUTHOR\'S CALL ---',
  ...(toEscalate.length ? toEscalate.map((r, n) => (n + 1) + '. ' +
      (typeof r.finding === 'string' ? r.finding : JSON.stringify(r.finding)) +
      '\n   Open question: ' + (r.triage.openQuestion || r.triage.rationale)) : ['(none)']),
  '',
  '--- DEDUP: DO THIS FIRST, BEFORE WRITING ANYTHING ---',
  'Finding keys covered by this comment:',
  ...FINDING_KEYS.map(k => '  ' + k),
  '',
  'Read ' + CHILD_TRACKER + '/events.jsonl and search for these keys. Note that the keys',
  'are deliberately head-independent — do NOT scope your search to head ' + HEAD_SHA + ',',
  'because our own push moves the head and a head-scoped search would always miss.',
  '',
  '- A `pr.comment.posted` event covering all of these keys → already answered. Set',
  '  posted=false, explain, and STOP. Duplicate comments on a reviewer thread are the',
  '  worst failure mode this system has.',
  '- A `pr.comment.attempting` event with NO matching `pr.comment.posted` → a previous',
  '  cycle died mid-post. Do not assume either way: run',
  '    gh pr view ' + PR + ' --repo ' + REPO + ' --json comments',
  '  and look for our own prior comment. If it is there, record the missing',
  '  `pr.comment.posted` event and STOP. Only post if it is genuinely absent.',
  '- Neither → proceed, covering only the keys with no prior record.',
  '',
  '--- WRITE-AHEAD: record intent BEFORE acting ---',
  'Append a `pr.comment.attempting` event with these keys to ' + CHILD_TRACKER +
    '/events.jsonl BEFORE calling gh, then post, then append `pr.comment.posted`.',
  'Ordering matters: if you post first and die before recording, the next cycle has no',
  'trace and posts again. Recording first turns that crash into a detectable ambiguity',
  'rather than a silent duplicate.',
  '',
  '--- HOW TO WRITE IT ---',
  'Three sections, omitting any that is empty: what was fixed (with commit SHA and one',
  'line of root cause each), what is being pushed back on (with the concrete evidence,',
  'phrased as information and explicitly inviting correction — you may be wrong), and',
  'what needs the author\'s decision (as specific questions).',
  '',
  'Be direct and short. No agentic-tool references, no status-update filler, no apology.',
  '',
  'Sequence, in this exact order:',
  '  1. append pr.comment.attempting (with the finding keys)',
  '  2. gh pr comment ' + PR + ' --repo ' + REPO + ' --body-file <tmpfile>',
  '  3. append pr.comment.posted (with the finding keys and the comment URL)',
  '  4. request re-review from the reviewers who left the findings',
  'Timestamps come from: date -u +%Y-%m-%dT%H:%M:%SZ',
  '',
  'Set recordedEvent=true only if step 3 actually succeeded. It is checked by the caller,',
  'and a false value means the next cycle cannot tell whether you posted.',
].join('\n'), {
  label: 'respond:pr-' + PR,
  phase: 'Respond',
  schema: RESPOND_SCHEMA,
  effort: 'medium',
})

const responded = respond ? respond.posted === true : false

// Anything that means a reviewer has NOT been fully and accurately answered must block the
// unattended merge paths. Arming --auto on a PR with a dropped finding is irreversible the
// moment a human approves: the comment reads as a complete disposition, the reviewer
// approves, and GitHub merges work that was never triaged.
const blockers = []
if (dropped > 0) blockers.push(dropped + ' finding(s) failed triage and were never dispositioned')
if (!responded) blockers.push('the response comment was not posted')
if (respond && respond.recordedEvent !== true) blockers.push('the posted comment was not durably recorded, so a later tick cannot tell it happened')
if (impl && impl.pushed && impl.recordedPush !== true) blockers.push('the push was not durably recorded')
if (toEscalate.length) blockers.push(toEscalate.length + ' finding(s) need the author\'s decision')

if (blockers.length) {
  log('PR #' + PR + ' will NOT be advanced toward merge: ' + blockers.join('; ') + '.')
}

return {
  pr: PR,
  branch: BRANCH,
  headSha: HEAD_SHA,
  grounding,
  verdicts: results,
  counts: { fix: toFix.length, pushback: toPush.length, escalate: toEscalate.length, dropped },
  implemented: impl,
  responded,
  response: respond,
  // A completed cycle means every finding reached a verdict AND the reviewer was answered
  // and that fact was recorded. The agent uses this to decide whether to re-dispatch: a
  // failed cycle produces no provider-side change, so without this flag the PR livelocks.
  cycleComplete: blockers.length === 0,
  blockers,
  // The agent, not this workflow, owns the merge gate and cleanup.
  nextAction: blockers.length ? 'needs-attention'
    : (impl && impl.pushed) ? 'arm-auto-merge'
    : 'evaluate-merge-gate',
}
