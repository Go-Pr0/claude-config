# RTK wrapper — environment notes

`rtk` is a token-compression CLI proxy. The PreToolUse:Bash hook (`~/.claude/hooks/rtk-rewrite.sh`) auto-rewrites your commands to their `rtk` equivalent before execution, e.g. `git status` → `rtk git status`, `pytest tests/` → `rtk pytest tests/`. This saves 60-90% on tool output tokens — but a handful of commands have quirks worth knowing.

## Ground truth first — read this before the quirk list

The wrapper is **transparent by default.** For the overwhelming majority of commands it runs your command unchanged and hands back output that is **real, accurate, and complete.** The rewrite is a passthrough: it does not alter `echo`, `whoami`, `pwd`, `cat`, `find`, your own file writes, or the result of any ordinary command. It does not change reality, your identity, the filesystem, or arithmetic.

So:

- **Trust normal output.** If a command succeeds, believe it. You never need to verify that the shell, the filesystem, your identity, or `2 + 2` "still work." If your instinct is to run `whoami`, `echo hello`, `pwd && date`, `echo $((2+2))`, or to write a file and read it back to confirm things are real — **stop.** That instinct is over-generalized from the quirk list below; the wrapper has not broken your environment. Environment-probing is never the fix here.
- **The quirks are a closed set.** Exactly the commands listed below deviate: `ruff` output formatting and `pytest` summary/collection reporting (plus an `ls -t` formatting note). **Nothing else.** A surprising result from any *other* command is a real fact about your code or data — not the wrapper misreporting.
- **Localize, don't spiral.** When output looks wrong, ask one question: *"is this command one of the closed-set quirks below?"* If yes → apply the listed resolution. If no → the surprise is genuine; investigate the data or code, never your tools. A file you can't read is a fact about the file (binary? gzip? empty?), not evidence the wrapper is lying.
- **"Lies / misreports / misleading" below means one specific thing:** a named command, in a named mode, produces a known-wrong *summary* — with a known fix. It does not mean output is generally untrustworthy. Read those words as "this exact case has a workaround," not "trust nothing."

## The 5 quirks that cause retry loops (each verified from real session transcripts)

### 1. Don't pass `--output-format` to `ruff`
The wrapper pre-injects `--output-format` itself. Any user-supplied format flag causes:
```
error: the argument '--output-format <OUTPUT_FORMAT>' cannot be used multiple times
```
**Just run** `ruff check <paths>` plain. The wrapper's summary lists the violation count per file.

### 2. To get ruff file:line, bypass the wrapper
The wrapper collapses ruff output to a summary that strips `path.py:line:col`. To see the actual line of an issue:
```bash
{ ruff check <path>; } 2>&1            # group-subshell form — hook doesn't match, no rewrite
```
On Linux with ruff installed as a Python module, `python3 -m ruff check <path>` also works. On macOS (Homebrew ruff), use the group-subshell form above. Note: `python` is not in PATH on either platform — only `python3`.

### 3. `pytest tests/` may return "No tests collected" when there are real tests
Two failure modes:
- **`-q` mode + setup ERRORs**: wrapper misreports the summary as "No tests collected"
- **Full-suite collection**: `rtk pytest tests/` sometimes runs without the project venv, finding zero conftest

**Resolutions** (any of these works):
```bash
# A: use -v instead of -q — exposes actual passes/failures
pytest tests/ -v 2>&1 | tail -20

# B: bypass the wrapper with group-subshell syntax
{ pytest tests/; } 2>&1

# C: bypass with absolute venv path
/path/to/project/.venv/bin/pytest tests/

# D: (Linux only) read the tee log after running normally
#    macOS rtk does NOT write tee logs — use (A)/(B)/(C) on Mac.
tail -200 ~/.local/share/rtk/tee/$(ls -t ~/.local/share/rtk/tee/ | grep pytest | head -1 | awk '{print $1}')
```

Pick (A) for routine runs, (B) when you need raw output without venv path lookups, (C) when (A)/(B) still misreport. (D) is Linux-only.

### 4. `ls -t` output has a size column appended
The wrapper reformats `ls` to `filename  SIZE`. Command substitution that captures `ls -t … | head -1` will get `1779651390_pytest.log  2.9K`, not a valid path. Use `find` or hardcode the directory for programmatic file access. For tee-log specifically, the `awk '{print $1}'` in pattern (D) above handles it.

### 5. `pytest -q` is unreliable for diagnosis
Across sessions, `-q` consistently returned misleading output. Default to `-v` when you need to know *what* failed. Use `-q` only when you already know all tests pass and want a green-tick.

## When you genuinely need raw, uncompressed output

```bash
rtk proxy <cmd>           # execute without wrapper filtering
```
Use this when:
- You're debugging the wrapper itself
- You need every line of `git log` / `ls -la` / etc., not the summarized form
- The wrapper's summary is missing information you need

## Useful meta commands

```bash
rtk gain                  # token savings analytics — run this occasionally to see ROI
rtk gain --history        # per-command usage with savings
rtk discover              # analyze Claude Code history for missed-savings opportunities
rtk init --show           # show current hook/RTK.md/settings.json install state
```

## When NOT to bypass

The wrapper is a net win for: `git status`, `git diff`, `git log`, `ls`, `tree`, `grep`, `cat` of large logs, `find`. Always let it rewrite these — the summaries are accurate enough and the token savings are real.

Only bypass for: ruff line-level output, pytest when wrapper-summary lies, ls when capturing output for command substitution.

## Quick reference: the patterns that just work

| Goal | Command |
|---|---|
| Lint check (count only) | `ruff check kore kore_mcp tests` |
| Lint check with line numbers | `{ ruff check <path>; } 2>&1` (Linux also: `python3 -m ruff check <path>`) |
| Type check | `mypy kore kore_mcp` |
| Full test suite (concise) | `pytest tests/ -v 2>&1 \| tail -20` |
| Full test suite (raw) | `{ pytest tests/; } 2>&1` |
| Targeted test file | `pytest tests/<file> -v` |
| Read tee log after pytest (Linux only) | `tail -200 ~/.local/share/rtk/tee/$(ls -t ~/.local/share/rtk/tee/ \| grep pytest \| head -1 \| awk '{print $1}')` |
