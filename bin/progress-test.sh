#!/bin/sh
# Tests ./progress on temp dirs only. Windows and failures are reached without test hooks in the
# script: shims on PATH (cksum, sleep, cat) act at the moment each call happens.
set -u
LC_ALL=C
export LC_ALL

HERE=$(cd "$(dirname "$0")" && pwd)
PROGRESS=$HERE/progress
ROOT=$(mktemp -d "${TMPDIR:-/tmp}/progress-test.XXXXXX") || exit 1
trap 'rm -rf "$ROOT"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

PASSED=0
FAILED=0
SKIPPED=
N=0
T=
RC=0
OUT=$ROOT/out
ERR=$ROOT/err

REAL_CKSUM=$(command -v cksum)
REAL_CAT=$(command -v cat)
REAL_RM=$(command -v rm)
export REAL_CKSUM REAL_CAT REAL_RM

SHIMS=$ROOT/shims
mkdir "$SHIMS" "$SHIMS/hook" "$SHIMS/nosleep" "$SHIMS/swap" "$SHIMS/killbreaker"
# Runs a scenario's hook before each cksum; a failing hook makes this cksum lie.
cat > "$SHIMS/hook/cksum" <<'EOF'
#!/bin/sh
if ! sh "$PROGRESS_TEST_HOOK" </dev/null >/dev/null 2>&1; then
  "$REAL_CAT" >/dev/null
  echo '0 0'
  exit 0
fi
exec "$REAL_CKSUM"
EOF
printf '#!/bin/sh\nexit 0\n' > "$SHIMS/nosleep/sleep"
# The first read of a lock's pid returns the dead pid, then a new holder has the lock: the state
# of a waiter who read the pid just before another waiter broke the lock and took it.
cat > "$SHIMS/swap/cat" <<'EOF'
#!/bin/sh
case ${1:-} in
  *.progress.lock/pid)
    if [ ! -e "$PROGRESS_TEST_SWAP_FLAG" ]; then
      "$REAL_CAT" "$1"
      : > "$PROGRESS_TEST_SWAP_FLAG"
      printf '%s\n' "$PROGRESS_TEST_LIVE_PID" > "$1"
      exit 0
    fi
    ;;
esac
exec "$REAL_CAT" "$@"
EOF
# A signal reaches the script while it removes a dead lock under the breaker's directory.
cat > "$SHIMS/killbreaker/rm" <<'EOF'
#!/bin/sh
case $* in
  *.progress.lock) kill -TERM "$PPID" ;;
esac
exec "$REAL_RM" "$@"
EOF
chmod +x "$SHIMS"/*/*

pass() { PASSED=$((PASSED + 1)); }
fail() {
  FAILED=$((FAILED + 1))
  printf 'FAIL: %s\n' "$*"
}

fresh() {
  N=$((N + 1))
  T=$ROOT/$N
  mkdir "$T"
}

run() {
  "$@" > "$OUT" 2> "$ERR"
  RC=$?
}
p() { run "$PROGRESS" "$@"; }
p_hooked() { run env PATH="$SHIMS/hook:$PATH" PROGRESS_TEST_HOOK="$T/hook" "$PROGRESS" "$@"; }
p_nosleep() { run env PATH="$SHIMS/nosleep:$PATH" "$PROGRESS" "$@"; }

# Exit code, with no stderr on success and exactly one line on a failure.
rc_is() {
  if [ "$RC" -ne "$2" ]; then
    fail "$1: exit $RC, wanted $2: $("$REAL_CAT" "$ERR")"
    return
  fi
  lines=$(($(wc -l < "$ERR")))
  if [ "$2" -eq 0 ] && [ "$lines" -ne 0 ]; then
    fail "$1: stderr on success: $("$REAL_CAT" "$ERR")"
  elif [ "$2" -ne 0 ] && [ "$lines" -ne 1 ]; then
    fail "$1: $lines stderr lines: $("$REAL_CAT" "$ERR")"
  else
    pass
  fi
}
eq() {
  if [ "$2" = "$3" ]; then pass; else fail "$1: got [$3], wanted [$2]"; fi
}
same() {
  if cmp -s "$2" "$3"; then pass; else fail "$1: $2 differs from $3"; fi
}
has() {
  if grep -qF -- "$3" "$2"; then pass; else fail "$1: $2 lacks [$3]"; fi
}
lacks() {
  if grep -qF -- "$3" "$2"; then fail "$1: $2 holds [$3]"; else pass; fi
}
holds_n() {
  got=$(grep -cF -- "$3" "$2")
  eq "$1: count of [$3] in ${2##*/}" "$4" "$got"
}
absent() {
  if [ -e "$2" ]; then fail "$1: $2 exists"; else pass; fi
}
# No lock, aside or temp file of the script's left in the scenario's directory.
clean() {
  left=$(ls -A "$T" | grep '^\.progress' || true)
  eq "$1: leftovers" "" "$left"
}
bytes() { printf '%s' $(wc -c < "$1"); }
mode() { ls -l "$1" | cut -c1-10; }
dead_pid() { sh -c 'echo $$'; }

# Two levels and a preamble, the shape most documents have.
doc() {
  printf '%s\n' '# Title' 'intro' '' '## One' 'body one' '' '### One sub' 'sub body' '' \
    '## Two' 'body two' '' '### Two sub' 'more' > "$1"
}

# ---- argument checks and usage

fresh
p; rc_is 'no verb' 2
p bogus; rc_is 'bad verb' 2
has 'bad verb names usage' "$ERR" 'usage:'
p add "$T"; rc_is 'add short' 2
p add "$T" bogus text; rc_is 'bad kind' 2
p add "$T/none" open text; rc_is 'add no dir' 2
p add "$T" open ''; rc_is 'empty text' 2
p add "$T" open 'two
lines'; rc_is 'multi-line text' 2
p add "$T" open "$(printf 'carriage\rreturn')"; rc_is 'carriage return' 2
p add "$T" open '# heading'; rc_is 'leading hash' 2
p add "$T" open "$(awk 'BEGIN { for (i = 0; i < 301; i++) printf "x" }')"
rc_is '301 bytes' 2
has '301 bytes says why' "$ERR" 'the entry file holds detail, this line the outcome'
absent 'refused add writes nothing' "$T/progress.md"
p add "$T" open "$(awk 'BEGIN { for (i = 0; i < 300; i++) printf "x" }')"
rc_is '300 bytes' 0
p move "$T/none.md" 'x'; rc_is 'move no file' 2
p move "$T/progress.md"; rc_is 'move no heading' 2
p move "$T/progress.md" ''; rc_is 'move empty heading' 2
p show "$T/none"; rc_is 'show no file' 2
p show; rc_is 'show no arg' 2
p list "$T/none.md"; rc_is 'list no file' 2
p list; rc_is 'list no arg' 2
if [ -x "$PROGRESS" ]; then pass; else fail 'script is not executable'; fi

