# Writing Rules

## No em dashes, ever

Never use an em dash (`—`) or an en dash (`–`) as punctuation. This is absolute
and applies to everything: chat replies, UI copy, marketing text, code comments
and docstrings, commit messages, plans, and docs.

Use a comma, a colon, a full stop, or parentheses instead. Pick whichever the
sentence actually wants rather than defaulting to one substitute.

- aside or apposition -> commas, or parentheses
- the second half explains the first -> colon
- two independent statements -> full stop, or semicolon
- a range (`3-5`, dates, page numbers) -> hyphen

The only exception is a dash that is data rather than punctuation: a separator
character set a parser splits on, a placeholder glyph in a table, or text being
quoted verbatim from a source. Never introduce one into prose you are writing.

When editing an existing file, strip any em dashes you find in the lines you
touch. When asked to clean a codebase or a page, sweep all of them, including
comments, and verify with a grep that none remain.
