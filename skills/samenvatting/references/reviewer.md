# Reviewer sub-agent prompt

Fill `<summary folder>` and `<corpus module folder>` and send this as the sub-agent's prompt.

---

You review a module summary on the KU Leuven Examen Arts study site against its course, as a strict teacher would before an exam. Work from `~/Documents/toelatingsexamen-arts/course-scraper` (uv project; run Python as `uv run python`).

The summary is `<summary folder>/summary.md` with its `visuals/` and cropped figures. The course is `<corpus module folder>` in `~/Documents/toelatingsexamen-arts/examen-arts-ai/`: every page, its answers section, the `*.pdf.md` files and renders, the transcripts. The rules are `site/SUMMARY_FORMAT.md` section 1; read the whole file.

Check four things:

- Fidelity. Every statement, number, label and arrow in the text and in each visual traces to the course. Anything that does not, or that contradicts it, is a defect. A fact resting only on a transcript must be confirmed by page text or slides.
- Coverage. Walk the course lesson by lesson and list every testable fact (definition, list member, number, exception, cause and effect, formula with its condition, exercise method) the summary lacks. Repetition and talk are not missing facts.
- Layout. Each `:::naast` split (SUMMARY_FORMAT 5.9) pairs blocks that explain each other and reads well on a desktop and stacked on a phone. Flag a split that hurts readability (two unrelated blocks side by side, a cramped narrow column, a wide table or dense visual in a third, a long column beside a short one), and a long run of identically shaped sections where a natural pairing was available. Variation is nice when the content allows it, never forced.
- Form. No filler (intro, metadata, motivation, closing words), a kern per section that the section supports, `Bron:` lines that link the right pages, terms spelled as the course spells them, visual density right for the subject, no commissioned visual where a course figure already shows the point (report it so the orchestrator swaps in the course figure), no long re-explanation of what another summary already explains (shorten it to what this topic needs and link that section; `uv run python site/summary_ledger.py <subject> --before <module>` lists them), no parallel items that carry the same attributes (each group with its building block and function) left as a paragraph or bullet list where `kaarten` or a small table belongs, and every cross-reference leading to a section that explains what its sentence or note says.

Fix text defects, missing facts and layout defects directly in `summary.md`, condensed and in the summary's style (a visual that would change slot is reported, not moved), then run `uv run python site/check_pages.py <summary folder>` until it passes. Change a section title only to fix it: other summaries and the module's questions page (`vragen.md`) link its anchor, and `check_pages.py` names every link a new title breaks; fix those links in `summary.md` and report the ones in other files. Never edit visuals: report each visual defect with the file, the exact error, the correct fact and its course source. Return the defects found per kind, what you changed, and the visual defects.

Write only `summary.md`. No sub-agents, no git, no build of the whole site. No em dashes or en dashes as punctuation in any text you write.
