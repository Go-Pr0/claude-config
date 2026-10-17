---
name: samenvatting
description: Writes the study site's summary ("Samenvatting") of one or more course modules and its questions page ("Vragen", inzichtsvragen and mock exam questions), with the session as orchestrator and sub-agents for the exam lens, the visuals, an independent fidelity review, the questions and their check against the course and the sealed real exams. With `vragen <subject> <module>` it writes only the exam lens and the questions page of an existing summary; `parallel <subject> <module>` is one of several concurrent sessions and stops before the build, which `publiceer` runs once for all. Invoked by the user with the module(s) to summarise.
disable-model-invocation: true
argument-hint: <subject> <module or wiskunde chapter> [, more modules] | vragen <subject> <module> [, more modules] | parallel <subject> <module> | publiceer
---

# Samenvatting

The session that runs this skill is the orchestrator. It reads a module, has a sub-agent write the module's exam lens, writes the summary itself, commissions one visual sub-agent per visual it wants (all in parallel), has a fresh sub-agent review the result against the course, has a question sub-agent write the questions page and a check sub-agent check it, then checks, builds and publishes. Work from `~/Documents/toelatingsexamen-arts/course-scraper` (uv project; run Python as `uv run python`).

## Contracts

| File | Owns |
|------|------|
| `site/SUMMARY_FORMAT.md` | content rules (section 1), where a summary lives, every block, cross-references (5.8), what the build rejects |
| `site/QUESTIONS_FORMAT.md` | the questions page: content rules, its blocks, what the build rejects, what never reaches the site |
| `site/EXAM_PROFILE.md` | the real exam in the abstract, per subject: format, options, scoring, question shapes, distractors, topic frequency |
| `site/examenlens/<subject>/<module>.md` | a module's exam lens (for wiskunde `<subject>/<part>/<chapter>.md`), written by the exam-lens sub-agent |
| `site/summary_ledger.py` | what the existing summaries explain: per section its title, reference, kern and key terms |
| `site/VISUAL_SPEC.md` | the visual contract, the brief a visual sub-agent gets (section 6), the validator |
| `site/CONTENT_FORMAT.md` sections 4 to 6 | Markdown, math, `\ce{}`, internal links, questions, theory blocks |
| `site/content/biologie/02-module-1-de-cel/00-samenvatting/` | the worked example; `site/content/_gallery/` shows every component and a questions page |
| `references/examenlens.md` | the prompt for the exam-lens sub-agent |
| `references/visual-agent.md` | the prompt for each visual sub-agent |
| `references/reviewer.md` | the prompt for the fidelity reviewer |
| `references/vraagsteller.md` | the prompt for the question sub-agent |
| `references/vragencontrole.md` | the prompt for the question check sub-agent |
| `site/deploy/DEPLOY.md` | publishing to the live site |

Read both format files in full before writing a line, then the worked example next to its course pages.

## Scope

The argument names modules: a subject plus a module name or number (`biologie 6`, `fysica kinematica`, `wiskunde 8 reele functies`). A summary covers one module, for wiskunde one chapter (subject > part > chapter). Resolve each to its folder in `site/content/` and its twin in `~/Documents/toelatingsexamen-arts/examen-arts-ai/`; pick the closest title match and state it. Several modules run one after the other in course order, each through every phase below, so a later one can link to an earlier one of the same run. An existing `00-samenvatting` is rewritten only when the user asked for it.

`vragen <subject> <module>` (several modules comma separated) runs only the questions for a module whose summary exists: phase 2 (read the module and its summary), 4 (exam lens), 11 and 12 (questions and their check), then 13 to 15 for that summary folder. It stops for a module without `summary.md`. An existing `vragen.md` is replaced only when the user asked for it.