fresh
doc "$T/real.md"
"$REAL_CAT" "$T/real.md" > "$T/orig"
ln -s "$T/real.md" "$T/link.md"
p move "$T/link.md" 'One sub'; rc_is 'move symlink' 2
same 'symlink target unchanged' "$T/orig" "$T/real.md"
if [ -L "$T/link.md" ]; then pass; else fail 'link was replaced'; fi
fresh
printf '## Binding\n## Open\n## Landed\n' > "$T/real.md"
ln -s "$T/real.md" "$T/progress.md"
p add "$T" open 'x'; rc_is 'add onto symlink' 2
fresh
doc "$T/archive.md"
p move "$T/archive.md" '## One'; rc_is 'move out of the archive' 2
fresh
doc "$T/plan.md"
ln "$T/plan.md" "$T/archive.md"
"$REAL_CAT" "$T/plan.md" > "$T/orig"
p move "$T/plan.md" '## One'; rc_is 'another name of the archive' 2
same 'another name of the archive unchanged' "$T/orig" "$T/plan.md"

# ---- add, show

fresh
p add "$T" landed 'Wave 1: done'
rc_is 'add to absent file' 0
eq 'add prints size only' "landed: 46 bytes" "$("$REAL_CAT" "$OUT")"
p add "$T" binding 'Rule A'; rc_is 'add binding' 0
p add "$T" open 'Item A'; rc_is 'add open' 0
p add "$T" binding 'Rule B'; rc_is 'add binding again' 0
p add "$T" landed 'Wave 2: done'; rc_is 'add landed again' 0
mkdir -p "$T/cfg/projects/x"
printf '{"type":"assistant","message":{"usage":{"input_tokens":400000}}}\n' > "$T/cfg/projects/x/s.jsonl"
run env CLAUDE_CONFIG_DIR="$T/cfg" CLAUDE_CODE_SESSION_ID=s "$PROGRESS" add "$T" landed 'Wave 3: done'
rc_is 'add with a session transcript' 0
lacks 'add says nothing about context' "$OUT" 'context'
rm -rf "$T/cfg"
p move "$T/progress.md" 'Wave 3: done'; rc_is 'its line moves' 0
rm -f "$T/archive.md"
p show "$T"
rc_is 'show' 0
printf '%s\n' '## Binding' '### Rule A' '### Rule B' '## Open' '### Item A' '## Landed' \
  '### Wave 1: done' '### Wave 2: done' > "$T/want"
same 'sections keep order, blocks append' "$OUT" "$T/want"
same 'show prints the file' "$OUT" "$T/progress.md"
p add "$T" binding 'Rule A'; rc_is 'duplicate' 3
same 'duplicate leaves the file' "$T/want" "$T/progress.md"
p add "$T" binding "Odd \\n %s \"quote\" & back\\slash"; rc_is 'escapes in text' 0
has 'text kept literally' "$T/progress.md" "### Odd \\n %s \"quote\" & back\\slash"
clean 'add'

fresh
: > "$T/progress.md"
p add "$T" open 'First'; rc_is 'add to empty file' 0
printf '%s\n' '## Binding' '## Open' '### First' '## Landed' > "$T/want"
same 'empty file gets sections' "$T/want" "$T/progress.md"

fresh
printf '## Binding\n## Open\n## Landed' > "$T/progress.md"
p add "$T" landed 'Tail'; rc_is 'add onto no final newline' 0
printf '%s\n' '## Binding' '## Open' '## Landed' '### Tail' > "$T/want"
same 'no final newline joined' "$T/want" "$T/progress.md"

# ---- exit 6: anything but the record's shape

bad_shape() {
  fresh
  printf "$2" > "$T/progress.md"
  "$REAL_CAT" "$T/progress.md" > "$T/orig"
  p add "$T" open 'x'
  rc_is "shape: $1" 6
  has "shape: $1 says what to do" "$ERR" "${3:-clear them by hand}"
  same "shape: $1 unchanged" "$T/orig" "$T/progress.md"
  clean "shape: $1"
}
bad_shape 'missing section' '## Binding\n## Landed\n' " '## Binding' '## Landed' and add"
bad_shape 'wrong order' '## Open\n## Binding\n## Landed\n' " '## Open' '## Binding' '## Landed' and add"
bad_shape 'blank line' '## Binding\n\n## Open\n## Landed\n'
bad_shape 'prose under a block' '## Binding\n### a\nprose\n## Open\n## Landed\n'
bad_shape 'block before a section' '### a\n## Binding\n## Open\n## Landed\n' " '### a' and add"
bad_shape 'no heading at all' 'only prose\n'
bad_shape 'a title over the sections' '# T\n## Binding\n## Open\n## Landed\n'
bad_shape 'extra section' '## Binding\n### Rule\n## Open\n## Landed\n### Wave 1\n## More\nnote\n' "/progress.md '## More' and add"
p move "$T/progress.md" 'Landed'
rc_is 'extra section: a section still refuses' 3
p move "$T/progress.md" '## More'
rc_is 'extra section: its command runs' 0
printf '%s\n' '## Binding' '### Rule' '## Open' '## Landed' '### Wave 1' > "$T/want"
same 'extra section: the record keeps its sections and blocks' "$T/want" "$T/progress.md"
p add "$T" open 'x'
rc_is 'extra section: add then works' 0

# The command an old record's refusal prints is the one that clears it, whatever its headings.
migrates() {
  bad_shape "$1" "$2" "$3"
  command_line=$(sed "s/.*dispatch a worker to run progress move \(.*\) and add what still binds/\1/" "$ERR")
  eval "p move $command_line"
  rc_is "$1: its command runs" 0
  tail -n +2 "$T/archive.md" > "$T/body"
  same "$1: byte-identical in the archive" "$T/orig" "$T/body"
  p add "$T" open 'x'
  rc_is "$1: add then works" 0
}
migrates 'old record' '## Current state\nlong prose\n' " '## Current state' and add"
migrates 'titled record' '# A title: progress\nintro\n\n## Wave 1\nbody\n## Wave 2\nbody\n' " '# A title: progress' and add"
migrates 'several top headings' '## Plan\na\n### Sub\nb\n## Progress\nc\n' " '## Plan' '## Progress' and add"
migrates 'a quote in a heading' "# What's left\nbody\n" "'# What'\\''s left' and add"

