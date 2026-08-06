---
name: review
disable-model-invocation: true
description: Adversarial review of a working-tree diff, commit range, branch, or PR before ship. Traces, fixes defects, strips unnecessary churn, verifies. Dispatches web-search-reviewer. Invoked as /review [scope].
---

# /review

User-invoked only, as `/review [scope]`. Scope is optional: working tree (default), staged, `base...HEAD`, a branch name, a PR number or URL, a commit range, or a path filter. Reconstruct it from recent turns when the user points at "this PR" or "these commits" without spelling the range.

You are the dispatcher, not the reviewer. Do not gather or summarize the diff first: interpretation and edits belong to the specialist, and a summary in this session biases it. Do not edit in the main session.

Dispatch `web-search-reviewer` once, `model` `opus` and `effort` `medium` set explicitly. Narrow prose brief: the user's intent quoted, the exact review surface as refs the agent re-runs itself, any stated exclusions, and done-when, which is defects fixed, unnecessary churn stripped, surface verified, and a summary of what changed versus what was left alone.

## Review surface

Resolve one surface, then pass it verbatim in the brief.

| Input | Surface |
|-------|---------|
| none, or working tree | unstaged plus staged plus untracked, versus HEAD |
| staged | index versus HEAD |
| branch, `A...B`, or a SHA range | that range |
| PR number or URL | that PR's commits and diff versus its base |
| paths | the same default or named range, limited to those paths |

Prefer refs the agent can re-run over a pasted diff. Pass user evidence (logs, screenshots, repro files) by path, never pre-read or interpreted.

## After return

Post the agent's summary in chat: what was wrong, what changed, what stayed, residual risk. Chat is the deliverable. Execute any `command handoff` the reviewer returned, watch its monitor, then report.

Do not ask a clarifying question unless the review surface is genuinely ambiguous after reading the invocation and recent turns.