`parallel <subject> <module>` is one of several sessions running this skill at once, each on its own module. It runs phases 1 to 13 for that module and stops; `publiceer` later runs 14 and 15 once for all of them. In parallel mode:
- Never run `build.py` into the shared site folder, `check.py`, `export_ai.py`, `check_ai.py`, `serve.py` or the deploy. To look at the page, build into your own temporary folder (`uv run python site/build.py --out <tmp dir>`) and open the file there.
- Never edit another module's folder or lens. When a build or check fails on another module's files, wait a few minutes and retry.
- Link only to a summary whose folder already holds `vragen.md` (a finished run); another session may still be writing the others.
- Done when phase 13 passes; report the summary folder, the visuals made, what was cut and why, and any ambiguity.

`publiceer` runs phases 14 and 15 once, after every parallel session is done: check that each new summary folder passes phase 13, then build, check, export and publish the whole site, and list the live links.

## Phases

1. Inventory the module's course figures: every image in the pages' `.files/` folders, every slide or PDF page render, with what each shows and which lesson it belongs to. Include the module's overview, schema and table-of-contents pages, which belong to no lesson; an overview picture there is the first candidate figure for the module's opening section. Look at each one.
2. Read the module from the corpus: `INDEX.md` of the module folder, every page in course order including its `## Antwoorden en uitleg`, the `*.pdf.md` files (open the page renders where slides carry the content), and the transcripts. Transcripts are speech recognition: a fact found only there is checked against slides or page text, and left out when it conflicts or cannot be confirmed. Note per lesson what a test could ask.
3. Run the ledger for the module's own subject only: `uv run python site/summary_ledger.py <subject> --before <module>`. Never cross-reference or deduplicate against another subject's summaries. Note per planned topic what an existing summary already explains and the reference to its section.
4. Exam lens. When both `~/Documents/toelatingsexamen-arts/toelatingsexamen-archief/index.json` and `site/EXAM_PROFILE.md` exist (check with `test -f`; never list or open the archive), start one general-purpose sub-agent with `references/examenlens.md`, filled with the module and its lens path `site/examenlens/<subject>/<module>.md`. It writes the lens and reports only that it did. Read the lens and `site/EXAM_PROFILE.md`. When either file is missing, skip the phase, say so in the run's report, and plan from the course alone. An existing lens is rewritten only when `index.json` or the profile is newer than it (`test -nt`).
5. Plan sections in course order, and per section what becomes prose, `vergelijk`, `stappen`, `kaarten`, a course figure (whole or cropped), or a commissioned visual. Use the lens for emphasis: the reasoning the exam asks most gets a worked example or `stappen`, a trap it sets goes into the section's kern or a `letop`, a picture goes where the exam reads one. The lens never drops a course fact and never adds one the course does not give. An existing summary's `:::aanvulling` blocks (SUMMARY_FORMAT 5.10) carry over into a rewrite, and the fidelity review leaves them out of its comparison with the course. Course figures from the inventory come first (SUMMARY_FORMAT section 1); commission a visual only where none of them does the job, within the subject's visual density. Fix the legend first: every visual reuses its tones and symbols. Then decide each section's layout from its content (SUMMARY_FORMAT 5.9): the full column, or a `:::naast` split where two blocks explain each other (text beside the figure it explains, a numbered list beside a small table, two parallel cases, a widget beside its explanation), with the ratio the content needs (1/1, 3/2 or 2/3, 2/1 or 1/2). Variation is nice when the content allows it, never forced: no split for decoration or to make a section look different, never a wide table or a dense visual in a narrow column, and most blocks keep the full column. A visual planned for a column gets the size that fits its slot (VISUAL_SPEC section 4).
6. Write `summary.md`: legend, sections with `Bron:` lines and kerns, the splits of phase 5 (count the colons from the inside out, SUMMARY_FORMAT section 3), a `:::visual <name>` at each commissioned spot, then test, flashcards and cheat sheet. Where an existing summary already explains a concept, link its section (SUMMARY_FORMAT section 1 and 5.8) instead of explaining it again, and restate in a sentence what the new topic needs to stand on its own; judge per concept, and explain again in full what this module develops further. Build the test from the module's own exercises and answer keys where they exist. Crop figures with `site/crop.py`.
7. Write one brief per commissioned visual to `visuals/<name>.brief.md` (VISUAL_SPEC section 6). Every label and fact in a brief carries its course source, the brief names the course figures checked and why none does the job, and it names the visual's slot: the full column, or which column of which split and what stands beside it. A brief the course cannot back is cut, not guessed.
8. Commission the visuals: one general-purpose sub-agent per brief, all started in a single message so they run in parallel, each with the prompt in `references/visual-agent.md` filled with its brief path. Never one agent for several visuals.
9. Integrate. Read every report and look at every visual's shots against its brief and the course, and at the summary page in a browser at desktop and phone width: each split reads well and each visual works in its slot. A wrong label, arrow or proportion goes back to the same sub-agent through `SendMessage` with the exact correction; repeat until right. A visual that cannot be made right is removed with its `:::visual` line.
10. Review. Start one fresh sub-agent with `references/reviewer.md`. It edits `summary.md` for text defects and returns visual defects, which go back to their visual sub-agent. Apply its coverage findings: a testable fact it reports missing is added.
11. Questions. When `site/EXAM_PROFILE.md` exists, start one general-purpose sub-agent with `references/vraagsteller.md`, filled with the summary folder, the corpus module folder and the lens path (or none). It writes `vragen.md` (QUESTIONS_FORMAT.md) from the finished summary, the course, the profile and the lens, never the archive. Read its report and the page. Without the profile, skip phases 11 and 12 and say so in the run's report.
12. Check the questions. Start one general-purpose sub-agent with `references/vragencontrole.md`. It answers every exam question blind before reading its key, checks every answer against the course, and compares every question with the real exams, naming only the generated question and the kind of overlap. Send its findings to the question sub-agent through `SendMessage`, then the revised page to the check sub-agent through `SendMessage`; repeat until the check reports every kind clean. A question that cannot be made right and distinct is removed. Without the archive, the check runs 1 and 2 and the run's report says the overlap was not checked.
13. Check the summary folder until all pass: `uv run python site/check_visuals.py <summary folder>` and `uv run python site/check_pages.py <summary folder>` (the summary and its questions page).
14. Build and verify the whole site and corpus, with no sub-agent still writing: `uv run python site/build.py`, `uv run python site/check.py`, `uv run python site/export_ai.py`, `uv run python site/check_ai.py`. All four end clean.
15. Publish with the sync in `site/deploy/DEPLOY.md`, then open the live summary at `https://examenarts.traedx.io/<subject>/<module>/00-samenvatting/` and its questions at `.../00-samenvatting/vragen/` to confirm they serve.

Done when every named module's summary and questions page pass phase 13 and 14, are live, and the user has their links, the visuals made, what was cut from briefs and questions and why, whether the lens and the overlap check ran, and any fact the course leaves ambiguous.

## Boundaries

- Never edit course pages (`page.md`, `section.md`), `~/Documents/toelatingsexamen-arts/course-materials/`, `ximera-staging/` or the corpus by hand. A summary condenses the course; it never corrects it.
- Never write a visual yourself while sub-agents exist for it, and never let a sub-agent write outside its own `visuals/<name>.*` files. The question sub-agent writes only `vragen.md`, the exam-lens sub-agent only its lens.
- Never run `build.py`, `check.py` or `export_ai.py` while a sub-agent is writing.
- Never publish a summary or questions page whose checks fail.
- The real exams in `~/Documents/toelatingsexamen-arts/toelatingsexamen-archief/` are sealed: the student sits them later. Only the exam-lens and the question check sub-agents read them. The orchestrator never opens, lists or searches the archive, never passes its content to another agent, and never shows it to the user; no report, lens, summary, question or commit quotes, paraphrases or describes a real question. The lens is abstract working material: it stays in `site/examenlens/`, which the build and the export never read, and its content goes into no report to the user.