# A rewrite that comes out the wrong size or not at all never replaces the record.
fresh
printf '%s\n' '## Binding' '### Rule' '## Open' '## Landed' > "$T/progress.md"
"$REAL_CAT" "$T/progress.md" > "$T/orig"
mkdir "$T/shim"
printf '#!/bin/sh\n%s >/dev/null\nexit 0\n' "$REAL_CAT" > "$T/shim/awk"
chmod +x "$T/shim/awk"
run env PATH="$T/shim:$PATH" "$PROGRESS" add "$T" open 'x'
rc_is 'add whose rewrite comes out short' 5
same 'short rewrite leaves the record' "$T/orig" "$T/progress.md"
printf '#!/bin/sh\nexit 2\n' > "$T/shim/awk"
run env PATH="$T/shim:$PATH" "$PROGRESS" add "$T" open 'x'
rc_is 'add whose rewrite fails' 5
same 'failed rewrite leaves the record' "$T/orig" "$T/progress.md"
rm -rf "$T/shim"
clean 'failed add'

# Relative paths: the archive and the lock sit beside FILE.
fresh
mkdir "$T/sub"
doc "$T/sub/plan.md"
(cd "$T/sub" && "$PROGRESS" move plan.md '## One') > "$OUT" 2> "$ERR"
RC=$?
rc_is 'relative FILE' 0
has 'relative FILE archive' "$T/sub/archive.md" 'body one'
(cd "$T/sub" && "$PROGRESS" add . open 'here') > "$OUT" 2> "$ERR"
RC=$?
rc_is 'relative DIR' 0
has 'relative DIR record' "$T/sub/progress.md" '### here'

# ---- the 12 KB step

seed() {
  awk -v n="$2" 'BEGIN {
    printf "## Binding\n### "
    for (i = 0; i < n; i++) printf "x"
    printf "\n## Open\n## Landed\n"
  }' > "$1"
}
fresh
seed "$T/progress.md" 11916
eq 'seed size' 11950 "$(bytes "$T/progress.md")"
p add "$T" open 'just under the step, forty-three bytes of it'
rc_is 'under the step' 0
eq 'no trigger under the step' 'open: 11999 bytes' "$("$REAL_CAT" "$OUT")"
p add "$T" open 'c'
eq 'crossing fires' 'open: 12005 bytes | crossed a 12 KB step: dispatch the pass' "$("$REAL_CAT" "$OUT")"
p add "$T" open 'd'
eq 'fires once' 'open: 12011 bytes' "$("$REAL_CAT" "$OUT")"
fresh
seed "$T/progress.md" 11916
p add "$T" open 'exactly to the step, forty-four bytes of text'
eq 'landing on the multiple fires' 'open: 12000 bytes | crossed a 12 KB step: dispatch the pass' "$("$REAL_CAT" "$OUT")"
p move "$T/progress.md" 'xxxx'
rc_is 'the pass shrinks' 0
p add "$T" open 'e'
lacks 'no trigger after shrinking' "$OUT" 'crossed'
seed "$T/progress.md" 11960
p add "$T" landed 'f'
has 'fires again on the next crossing' "$OUT" 'crossed a 12 KB step: dispatch the pass'
fresh
seed "$T/progress.md" 23960
p add "$T" landed 'g'
has 'fires at the second multiple' "$OUT" 'crossed a 12 KB step: dispatch the pass'

# ---- list and block boundaries

fresh
doc "$T/plan.md"
p list "$T/plan.md"
rc_is 'list' 0
printf '1\t88\t# Title\n4\t39\t## One\n7\t22\t### One sub\n10\t34\t## Two\n13\t17\t### Two sub\n' > "$T/want"
same 'list: line, bytes, heading' "$OUT" "$T/want"
absent 'list takes no lock' "$T/.progress.lock"

fresh
printf '%s\n' '## A' 'a' '### A1' 'a1' '#### A2' 'a2' '### A3' 'a3' '## B' 'b' > "$T/plan.md"
p move "$T/plan.md" '### A1'
rc_is 'nested heading' 0
eq 'block ends at same level' "$(printf 'moved 4 lines, 21 bytes: ### A1\nplan.md: 24 bytes; archive.md: 65 bytes')" "$("$REAL_CAT" "$OUT")"
printf '%s\n' '## A' 'a' '### A3' 'a3' '## B' 'b' > "$T/want"
same 'rest of nested move' "$T/want" "$T/plan.md"
printf '%s\n' '# Archive: grep a heading, never read whole' '### A1' 'a1' '#### A2' 'a2' > "$T/want"
same 'archive of nested move' "$T/want" "$T/archive.md"
p move "$T/plan.md" '## A'
rc_is 'higher level takes its children' 0
printf '%s\n' '## B' 'b' > "$T/want"
same 'rest after parent move' "$T/want" "$T/plan.md"

fresh
printf '%s\n' '####### not a heading' 'x' '##nospace' '# Top' 'y' '    ## indented' > "$T/plan.md"
p list "$T/plan.md"
eq 'only real headings listed' "$(printf '4\t24\t# Top')" "$("$REAL_CAT" "$OUT")"

# ---- code fences

fresh
cat > "$T/plan.md" <<'EOF'
# Doc
## A
```sh
# not a heading
## nor this
```
~~~
### still not
```
## a backtick fence does not close a tilde one
~~~
````md
```
# inner fence
```
## inner heading
````
```inline``` is not a fence
## B
tail
EOF
"$REAL_CAT" "$T/plan.md" > "$T/orig"
p list "$T/plan.md"
rc_is 'list with fences' 0
holds_n 'list skips fenced headings' "$OUT" '#' 3
has 'list has A' "$OUT" '## A'
has 'list has B' "$OUT" '## B'
p move "$T/plan.md" 'not a heading'
rc_is 'fenced heading is no heading' 3
p move "$T/plan.md" '## A'
rc_is 'move across fences' 0
printf '%s\n' '# Doc' '## B' 'tail' > "$T/want"
same 'fenced block moved whole' "$T/want" "$T/plan.md"
has 'archive holds the fenced text' "$T/archive.md" '## nor this'

fresh
printf '%s\n' '## C' '```' '## D in an unclosed fence' > "$T/plan.md"
p list "$T/plan.md"
holds_n 'an unclosed fence runs to the end' "$OUT" '##' 1
fresh
printf '%s\n' '## C' '   ```' '## fenced' '  ```  ' '## E' '    ```' '## F' > "$T/plan.md"
p list "$T/plan.md"
holds_n 'indents up to three open and close a fence, four is no fence' "$OUT" '##' 3

# ---- matching

