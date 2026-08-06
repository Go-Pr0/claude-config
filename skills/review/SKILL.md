---
name: review
disable-model-invocation: true
description: Adversarial review of a working-tree diff, commit range, branch, or PR before ship — trace, fix defects, strip unnecessary churn, verify. Dispatches web-search-reviewer. Invoked as /review [scope].
---

# /review

User-invoked only. Invoked as `/review [scope]`. Scope is optional: working tree (default), staged, `base...HEAD`, branch name, PR number/URL, commit range, or path filter. Reconstruct from recent turns when the user points at this PR or these commits without spelling the range.

You are the dispatcher, not the reviewer. Do not gather or summarize the diff first — interpretation and edits belong to the specialist. Do not edit in the main session. Dispatch `web-search-reviewer` once with `model` `opus` and `effort` `medium` set explicitly. Narrow prose brief only: user intent quoted, exact review surface (git/gh refs or commands the agent re-runs itself), any stated exclusions, done-when = defects fixed, unnecessary churn stripped, surface verified, summary of what changed vs left alone.

## Review surface

Resolve one surface, then pass it verbatim in the brief:

| Input | Surface |
|-------|---------|
| (none) / working tree | unstaged + staged + untracked vs HEAD |
| staged | index vs HEAD |
| branch / `A...B` / SHA range | that range |
| PR number or URL | that PR's commits / diff vs its base |
| paths | same default or named range, limited to those paths |

Prefer refs the agent can re-run over pasted diffs. Pass user evidence (logs, screenshots, repro files) by path — never pre-read or interpret them in this session.

## After return

Post the agent's summary in chat — what was wrong, what changed, what stayed, residual risk. Chat is the deliverable per `~/.claude/rules/artifacts.md`. Do not write a review markdown file unless the user asks for a file. Execute any `command handoff` the reviewer returned (run + monitor), then report.

## Boundaries

Do not pass `/orchestrator` or `/research` to the reviewer.
Do not assign long-running gates to the reviewer — those stay in this session via `command handoff`.
Do not ask clarifying questions unless the review surface is genuinely ambiguous after reading the invocation and recent turns.
