# Code Writing Rules

## Read before editing

Read the actual file before proposing or making edits. Understand existing behavior; don't infer from names or grep alone.

## Backward compatibility

Refactors get a clean split: remove overhauled systems, don't shim them. New systems get regular names, never "New".

## File splitting

Split when a file crosses coherent boundaries: unrelated class/section, name mismatch, or a second conceptual domain. The no-new-files rule targets gratuitous utilities, not legitimate module splits.

## Scope discipline

- Add only what was asked: no drive-by features, refactors, or improvements.
- Don't touch docstrings, comments, or types on code you didn't change.
- Delete unused code completely: no shims, `_var` renames, or `# removed` comments.
- Three similar lines beat a one-off abstraction.

## Comments

- Code first. If a branch, type, helper, schema, or test can carry the rule, skip the comment.
- Comment only what code cannot express: unguarded invariants, business/security/compliance rules, non-local coupling, rationale for code that looks wrongly simple.
- Point of use. Put load-bearing comments next to the constrained code, never in a file-header rule list.
- Never paraphrase the next line or write generic AI docstrings. They rot and mislead the next agent.
- Stale comments are bugs. Update or delete in the same change.
- No storytelling. No changelog, no "X wrote this", no session narrative. Current state only. Punctuation: `~/.claude/rules/writing.md`.

## Defensive code

Every fallback, guard, retry, or branch must name its trigger: the concrete input or state that reaches it. Can't name it → don't write it. Validate at system boundaries; impossible-by-construction cases fail loudly (assert/raise), not handling branches. Never silently substitute a value: no default, zero, cached copy, or mock masking what failed. Crash instead. Handle real, reachable failures (I/O, external APIs, user input) once, where they occur.

High stakes invert nothing: stricter validation and louder failure, not more branches. Never add unrequested parallel modes (paper, dry-run, demo, mock, or safety scaffolding "just in case"). Those are features; the user asks or they don't exist.

## Performance & cost

Treat cost as part of correctness. Don't add work on a hot path (per request, tick, frame, or tight loop) unless you can name why it's cheap enough. No unbounded loops over I/O, queries, or allocations; bound them or batch. Prefer the simpler correct path over cleverness; measure before optimizing away from clarity. Don't introduce N+1 remote or disk calls, lock contention, or copies of large structures without a named reason.