fresh
printf '%s\n' '### Wave 1' 'a' '### Wave 10' 'b' '### Wave 11' 'c' > "$T/plan.md"
"$REAL_CAT" "$T/plan.md" > "$T/orig"
p move "$T/plan.md" 'Wave 1'
rc_is 'several match' 3
has 'several: lists them with lines' "$ERR" '3: ### Wave 10'
has 'several: lists all' "$ERR" '5: ### Wave 11'
same 'several: unchanged' "$T/orig" "$T/plan.md"
absent 'several: no archive' "$T/archive.md"
p move "$T/plan.md" 'wave 10'
rc_is 'case-sensitive' 3
p move "$T/plan.md" 'Wave 9'
rc_is 'none match' 3
p move "$T/plan.md" '### Wave 1'
rc_is 'a whole heading line wins over containment' 0
printf '%s\n' '### Wave 10' 'b' '### Wave 11' 'c' > "$T/want"
same 'whole-line pick' "$T/want" "$T/plan.md"
fresh
printf '%s\n' '### Same' 'a' '### Same' 'b' > "$T/plan.md"
p move "$T/plan.md" '### Same'
rc_is 'two identical heading lines stay ambiguous' 3
fresh
printf '%s\n' '## a.b*c [x]' 'y' '## azbyc' 'z' > "$T/plan.md"
p move "$T/plan.md" 'a.b*c [x]'
rc_is 'text is fixed, not a pattern' 0
has 'pattern-like rest' "$T/plan.md" '## azbyc'
fresh
printf '%s\n' '## back\slash \n' 'y' > "$T/plan.md"
p move "$T/plan.md" 'back\slash \n'
rc_is 'backslashes are literal' 0

# ---- several arguments

fresh
doc "$T/plan.md"
"$REAL_CAT" "$T/plan.md" > "$T/orig"
p move "$T/plan.md" '## One' 'no such heading' '## Two'
rc_is 'one bad heading' 3
same 'one bad heading moves nothing' "$T/orig" "$T/plan.md"
absent 'one bad heading archives nothing' "$T/archive.md"
clean 'one bad heading'
p move "$T/plan.md" '## One' '### One sub'
rc_is 'overlapping arguments' 3
same 'overlap moves nothing' "$T/orig" "$T/plan.md"
p move "$T/plan.md" '### One sub' '## One'
rc_is 'overlapping arguments, either order' 3
p move "$T/plan.md" '## Two' 'Two'
rc_is 'same block twice is ambiguous or overlap' 3
p move "$T/plan.md" '## Two' '## Two'
rc_is 'same heading twice is an overlap' 3
has 'same heading twice says so' "$ERR" 'overlap'
p move "$T/plan.md" '## Two' '## One'
rc_is 'in order' 0
holds_n 'a line per block and a total' "$OUT" 'moved' 2
holds_n 'total line' "$OUT" 'plan.md:' 1
lacks 'move never prints a block body' "$OUT" 'body one'
lacks 'move never prints a block body' "$OUT" 'sub body'
two=$(grep -n '^## Two' "$T/archive.md" | cut -d: -f1)
one=$(grep -n '^## One' "$T/archive.md" | cut -d: -f1)
if [ "$two" -lt "$one" ]; then pass; else fail 'blocks archived out of argument order'; fi
printf '%s\n' '# Title' 'intro' '' > "$T/want"
same 'rest after both' "$T/want" "$T/plan.md"

# ---- a record keeps its sections

fresh
printf '%s\n' '## Binding' '### Rule' '## Open' '## Landed' '### Wave 1' '### Wave 2' > "$T/progress.md"
"$REAL_CAT" "$T/progress.md" > "$T/orig"
for section in Binding Open Landed '## Landed'; do
  p move "$T/progress.md" "$section"
  rc_is "whole section $section" 3
  same "whole section $section unchanged" "$T/orig" "$T/progress.md"
done
has 'whole section says what to do' "$ERR" 'name its blocks'
p move "$T/progress.md" 'Wave 1' 'Landed'
rc_is 'a section among blocks' 3
same 'a section among blocks moves nothing' "$T/orig" "$T/progress.md"
absent 'a section archives nothing' "$T/archive.md"
p move "$T/progress.md" 'Wave 1'
rc_is 'its blocks still move' 0
p add "$T" landed 'Wave 3'
rc_is 'and add still works' 0

# The same names in another shape are ordinary headings.
fresh
printf '%s\n' '# Doc' '## Open' 'text' '## Other' 'more' > "$T/plan.md"
p move "$T/plan.md" '## Open'
rc_is 'a heading named like a section, elsewhere' 0
fresh
printf '%s\n' '## Current state' 'old' '## Landed' 'old too' > "$T/progress.md"
p move "$T/progress.md" 'Landed'
rc_is 'a section of an old-format record' 0

# ---- first line, last line, no final newline, whole record

fresh
printf '%s\n' '## First' 'a' '## Second' 'b' > "$T/plan.md"
p move "$T/plan.md" '## First'
rc_is 'heading on line one' 0
printf '%s\n' '## Second' 'b' > "$T/want"
same 'heading on line one, rest' "$T/want" "$T/plan.md"

fresh
printf '%s\n' 'x' '## Last' > "$T/plan.md"
p move "$T/plan.md" 'Last'
rc_is 'heading on the last line' 0
has 'one-line block' "$OUT" 'moved 1 lines, 8 bytes: ## Last'
printf 'x\n' > "$T/want"
same 'heading on the last line, rest' "$T/want" "$T/plan.md"

fresh
printf 'x\n## Last' > "$T/plan.md"
p move "$T/plan.md" 'Last'
rc_is 'bare last heading, no newline' 0
has 'bare last heading size' "$OUT" 'moved 1 lines, 7 bytes: ## Last'

fresh
printf 'x\n## A\nbody a\n## B\nb one\nb last' > "$T/plan.md"
p list "$T/plan.md"
eq 'list counts the unterminated last block' "$(printf '2\t12\t## A\n4\t17\t## B')" "$("$REAL_CAT" "$OUT")"
p move "$T/plan.md" '## A'
rc_is 'middle block of a file with no final newline' 0
printf 'x\n## B\nb one\nb last' > "$T/want"
same 'rest keeps the missing newline' "$T/want" "$T/plan.md"
p move "$T/plan.md" '## B'
rc_is 'last block, no final newline' 0
has 'last block keeps its last line' "$OUT" 'moved 3 lines, 17 bytes: ## B'
has 'archive holds the last line' "$T/archive.md" 'b last'
printf 'x\n' > "$T/want"
same 'rest after last block' "$T/want" "$T/plan.md"
printf '%s\n## C\nc\n' 'x' > "$T/plan.md"
p move "$T/plan.md" '## C'
rc_is 'append after an open archive tail' 0
printf '# Archive: grep a heading, never read whole\n## A\nbody a\n## B\nb one\nb last\n## C\nc\n' > "$T/want"
same 'open tail closed by one newline' "$T/want" "$T/archive.md"

