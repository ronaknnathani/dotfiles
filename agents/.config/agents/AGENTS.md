# AGENTS.md

Working agreement and coding standards for AI agents (Claude Code and others) working in
**rnathani**'s repositories. Part 1 is how to *work*; Part 2 is the code/review *standards* mined
from 5 months of PR review comments; Part 3 is PR & workflow conventions. Repo-specific rules live
in `<repo>/AGENTS.md` and take precedence within that repo.

**Tradeoff:** these guidelines bias toward caution over speed. For trivial tasks, use judgment.

---

# Part 1 — How to work

## Think before coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## Surgical changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that *your* changes made unused; don't remove pre-existing dead code unless asked.
- The test: every changed line should trace directly to the request.

## Goal-driven execution

**Define success criteria. Loop until verified.**

- Turn tasks into verifiable goals: "add validation" → "write tests for invalid inputs, then make them pass"; "fix the bug" → "write a test that reproduces it, then make it pass"; "refactor X" → "ensure tests pass before and after".
- For multi-step tasks, state a brief plan with a verification check per step.
- Strong success criteria let you loop independently; weak criteria ("make it work") force constant clarification.

---

# Part 2 — Code & review standards

## Errors

- Never ignore an error. Don't use `_` to drop one, and don't swallow it with a log-and-continue.
- Always wrap errors with context (`fmt.Errorf("...: %w", err)`) so the origin is clear when debugging.
- Put identifying detail in the wrap — which file, which key failed — not just a generic verb.
- When you expect a specific error, assert it (e.g. `errors.Is(err, ...)`/`IsNotFound`) and only then proceed; if it's anything else, return it.
- Error messages must be actionable: name the thing that failed and the value used (e.g. the file path that couldn't be opened).
- When validating multiple things, aggregate the errors and report them all at once, not the first one only.
- Prefer returning an error over silently falling back to a default; a one-sided/partial input is a hard error, not a fallback.
- Return a sentinel value (e.g. `-1`) plus context rather than ignoring an error to signal an absent case.

## Control flow & readability

- Use guard clauses: handle the special/early case first and `return`, instead of nesting the body in an `if`.
- Flip a condition if the negation reads more directly (`if skip { return X }` over `if !skip { ... } else { ... }`).
- Keep functions flat. Deep nesting is a signal to extract or invert.
- Collapse redundant branches and combine code paths that do the same thing.
- Don't keep an `if` guard whose body is already covered by the assertion/expectation that follows it.

## Simplicity & avoiding over-engineering

**Minimum code that solves the problem. Nothing speculative.**

- Write the minimum code that solves the problem. If it can be smaller, rewrite it.
- No features beyond what was asked; no "flexibility" or configurability that wasn't requested.
- Don't add indirection (a helper, a wrapper, an interface) unless it earns its keep; inline a single-use helper.
- Don't complicate arithmetic or logic you don't need to — prefer the obvious formulation.
- Remove parameters, fields, loops, and arguments that are no longer used or never needed. Ask "do we need this at all?"
- Don't write defensive code for states that internal invariants make impossible. If you keep a guard for caution, add a comment saying so and why.
- Trust input that an upstream layer (webhook/admission/validation) already guaranteed; don't re-defend it deep in the stack.
- Avoid `any`/`interface{}` for structured data — define a named type that captures the shape (e.g. a struct of the pair you actually pass).
- The check: "would a senior engineer say this is overcomplicated?" If yes, simplify.

## Reuse & DRY

- Before adding a helper, check the shared utility packages for one that already does it, and reuse it.
- Consolidate repeated loops/blocks into one place; a pattern written twice is a pattern to extract.
- Reuse existing code paths that compute the same thing rather than recomputing from scratch.
- Prefer standard / well-known libraries over hand-rolled equivalents (e.g. `k8s.io/utils/set`, `maps.Keys`).
- Keep a single source of truth: when a value or instruction is needed in many places, reference one file/const instead of duplicating it.
- Don't introduce a new type/label/field when an existing one can be reused or modified.

## Naming

- Names must match what the thing actually is. Rename when a name implies something narrower or different than the behavior (e.g. don't call something `mariner...` if there's nothing mariner-specific; `Direct` shouldn't mean "by address").
- Keep names generic when the concept is generic; don't bake a company/vendor concept into a name that doesn't need it.
- Variable names should describe contents: a slice of cluster names is `clusterNames`/`clusters`, not `clusterCounts`.
- Pick names end users/operators understand. Avoid jargon that reads as "stuck" or "unknown" when it isn't (favor `WaitingFor…`/`Pending…`/`Converged` over `Stalled`/`ProgressDeadlineExceeded`).
- Match upstream/well-established terminology instead of inventing a parallel name for the same thing.
- If a name throws a reader off, fix the name and the comment together.

## Tests

- New behavior needs a test. Bug fixes need a test that fails without the fix.
- Assert exact expected values, not negations ("equals the timeout we expect", not "not the default").
- Assert whole-object equality against a constructed `expected` rather than field-by-field where practical.
- Use one consistent, simple way to construct test fixtures across a file; don't invent a new pod/object builder per test.
- Don't depend on real external systems or real endpoints in tests — use dummy/fake values.
- Keep tests fast. If a test takes many seconds (e.g. real TTL waits), restructure it; set short per-test values instead of relying on long defaults.
- Don't bump a shared/default timeout to make a test pass; pass a scoped timeout only in the block that needs it.
- Mark test helpers as helpers (`t.Helper()`).
- Remove redundant tests — if one test supersedes another or the coverage exists elsewhere, keep only one.
- Don't add a benchmark or test "just because"; each test must have a clear reason to exist.
- Don't exclude code from coverage to dodge a test — write the unit test and drop the exception.
- Skip a nil check the following equality assertion already covers.

## Comments & documentation

- Add docstrings to exported/public functions and types.
- Add a short comment where intent isn't obvious (e.g. what "drift" means here, where a flag's value is consumed).
- Comments must be readable and simple. Rewrite a comment a reviewer can't parse; delete one that says nothing.
- Code comments context for the code — they are not a place for PR-narrative, changelog, or "what I changed".
- Never leave references to private/working notes, tickets, or external scratch logs in committed comments.

## Validation & input boundaries

- Validate user input at the admission/validation/webhook boundary, not by failing later in business logic.
- Bound user-supplied values against the limit the system would configure; reject inputs that exceed it (or don't expose the input at all).
- Put a validation rule next to the field it validates.
- Make invalid states hard to express — "make it hard for users to shoot themselves in the foot."
- When tightening validation, first check it won't reject data that already exists in production (run it against real objects).

## Logging & observability

- Log at a verbosity that matches the message's importance; routine/expected lines belong at higher verbosity.
- Include the actionable context (path, name, id) in log and error strings.
- Emit a success event/metric only after the operations it claims succeeded — order it before failure-prone steps only if it represents intent, not outcome.

## Go & Kubernetes APIs

(Most of these repos are Go controllers/operators; these recur across them.)

- **Spec vs status:** `spec` is user intent; `status` holds derived/observed values. Pull values from external sources-of-truth yourself and cache them in `status` rather than letting users set them in `spec`.
- Don't define a constant in a public API package unless it's part of the public API; define it as an unexported const in the file that uses it.
- **Labels are for selectors.** If a value is metadata and nothing selects on it, make it an annotation, not a label.
- Consolidate redundant representations of the same concept (e.g. too many port types) — model it the way upstream k8s does (`corev1.ContainerPort`).
- Treat composite ids (e.g. `{name}-{ordinal}`) as opaque strings to consumers; don't make callers parse them.
- In controllers, don't requeue for something an informer/watch event will already deliver.
- Don't mutate `spec` from a reconciler; default values in the webhook so the reconciler receives everything it needs.
- Bump module major versions when making breaking changes to a published module.
- Prefer `intstr`/percentage handling that's explicit; enforce one consistent format rather than mixing int and string meanings.

## AI agents authoring AI-agent content

- When an automated agent comments or acts on a person's behalf (PR replies, reviews), it **must** clearly mark itself as automated and identify whose behalf it acts on. Don't let an agent impersonate the human.
- Don't post agent "slop" as if it were the human's considered reply.

---

# Part 3 — PRs & workflow

## PR scope & sequencing

- Keep PRs small and single-intent. If you can describe a PR as "1… 2… 3…", it's several PRs.
- Sequence stacked PRs in dependency order: **API changes → code changes → manifests/config**.
- A rename is its own PR — don't fold a rename into a feature/fix.
- Defer out-of-scope improvements to a follow-up PR (and leave a note/TODO), rather than expanding the current one.

## PR summaries

- Write PR summaries as concise prose paragraphs, not bullet lists. Focus on the why and what, not the how — the diff shows the how.
- Aim for 1–2 short paragraphs. If a paragraph is explaining mechanism, cut it.
- Don't: enumerate every caller/file the change touches, describe how the new code mirrors an existing pattern, or explain rejected alternatives. Those are all "how".
- For the `Testing Done` section, just list the commands that were run — no preamble, no per-test bullet descriptions.

## Worktree & project preferences

- Worktree directory: `.worktrees`
- Branch prefix: `rnathani/`
- Active projects: `~/.claude/projects/active/`
- Archived projects: `~/.claude/projects/archived/`
