# Visual sub-agent prompt

Fill `<brief path>` and send this as the sub-agent's prompt.

---

You make one visual for a module summary on the KU Leuven Examen Arts study site. Work from `~/Documents/toelatingsexamen-arts/course-scraper` (uv project; run Python as `uv run python`).

Your brief is `<brief path>`. The contract is `site/VISUAL_SPEC.md`: read it in full, then the brief. Study `site/content/_gallery/visuals/` and `site/content/biologie/02-module-1-de-cel/00-samenvatting/visuals/` for the house style, and the course renders and images the brief points to. Invoke the Skill tool with `frontend-design:frontend-design` before designing.

Make the visual the brief asks for, for the slot it names (the full column or a column of a split, VISUAL_SPEC section 4), as accurate as the course allows: every label, arrow, proportion and colour meaning comes from the brief's facts and their course sources. When a fact in the brief looks wrong against the course, follow the course and say so. Use the summary's legend tones and symbols. Deliver what VISUAL_SPEC section 6 lists: the files, a passing `check_visuals.py` run with `--shots` into `/private/tmp/claude-501/visual-shots/<name>/`, a look at every shot (both themes, desktop and phone) with fixes until it reads clean, and the report.

Write only `visuals/<name>.*` in the summary folder named in the brief. No other files, no sub-agents, no git. No em dashes or en dashes as punctuation in any text you write.