fresh
{
  printf '## Current state\n'
  awk 'BEGIN { for (i = 1; i <= 126; i++) print "long old prose line " i }'
} > "$T/progress.md"
"$REAL_CAT" "$T/progress.md" > "$T/orig"
p move "$T/progress.md" 'Current state'
rc_is 'whole record' 0
has 'whole record size line' "$OUT" 'progress.md: 0 bytes'
tail -n +2 "$T/archive.md" > "$T/body"
same 'whole record byte-identical in the archive' "$T/orig" "$T/body"
p add "$T" binding 'Grep the archive for your wave.'
rc_is 'add on the emptied file' 0
printf '%s\n' '## Binding' '### Grep the archive for your wave.' '## Open' '## Landed' > "$T/want"
same 'emptied file reshaped' "$T/want" "$T/progress.md"

# ---- reassembly

fresh
{
  printf 'preamble\n\n# Head\nfacts\n'
  printf '```sh\n## fenced in the facts\n```\n'
  printf '## Waves\n\n'
  for i in 1 2 3 4 5 6; do printf '### Wave %s\nline a\n\nline b\n\n' "$i"; done
  printf '## Deferred\nlater\n'
} > "$T/plan.md"
"$REAL_CAT" "$T/plan.md" > "$T/orig"
p move "$T/plan.md" 'Wave 1' 'Wave 2' 'Wave 3' 'Wave 4' 'Wave 5' 'Wave 6'
rc_is 'moves in file order' 0
at=$(grep -n '^## Deferred' "$T/plan.md" | cut -d: -f1)
{
  head -n $((at - 1)) "$T/plan.md"
  tail -n +2 "$T/archive.md"
  tail -n "+$at" "$T/plan.md"
} > "$T/joined"
same 'remainder and archive reassemble' "$T/orig" "$T/joined"

# ---- multibyte under a UTF-8 locale

UTF8=$(locale -a 2>/dev/null | grep -i 'utf-\{0,1\}8$' | head -n 1)
if [ -n "$UTF8" ]; then
  fresh
  printf '# Kopf\nintro\n## Bl\303\266cke \342\202\254\ntext \346\227\245\346\234\254\350\252\236\n\n## Rest\nr\n' > "$T/plan.md"
  printf '## Bl\303\266cke \342\202\254\ntext \346\227\245\346\234\254\350\252\236\n\n' > "$T/block"
  want_bytes=$(bytes "$T/block")
  run env LC_ALL="$UTF8" "$PROGRESS" list "$T/plan.md"
  rc_is 'multibyte list' 0
  has 'multibyte list counts bytes' "$OUT" "3	$want_bytes	"
  run env LC_ALL="$UTF8" "$PROGRESS" move "$T/plan.md" "$(printf 'Bl\303\266cke')"
  rc_is 'multibyte move' 0
  has 'multibyte move counts bytes' "$OUT" "moved 3 lines, $want_bytes bytes:"
  tail -n +2 "$T/archive.md" > "$T/body"
  same 'multibyte block byte-identical' "$T/block" "$T/body"

  fresh
  euros=$(awk 'BEGIN { for (i = 0; i < 100; i++) printf "\342\202\254" }')
  run env LC_ALL="$UTF8" "$PROGRESS" add "$T" open "$euros"
  rc_is '100 three-byte characters are 300 bytes' 0
  run env LC_ALL="$UTF8" "$PROGRESS" add "$T" open "${euros}x"
  rc_is '301 bytes in 101 characters' 2
else
  SKIPPED="$SKIPPED no-utf8-locale"
fi

# ---- mode

fresh
doc "$T/plan.md"
chmod 640 "$T/plan.md"
p move "$T/plan.md" '## One'
rc_is 'mode: move' 0
eq 'mode kept by move' '-rw-r-----' "$(mode "$T/plan.md")"
fresh
printf '## Binding\n## Open\n## Landed\n' > "$T/progress.md"
chmod 600 "$T/progress.md"
p add "$T" open 'x'
rc_is 'mode: add' 0
eq 'mode kept by add' '-rw-------' "$(mode "$T/progress.md")"
fresh
: > "$T/progress.md"
chmod 640 "$T/progress.md"
p add "$T" open 'x'
eq 'mode of an empty file kept by add' '-rw-r-----' "$(mode "$T/progress.md")"

if [ "$(id -u)" -ne 0 ]; then
  fresh
  doc "$T/plan.md"
  chmod 444 "$T/plan.md"
  p move "$T/plan.md" '## One'
  rc_is 'read-only file refused' 2
  chmod 644 "$T/plan.md"
  : > "$T/archive.md"
  chmod 444 "$T/archive.md"
  "$REAL_CAT" "$T/plan.md" > "$T/orig"
  p move "$T/plan.md" '## One'
  rc_is 'read-only archive is a failed proof' 5
  has 'names the archive' "$ERR" "$T/archive.md"
  same 'read-only archive leaves the source' "$T/orig" "$T/plan.md"
  clean 'read-only archive'
  chmod 644 "$T/archive.md"

  fresh
  mkdir "$T/ro"
  doc "$T/ro/plan.md"
  chmod 555 "$T/ro"
  p move "$T/ro/plan.md" '## One'
  rc_is 'read-only directory refused' 2
  chmod 755 "$T/ro"

  fresh
  doc "$T/plan.md"
  chmod 200 "$T/plan.md"
  p move "$T/plan.md" '## One'
  rc_is 'unreadable file refused' 2
  chmod 644 "$T/plan.md"
  clean 'unreadable file'
else
  SKIPPED="$SKIPPED running-as-root"
fi

# ---- the proof

fresh
doc "$T/plan.md"
"$REAL_CAT" "$T/plan.md" > "$T/orig"
# The second cksum of a move is the reassembly's.
cat > "$T/hook" <<EOF
n=\$("$REAL_CAT" "$T/count" 2>/dev/null || echo 0)
n=\$((n + 1))
echo "\$n" > "$T/count"
[ "\$n" -ne 2 ] || exit 9
EOF
p_hooked move "$T/plan.md" '## One'
rc_is 'split that does not reassemble' 5
same 'failed split leaves the source' "$T/orig" "$T/plan.md"
absent 'failed split archives nothing' "$T/archive.md"
clean 'failed split'

