---
name: devflow-code-review
description: Structured code review checklist for diffs, branches, or specified files. Use during /devflow-review and as the self-review step in standard/deep tasks before finishing.
---

# Code Review

Review against the user's stated intent. Don't invent requirements. Don't rewrite working code.

## Checklist

For each finding output `file:line — problem — suggested fix`.

**Optional impact pre-pass:** if a graphify graph is available (`graphify` CLI +
`graphify-out/graph.json`), run `graphify affected "<changed-symbol>"` for the
key symbols in the diff to surface downstream consumers worth checking. Treat
hits as unverified hints; fall back to Grep on empty/ambiguous/error results.
Never read `graph.json` raw. Skip entirely if graphify is absent.

### Requirement match
- Does the diff implement what was asked?
- Anything missing from the spec/plan/task description?
- Anything added that wasn't asked for?

### Correctness
- Off-by-one, null/undefined, async ordering, error swallowing
- Boundary conditions for inputs
- Return types match callers' expectations

### Edge cases
- Empty input, single item, very large input
- Concurrent access, retry, timeout
- Failure modes of external calls

### Security
- Input validation at trust boundary
- Auth/authorization checks present where mutating
- Secrets not logged, not committed
- SQL/command/template injection vectors
- PII handling

### Performance
- N+1 queries
- Allocation in hot loops
- Sync work in event loops
- Indices on new queries / migrations

### Tests
- New behavior has tests
- Tests assert behavior, not implementation
- Test names describe intent

### Readability / maintainability
- Names match domain
- Function size and depth reasonable
- No dead code

### Unnecessary complexity
- Premature abstraction
- Speculative generality
- Flags/branches with no current consumer

### Hygiene
- Unrelated changes accidentally included
- Formatting drift
- Imports/dependencies added but unused

## Output

End with: **approve** | **approve-with-fixes** | **request-changes** + one-sentence reason.

Skip categories with nothing to flag. Don't pad.
