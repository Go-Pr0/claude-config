# RTK

`rtk` compresses Bash output: `~/.claude/hooks/rtk-rewrite.sh` rewrites known commands before they run. A summary can drop lines, so a count, a liveness check or anything a decision rests on reads the raw command.

- Never rewritten: `grep`, `rg`, `ps`, `wc`, `diff`, by `exclude_commands = ["ps", "wc", "diff", "grep", "rg"]` under `[hooks]` in the `config.toml` that `rtk config` names. Without that line `grep` and `rg` clip their lines and group them as `[file] N (1):`, a basic regex holding `(` prints a parse error and `0 matches`, `ps` cuts to 30 lines before any pipe, `wc -l < file` prints 0, and `diff` prints `Files are identical` on a whitespace-only difference.
- Raw anywhere else: an absolute path (`/usr/bin/find`) is never rewritten, inside `$(...)` included. Inside `D=$(...)` write bare `grep`: `command grep` and `command rg` become `command rtk grep` there.
- `find`: ignores flags it does not know and truncates its list.
- `ls` appends a size column: never parse it.
- `ruff` injects `--output-format` and strips `path:line`; `pytest -q` can report no tests. Bypass with a group: `{ ruff check <path>; } 2>&1`, `{ pytest tests/; } 2>&1`.

`rtk gain` shows savings, `rtk init --show` the install state.