fresh
doc "$T/plan.md"
"$REAL_CAT" "$T/plan.md" > "$T/orig"
cat > "$T/hook" <<EOF
! grep -q 'body one' "$T/archive.md" 2>/dev/null
EOF
p_hooked move "$T/plan.md" '## One'
rc_is 'archive tail that does not match' 5
has 'tail failure names the archive' "$ERR" "$T/archive.md"
same 'tail failure leaves the source' "$T/orig" "$T/plan.md"
clean 'tail failure'

# ---- crash and replay

fresh
doc "$T/plan.md"
"$REAL_CAT" "$T/plan.md" > "$T/orig"
p move "$T/plan.md" '## One'
rc_is 'first move' 0
"$REAL_CAT" "$T/archive.md" > "$T/archive.orig"
# As a crash between append and rename leaves it, and as an Edit's rename that lands inside a
# move's window leaves it: the block in both.
"$REAL_CAT" "$T/orig" > "$T/plan.md"
p move "$T/plan.md" '## One'
rc_is 'replay' 0
same 'replay does not append again' "$T/archive.orig" "$T/archive.md"
lacks 'replay clears the source' "$T/plan.md" 'body one'

# Text that only ends a longer archive line is not this block already archived.
fresh
printf '%s\n' '## A' 'b' '## Z' 'z' > "$T/plan.md"
printf '%s\n' '# Archive' 'see ## A' 'b' > "$T/archive.md"
p move "$T/plan.md" '## A'
rc_is 'block text inside a longer archive line' 0
printf '%s\n' '# Archive' 'see ## A' 'b' '## A' 'b' > "$T/want"
same 'that block is appended' "$T/want" "$T/archive.md"

# With no final newline the archive's tail stays open, and a replay still finds it.
fresh
printf 'x\n## Last\nend' > "$T/plan.md"
"$REAL_CAT" "$T/plan.md" > "$T/orig"
p move "$T/plan.md" '## Last'
rc_is 'open-tail move' 0
"$REAL_CAT" "$T/archive.md" > "$T/archive.orig"
"$REAL_CAT" "$T/orig" > "$T/plan.md"
p move "$T/plan.md" '## Last'
rc_is 'open-tail replay' 0
same 'open-tail replay does not append' "$T/archive.orig" "$T/archive.md"

# A real crash: killed outright once the block is in the archive, lock and temp files left behind.
fresh
doc "$T/plan.md"
cat > "$T/hook" <<EOF
if grep -q 'body one' "$T/archive.md" 2>/dev/null; then
  kill -9 "\$("$REAL_CAT" "$T/.progress.lock/pid")"
fi
EOF
{ p_hooked move "$T/plan.md" '## One'; } 2>/dev/null
eq 'killed outright' 137 "$RC"
has 'crash leaves the block in the source' "$T/plan.md" 'body one'
has 'crash leaves the block in the archive' "$T/archive.md" 'body one'
if [ -d "$T/.progress.lock" ]; then pass; else fail 'crash left no lock to break'; fi
p move "$T/plan.md" '## One'
rc_is 'replay after a crash breaks the lock' 0
holds_n 'replay after a crash' "$T/archive.md" 'body one' 1
lacks 'replay after a crash clears the source' "$T/plan.md" 'body one'
clean 'replay after a crash removes the dead temp files'

# ---- a writer between read and rename

fresh
printf '%s\n' '# Doc' '## Keep' 'kept' '## Moving' 'version one' '## After' 'after' > "$T/plan.md"
cat > "$T/hook" <<EOF
[ ! -e "$T/flag" ] || exit 0
grep -q 'version one' "$T/archive.md" 2>/dev/null || exit 0
: > "$T/flag"
awk '{ if (\$0 == "version one") print "version two"; else print }' "$T/plan.md" > "$T/plan.new"
mv "$T/plan.new" "$T/plan.md"
EOF
p_hooked move "$T/plan.md" '## Moving'
rc_is 'writer inside the block' 0
holds_n 'older version archived' "$T/archive.md" 'version one' 1
holds_n 'newer version archived' "$T/archive.md" 'version two' 1
lacks 'block out of the source' "$T/plan.md" 'version two'
printf '%s\n' '# Doc' '## Keep' 'kept' '## After' 'after' > "$T/want"
same 'rest of a retried move' "$T/want" "$T/plan.md"
clean 'writer inside the block'

fresh
printf '%s\n' '# Doc' '## Moving' 'block body' '## After' 'after' > "$T/plan.md"
cat > "$T/hook" <<EOF
[ ! -e "$T/flag" ] || exit 0
grep -q 'block body' "$T/archive.md" 2>/dev/null || exit 0
: > "$T/flag"
printf 'appended by a raw writer\n' >> "$T/plan.md"
EOF
p_hooked move "$T/plan.md" '## Moving'
rc_is 'raw append outside the block' 0
holds_n 'unchanged block archived once' "$T/archive.md" 'block body' 1
has 'the writer keeps its line' "$T/plan.md" 'appended by a raw writer'
lacks 'block out of the source' "$T/plan.md" 'block body'

fresh
printf '%s\n' '# Doc' '## Moving' 'first read' '## After' 'after' > "$T/plan.md"
# Before the first cksum of the snapshot: FILE differs from what was read before anything is
# archived.
cat > "$T/hook" <<EOF
[ ! -e "$T/flag" ] || exit 0
: > "$T/flag"
printf 'line after the snapshot\n' >> "$T/plan.md"
EOF
p_hooked move "$T/plan.md" '## Moving'
rc_is 'writer right after the read' 0
has 'that writer keeps its line' "$T/plan.md" 'line after the snapshot'
holds_n 'block archived once' "$T/archive.md" 'first read' 1
lacks 'the writer stays out of the archive' "$T/archive.md" 'line after the snapshot'

fresh
printf '%s\n' '# Doc' '## Moving' 'always' > "$T/plan.md"
cat > "$T/hook" <<EOF
printf 'more\n' >> "$T/plan.md"
EOF
p_hooked move "$T/plan.md" '## Moving'
rc_is 'FILE keeps changing' 4
has 'says kept changing' "$ERR" 'kept changing through 3 tries'
has 'block still in the source' "$T/plan.md" 'always'
has 'block in the archive' "$T/archive.md" 'always'
clean 'FILE keeps changing'

fresh
printf '%s\n' '# Doc' '## Moving' 'gone soon' '## After' 'a' > "$T/plan.md"
cat > "$T/hook" <<EOF
[ ! -e "$T/flag" ] || exit 0
grep -q 'gone soon' "$T/archive.md" 2>/dev/null || exit 0
: > "$T/flag"
printf '%s\n' '# Doc' '## After' 'a' > "$T/plan.new"
mv "$T/plan.new" "$T/plan.md"
EOF
p_hooked move "$T/plan.md" '## Moving'
rc_is 'writer removes the heading in the window' 3
has 'its bytes stay in the archive' "$T/archive.md" 'gone soon'
has 'and the message says where' "$ERR" "is in $T/archive.md"

