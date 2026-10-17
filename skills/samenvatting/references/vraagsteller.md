# Question sub-agent prompt

Fill `<summary folder>`, `<corpus module folder>` and `<lens path>` (or "none: no lens for this module") and send this as the sub-agent's prompt.

---

You write the questions page ("Vragen") of one module of the KU Leuven Examen Arts study site, beside its summary. Work from `~/Documents/toelatingsexamen-arts/course-scraper` (uv project; run Python as `uv run python`).

Read, in this order: `site/QUESTIONS_FORMAT.md` in full (the contract), `<summary folder>/summary.md` (the finished summary; its section anchors are what you link), the course `<corpus module folder>` in `~/Documents/toelatingsexamen-arts/examen-arts-ai/` (every page, its answers section, the `*.pdf.md` files and the transcripts), `site/EXAM_PROFILE.md` (how the exam poses questions in this subject: format, options per question, scoring, shapes, distractor patterns) and the module's exam lens `<lens path>` (which concepts the exam tests and how often, the reasoning it asks, its traps). Look at `site/content/_gallery/vragen.md` for a complete page. Never open `~/Documents/toelatingsexamen-arts/toelatingsexamen-archief/`: the real exams stay sealed, and the profile and the lens are all you know of them.

Write `<summary folder>/vragen.md`:

- Inzichtsvragen, roughly 8 to 15: deep, open questions that make the student link the module's content and understand how things work. Each connects two or more sections, predicts the effect of a change, or explains a mechanism; none asks back a line of the summary. Each answer is a short paragraph, grounded in the course, with chips to the summary sections it rests on.
- Examenvragen, roughly 10 to 20, at the exam's level and in its form as the profile describes it, spread over the module by the lens's frequencies (by the course's weight when there is no lens), at the depth of reasoning the lens names. Take topics, difficulty and misconceptions from the lens, never a template: build each question's scenario and option set yourself from the course's own material (its exercises, examples, figures, experiments), and vary the form over the page, so no two questions on one concept share a build. The most tested concepts are where a generic exam template is most likely to match a real question; give those the most original angles. Most are multiple choice with the profile's number of options; where the profile or the content suits an open answer (a short calculation, a reasoning step), write it open with a model answer. Build distractors on real misconceptions, the lens's traps first. Every multiple choice answer names the key and goes through every option: why the key is right, why each other option is wrong.
- Every fact in a question, option or answer traces to the course (pages over transcripts; a fact only in a transcript is confirmed in page text or slides or left out). Scenarios and numbers may be new; the science they rest on is the course's. Use the course's terms and spelling. Where the course leaves an answer open, cut the question.
- Never reproduce or imitate a real exam question you may know of: new scenarios, new data, new answer structures.
- Nothing on the page is answered on screen: options as plain text in `:::opties`, the key in `:::antwoord`, never the course pages' `- [ ]` boxes, `[keuze: ...]` or `\answer`.

Run `uv run python site/check_pages.py <summary folder>` until both the summary and its questions page pass. Return the count per part, how the examenvragen spread over the summary's sections, the questions you cut because the course does not settle them, and anything in the profile or lens you could not follow.

The orchestrator will send you a check's findings through `SendMessage`: fix each one (rewrite or replace a question flagged as too close to a real exam with a new scenario and structure, not a reworded one), run `check_pages.py` again and report what you changed per finding.

Write only `<summary folder>/vragen.md`. No sub-agents, no git, no build of the whole site. No em dashes or en dashes as punctuation in any text you write.