# A writer outside the lock while add works: the writer's line and add's both land.
fresh
printf '%s\n' '## Binding' '## Open' '## Landed' > "$T/progress.md"
cat > "$T/hook" <<EOF
[ ! -e "$T/flag" ] || exit 0
: > "$T/flag"
printf '%s\n' '## Binding' '### written outside' '## Open' '## Landed' > "$T/new"
mv "$T/new" "$T/progress.md"
EOF
p_hooked add "$T" landed 'by add'
rc_is 'add with a writer in the window' 0
printf '%s\n' '## Binding' '### written outside' '## Open' '## Landed' '### by add' > "$T/want"
same 'add redoes on the changed file' "$T/want" "$T/progress.md"
clean 'add with a writer in the window'

fresh
printf '%s\n' '## Binding' '## Open' '## Landed' > "$T/progress.md"
cat > "$T/hook" <<EOF
printf '### more %s\n' "\$\$" >> "$T/progress.md"
EOF
p_hooked add "$T" open 'never lands'
rc_is 'add when FILE keeps changing' 4
lacks 'its line is not there' "$T/progress.md" 'never lands'
has 'the writer keeps its lines' "$T/progress.md" '### more'
clean 'add when FILE keeps changing'

# ---- the lock

fresh
doc "$T/plan.md"
"$REAL_CAT" "$T/plan.md" > "$T/orig"
mkdir "$T/.progress.lock"
echo "$$" > "$T/.progress.lock/pid"
p_nosleep move "$T/plan.md" '## One'
rc_is 'move times out on a live lock' 4
has 'timeout names the lock' "$ERR" "$T/.progress.lock"
has 'timeout names the pid' "$ERR" "pid $$"
same 'timeout leaves the file' "$T/orig" "$T/plan.md"
eq 'timeout leaves the lock' "$$" "$("$REAL_CAT" "$T/.progress.lock/pid")"
p_nosleep add "$T" open 'x'
rc_is 'add times out on a live lock' 4
rm -rf "$T/.progress.lock"
mkdir "$T/.progress.lock"
p_nosleep move "$T/plan.md" '## One'
rc_is 'a lock with no pid is waited on' 4
has 'no-pid timeout names the lock' "$ERR" "$T/.progress.lock"
if [ -d "$T/.progress.lock" ]; then pass; else fail 'a lock with no pid was removed'; fi
rm -rf "$T/.progress.lock"
# A live pid that refuses the signal is alive.
if [ "$(id -u)" -ne 0 ]; then
  mkdir "$T/.progress.lock"
  echo 1 > "$T/.progress.lock/pid"
  p_nosleep move "$T/plan.md" '## One'
  rc_is 'a live pid of another user keeps its lock' 4
  eq 'that lock stands' 1 "$("$REAL_CAT" "$T/.progress.lock/pid")"
  same 'that lock leaves the file' "$T/orig" "$T/plan.md"
  rm -rf "$T/.progress.lock"
else
  SKIPPED="$SKIPPED running-as-root"
fi
# A refused lock directory is no holder: said at once, with nothing to wait for.
mkdir "$T/shim"
printf '#!/bin/sh\necho "mkdir: $1: Operation not permitted" >&2\nexit 1\n' > "$T/shim/mkdir"
chmod +x "$T/shim/mkdir"
run env PATH="$T/shim:$SHIMS/nosleep:$PATH" "$PROGRESS" add "$T" open 'x'
rc_is 'a lock directory the system refuses' 2
has 'that refusal is the message' "$ERR" 'Operation not permitted'
rm -rf "$T/shim"
# While another breaker is at work no one else judges the lock.
mkdir "$T/.progress.lock" "$T/.progress.lock.break"
dead_pid > "$T/.progress.lock/pid"
p_nosleep add "$T" open 'x'
rc_is 'one breaker at a time' 4
has 'a stuck breaker is named' "$ERR" "$T/.progress.lock.break"
if [ -d "$T/.progress.lock" ]; then pass; else fail 'a second breaker removed the lock'; fi
rm -rf "$T/.progress.lock" "$T/.progress.lock.break"
mkdir "$T/.progress.lock"
dead_pid > "$T/.progress.lock/pid"
p move "$T/plan.md" '## One'
rc_is 'one dead lock broken' 0
clean 'one dead lock broken'
mkdir "$T/.progress.lock"
echo 'not a pid' > "$T/.progress.lock/pid"
p move "$T/plan.md" '## Two'
rc_is 'a lock holding no valid pid is broken' 0
clean 'a lock holding no valid pid is broken'

# A waiter who read the dead pid just before another waiter took the lock must not remove it.
fresh
doc "$T/plan.md"
mkdir "$T/.progress.lock"
dead_pid > "$T/.progress.lock/pid"
run env PATH="$SHIMS/swap:$SHIMS/nosleep:$PATH" PROGRESS_TEST_SWAP_FLAG="$T/flag" PROGRESS_TEST_LIVE_PID="$$" \
  "$PROGRESS" move "$T/plan.md" '## One'
rc_is 'a waiter holding a stale reading waits' 4
eq 'the live holder keeps the lock' "$$" "$("$REAL_CAT" "$T/.progress.lock/pid")"
eq 'only the lock is left' 1 "$(ls -A "$T" | grep -c '^\.progress')"

# Killed while breaking: the breaker's directory goes with it.
fresh
doc "$T/plan.md"
mkdir "$T/.progress.lock"
dead_pid > "$T/.progress.lock/pid"
run env PATH="$SHIMS/killbreaker:$PATH" "$PROGRESS" move "$T/plan.md" '## One'
eq 'signal while breaking: exit code' 143 "$RC"
clean 'signal while breaking'

# Each signal, delivered while the script holds the lock with temp files out.
signal_case() {
  fresh
  doc "$T/plan.md"
  "$REAL_CAT" "$T/plan.md" > "$T/orig"
  cat > "$T/hook" <<EOF
[ ! -e "$T/flag" ] || exit 0
: > "$T/flag"
kill -$1 "\$("$REAL_CAT" "$T/.progress.lock/pid")"
EOF
  p_hooked move "$T/plan.md" '## One'
  eq "signal $1: exit code" "$2" "$RC"
  same "signal $1: source unchanged" "$T/orig" "$T/plan.md"
  clean "signal $1"
}
# A signal ignored on entry, as for a background job or under nohup, cannot be trapped by anyone.
for pair in HUP:129 INT:130 TERM:143; do
  sig=${pair%:*}
  sh -c "trap 'exit 9' $sig; kill -$sig \$\$; exit 0" > /dev/null 2>&1
  if [ $? -eq 9 ]; then
    signal_case "$sig" "${pair#*:}"
  else
    SKIPPED="$SKIPPED $sig-ignored-on-entry"
  fi
done

# ---- concurrency

blocks() {
  printf 'head\n' > "$1"
  shift
  for b in "$@"; do printf '## %s\n%s body\n' "$b" "$b" >> "$T/plan.md"; done
}

fresh
blocks "$T/plan.md" a1 a2 a3 a4 b1 b2 b3 b4
"$PROGRESS" move "$T/plan.md" 'a1' 'a2' 'a3' 'a4' > "$T/o1" 2>&1 &
first=$!
"$PROGRESS" move "$T/plan.md" 'b1' 'b2' 'b3' 'b4' > "$T/o2" 2>&1 &
second=$!
wait "$first"; eq 'first of two concurrent moves' 0 $?
wait "$second"; eq 'second of two concurrent moves' 0 $?
for b in a1 a2 a3 a4 b1 b2 b3 b4; do holds_n 'concurrent moves' "$T/archive.md" "## $b" 1; done
printf 'head\n' > "$T/want"
same 'concurrent moves, rest' "$T/want" "$T/plan.md"
clean 'concurrent moves'

fresh
{
  printf '## Binding\n'
  for b in old1 old2 old3 old4; do printf '### %s\n' "$b"; done
  printf '## Open\n## Landed\n'
} > "$T/progress.md"
"$PROGRESS" move "$T/progress.md" 'old1' 'old2' > "$T/o1" 2>&1 &
pids=$!
for b in new1 new2 new3; do
  "$PROGRESS" add "$T" landed "$b" > "$T/o.$b" 2>&1 &
  pids="$pids $!"
done
for pid in $pids; do wait "$pid"; eq 'move and adds together' 0 $?; done
printf '%s\n' '## Binding' '### old3' '### old4' '## Open' '## Landed' > "$T/want"
grep -v 'new[123]' "$T/progress.md" > "$T/kept"
same 'move and adds: the record' "$T/want" "$T/kept"
for b in new1 new2 new3; do holds_n 'adds kept' "$T/progress.md" "### $b" 1; done
for b in old1 old2; do holds_n 'moved once' "$T/archive.md" "### $b" 1; done
clean 'move and adds'

fresh
"$PROGRESS" add "$T" open same > "$T/o1" 2>&1 &
first=$!
"$PROGRESS" add "$T" open same > "$T/o2" 2>&1 &
second=$!
wait "$first"; one=$?
wait "$second"; two=$?
eq 'same line twice: one lands, one refused' 3 "$((one + two))"
holds_n 'same line once' "$T/progress.md" '### same' 1

round=0
while [ "$round" -lt 3 ]; do
  round=$((round + 1))
  fresh
  blocks "$T/plan.md" w1 w2 w3 w4
  mkdir "$T/.progress.lock"
  dead_pid > "$T/.progress.lock/pid"
  pids=
  for b in w1 w2 w3 w4; do
    "$PROGRESS" move "$T/plan.md" "$b" > "$T/o.$b" 2>&1 &
    pids="$pids $!"
  done
  for pid in $pids; do wait "$pid"; eq "stale lock, waiters at once, round $round" 0 $?; done
  for b in w1 w2 w3 w4; do holds_n 'stale lock, moved once' "$T/archive.md" "## $b" 1; done
  printf 'head\n' > "$T/want"
  same 'stale lock, rest' "$T/want" "$T/plan.md"
  clean 'stale lock'
done

# Adders racing on a dead lock: a line whose add returned 0 is in the record.
round=0
while [ "$round" -lt 3 ]; do
  round=$((round + 1))
  fresh
  mkdir "$T/.progress.lock"
  dead_pid > "$T/.progress.lock/pid"
  pids=
  for b in r1 r2 r3 r4 r5; do
    "$PROGRESS" add "$T" landed "$b" > "$T/o.$b" 2>&1 &
    pids="$pids $!"
  done
  for pid in $pids; do wait "$pid"; eq "adders on a dead lock, round $round" 0 $?; done
  for b in r1 r2 r3 r4 r5; do holds_n 'adders on a dead lock, landed' "$T/progress.md" "### $b" 1; done
  clean 'adders on a dead lock'
done

# Stdout closed partway: every block whole in one place, nothing left behind.
fresh
blocks "$T/plan.md" p1 p2 p3 p4 p5 p6
"$PROGRESS" move "$T/plan.md" p1 p2 p3 p4 p5 p6 2> /dev/null | head -n 1 > /dev/null
for b in p1 p2 p3 p4 p5 p6; do
  n=$("$REAL_CAT" "$T/plan.md" "$T/archive.md" | grep -c "^## $b\$")
  eq "stdout closed: $b once" 1 "$n"
done
clean 'stdout closed'

# A reader sees the old file or the new one, whole.
fresh
{
  printf 'FIRST\n'
  i=0
  while [ "$i" -lt 25 ]; do
    i=$((i + 1))
    printf '## Block %s\nbody %s\n' "$i" "$i"
  done
  printf '## End\nLAST\n'
} > "$T/plan.md"
(
  while [ ! -e "$T/done" ]; do
    "$REAL_CAT" "$T/plan.md" > "$T/seen"
    if [ "$(head -n 1 "$T/seen")" != FIRST ] || [ "$(tail -n 1 "$T/seen")" != LAST ]; then
      : > "$T/torn"
    fi
    : > "$T/read"
  done
) &
reader=$!
set --
i=0
while [ "$i" -lt 25 ]; do
  i=$((i + 1))
  set -- "$@" "## Block $i"
done
p move "$T/plan.md" "$@"
rc_is 'moves under a reader' 0
: > "$T/done"
wait "$reader"
absent 'reader never saw a torn file' "$T/torn"
if [ -e "$T/read" ]; then pass; else fail 'the reader never read'; fi

# ---- tools the script must not depend on

for forbidden in 'flock' 'sed -i' 'jq' 'head -n 0' 'python'; do
  if grep -q -- "$forbidden" "$PROGRESS"; then fail "script uses $forbidden"; else pass; fi
done

printf '%s passed, %s failed%s\n' "$PASSED" "$FAILED" "${SKIPPED:+; skipped:$SKIPPED}"
[ "$FAILED" -eq 0 ]
