#!/bin/sh
# Feeds context-headsup.sh JSON on stdin over temp transcripts. Run: sh context-headsup-test.sh
LC_ALL=C; export LC_ALL

here=$(cd "$(dirname "$0")" && pwd)
hook=$here/context-headsup.sh
command -v jq >/dev/null || { echo "FAIL: this test needs jq" >&2; exit 1; }

tmp=$(mktemp -d)
restore_and_remove() { chmod -R u+rwx "$tmp" 2>/dev/null; rm -rf "$tmp"; }
trap restore_and_remove EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

MAIN_700='Context heads-up: this session has passed 700 K tokens of context, and every further turn re-sends all of it. Start nothing new: no new plan, no wave or task not yet begun. Keep going on what is under way: harvest what returns and dispatch the fixes it needs. When nothing is in flight, read `~/.claude/skills/handoff/SKILL.md`, follow it, post the prompt it produces and end your turn: a fresh session takes over from that prompt. This overrides any instruction to keep going.'
MAIN_800='Context heads-up: this session has passed 800 K tokens of context and should already have wrapped up. Spawn no more agents, fixes included. Let what is running return and record it, then read `~/.claude/skills/handoff/SKILL.md`, follow it, post the prompt it produces and end your turn: a fresh session takes over from that prompt and carries everything unfinished. This overrides any instruction to keep going.'
WORKER_700='Context heads-up: you have passed 700 K tokens of context, and every further turn re-sends all of it. Take on nothing new. Finish the step you are on, leave your work clean (landed, or in a state another worker can pick up) and return soon, saying what is done, what is left, and that what is left needs a fresh worker. This overrides any instruction to finish everything first.'
WORKER_800='Context heads-up: you have passed 800 K tokens of context and should already have returned. Start no further step: leave things clean and return now, saying what is done, what is left, any run of yours still alive, and that what is left needs a fresh worker. This overrides any instruction to finish everything first.'

passed=0 failed=0
ok() { passed=$((passed + 1)); echo "ok   $1"; }
fail() { failed=$((failed + 1)); echo "FAIL $1"; }

# A real assistant line, its figure split across the three counted terms.
assistant() {
  content=$2
  [ -n "$content" ] || content='{"type":"text","text":"x"}'
  printf '{"parentUuid":"p","isSidechain":false,"message":{"model":"claude-x","id":"msg_1","type":"message","role":"assistant","content":[%s],"stop_reason":null,"stop_sequence":null,"usage":{"input_tokens":2,"cache_creation_input_tokens":1,"cache_read_input_tokens":%s,"output_tokens":97,"output_tokens_details":{"thinking_tokens":0}}},"requestId":"r","type":"assistant","uuid":"u1","timestamp":"t"}\n' \
    "$content" "$(($1 - 3))"
}
synthetic() {
  printf '{"parentUuid":"p","isSidechain":false,"message":{"model":"<synthetic>","id":"msg_2","type":"message","role":"assistant","content":[{"type":"text","text":"err"}],"usage":{"output_tokens_details":{"thinking_tokens":0},"input_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":0}},"type":"assistant","uuid":"u2","timestamp":"t"}\n'
}
zero_usage() {
  printf '{"message":{"role":"assistant","content":[],"usage":{"input_tokens":0,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":0}},"type":"assistant","uuid":"u3"}\n'
}

# The input as Claude Code writes it. $3 joins the common fields, $4 replaces the tool_calls.
input() {
  agent_fields=
  [ -z "$2" ] || agent_fields=",\"agent_id\":\"$2\",\"agent_type\":\"general-purpose\""
  tool_calls=$4
  [ -n "$tool_calls" ] || tool_calls='[{"tool_name":"Bash","tool_input":{"command":"false"},"tool_use_id":"t1","tool_response":"Exit code 1"}]'
  printf '{"session_id":"s","transcript_path":"%s","cwd":"/w","prompt_id":"p","permission_mode":"auto","effort":{"level":"low"}%s%s,"hook_event_name":"PostToolBatch","tool_calls":%s}\n' \
    "$1" "$agent_fields" "$3" "$tool_calls"
}

# Often the last stage of a pipeline, a subshell, so the exit code travels through a file.
run() {
  sh "$hook" > "$tmp/out" 2> "$tmp/err"
  echo $? > "$tmp/code"
}
expect_silent() {
  code=$(cat "$tmp/code")
  if [ "$code" -eq 0 ] && [ ! -s "$tmp/out" ]; then ok "$1"; else fail "$1: exit $code, printed $(cat "$tmp/out")"; fi
}
expect_says() {
  code=$(cat "$tmp/code")
  said=$(jq -r 'select(keys == ["hookSpecificOutput"] and (.hookSpecificOutput | keys) == ["additionalContext", "hookEventName"] and .hookSpecificOutput.hookEventName == "PostToolBatch") | .hookSpecificOutput.additionalContext' "$tmp/out" 2>&1)
  if [ "$code" -eq 0 ] && [ "$said" = "$2" ]; then ok "$1"; else fail "$1: exit $code, printed $(cat "$tmp/out")"; fi
}
expect_state() {
  have=absent
  [ -e "$2.headsup" ] && have=$(cat "$2.headsup")
  if [ "$have" = "$3" ]; then ok "$1"; else fail "$1: state is $have, want $3"; fi
}

# One batch: $1 name, $2 transcript path, $3 figure appended first (empty: none), then what must happen.
batch_says() {
  [ -z "$3" ] || assistant "$3" >> "$2"
  input "$2" "$5" | run
  expect_says "$1" "$4"
}
batch_silent() {
  [ -z "$3" ] || assistant "$3" >> "$2"
  input "$2" "$4" | run
  expect_silent "$1"
}

echo "-- marks, main"
t=$tmp/main.jsonl
batch_silent "699,999: silent" "$t" 699999
expect_state "699,999: no state written" "$t" absent
batch_says "700,000 exactly: the main 700 K message" "$t" 700000 "$MAIN_700"
expect_state "700,000: state 700" "$t" 700
batch_silent "a second batch at the same figure: silent" "$t" ""
batch_silent "799,999: silent" "$t" 799999
batch_says "800,000 exactly: the main 800 K message" "$t" 800000 "$MAIN_800"
expect_state "800,000: state 800" "$t" 800
batch_silent "a second batch past 800 K: silent" "$t" 950000

echo "-- a jump past both"
t=$tmp/jump.jsonl
batch_says "first reading 900,000: the 800 K message alone" "$t" 900000 "$MAIN_800"
batch_silent "falling to 750,000: 700 K never after" "$t" 750000
batch_silent "750,000 again: silent" "$t" 750000

echo "-- a drop below 700 K"
t=$tmp/drop.jsonl
batch_says "crossing" "$t" 720000 "$MAIN_700"
batch_silent "compacted to 200,000: silent" "$t" 200000
expect_state "compacted: state removed" "$t" absent
batch_says "a new crossing speaks" "$t" 710000 "$MAIN_700"
batch_says "and 800 K again" "$t" 810000 "$MAIN_800"
batch_silent "compacted past both: silent" "$t" 100000
batch_says "a jump after compacting" "$t" 900000 "$MAIN_800"

echo "-- workers"
t=$tmp/w.jsonl
mkdir -p "$tmp/w/subagents/workflows/wf_x" "$tmp/w/subagents/other"
assistant 100 > "$t"
w=$tmp/w/subagents/agent-a1.jsonl
assistant 750000 > "$t"
assistant 100 > "$w"
input "$t" a1 | run
expect_silent "a worker below the mark, its main above: silent"
expect_state "and neither has state" "$t" absent
assistant 100 > "$t"
assistant 650000 > "$w"
input "$t" a1 | run
expect_silent "a worker at 650,000: silent"
assistant 700001 >> "$w"
input "$t" a1 | run
expect_says "a worker at 700 K under subagents/: worker wording" "$WORKER_700"
expect_state "its state sits beside its own transcript" "$w" 700
expect_state "its main session has none" "$t" absent
input "$t" a1 | run
expect_silent "a worker's second batch: silent"
assistant 800000 >> "$w"
input "$t" a1 | run
expect_says "a worker at 800 K: worker wording" "$WORKER_800"
input "$t" a1 | run
expect_silent "a worker's second batch past 800 K: silent"
batch_silent "the main session below the mark while its worker is past: silent" "$t" ""
wf=$tmp/w/subagents/workflows/wf_x/agent-a2.jsonl
assistant 720000 > "$wf"
input "$t" a2 | run
expect_says "under subagents/workflows/wf_x/: worker wording" "$WORKER_700"
expect_state "under wf_x: state beside it" "$wf" 700
one=$tmp/w/subagents/other/agent-a3.jsonl
assistant 820000 > "$one"
input "$t" a3 | run
expect_says "one level under subagents/: worker wording" "$WORKER_800"
input "$t" nobody | run
expect_silent "an agent_id with no file anywhere: silent"
input "$t" '' | run
expect_silent "a main session below the mark after all that: silent"

echo "-- whose keys count"
t=$tmp/keys.jsonl
assistant 720000 > "$t"
input "$t" "" "" '[{"tool_name":"Read","tool_input":{"agent_id":"a1"},"tool_use_id":"t1","tool_response":"\"agent_id\":\"a1\" and \"transcript_path\":\"/nowhere\""}]' | run
expect_says "agent_id only inside tool_calls: stays main" "$MAIN_700"
rm -f "$t.headsup"
input "$t" "" ',"agent_type":"Explore"' | run
expect_says "agent_type alone, an --agent main thread: main wording" "$MAIN_700"
printf '{"session_id":"s","hook_event_name":"PostToolBatch","tool_calls":[{"transcript_path":"%s"}]}\n' "$t" | run
expect_silent "transcript_path only inside tool_calls: silent"

echo "-- what is not a reading"
t=$tmp/lines.jsonl
assistant 100 > "$t"
printf '{"type":"user","message":{"role":"user","content":"x"},"toolUseResult":{"usage":{"input_tokens":900000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}},"uuid":"u"}\n' >> "$t"
input "$t" | run
expect_silent "a user line's usage: ignored"
assistant 720000 > "$t"
synthetic >> "$t"
input "$t" | run
expect_says "a synthetic line after a real one: ignored" "$MAIN_700"
rm -f "$t.headsup"
assistant 720000 > "$t"
zero_usage >> "$t"
input "$t" | run
expect_says "a zero usage after a real one: ignored" "$MAIN_700"
assistant 100 > "$t"
input "$t" | run
expect_silent "falling back under the mark clears the state"
assistant 100 '{"type":"tool_use","id":"t","name":"m","input":{"usage":{"input_tokens":900000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}' > "$t"
input "$t" | run
expect_silent "a tool_use input shaped like usage, ahead of the real one: ignored"
assistant 720000 '{"type":"tool_use","id":"t","name":"m","input":{"usage":{"input_tokens":1,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}}}' > "$t"
input "$t" | run
expect_says "a small one ahead of a real 720,000: the real one reads" "$MAIN_700"
rm -f "$t.headsup"
assistant 100 '{"type":"text","text":"\"type\":\"assistant\",\"uuid\":\"u\" \"usage\":{\"input_tokens\":900000,\"cache_creation_input_tokens\":0,\"cache_read_input_tokens\":0"}' > "$t"
printf '{"type":"user","message":{"content":"\\"type\\":\\"assistant\\",\\"uuid\\":\\"u\\",\\"usage\\":{\\"input_tokens\\":900000,\\"cache_creation_input_tokens\\":0,\\"cache_read_input_tokens\\":0"}}\n' >> "$t"
input "$t" | run
expect_silent "the shape quoted inside text: ignored"
assistant 300000 > "$t"
assistant 720000 >> "$t"
assistant 300000 >> "$t"
input "$t" | run
expect_silent "only the last reading counts"

echo "-- no reading in the tail"
t=$tmp/tail.jsonl
: > "$t"
input "$t" | run
expect_silent "an empty transcript: silent"
assistant 720000 > "$t"
awk 'BEGIN { for (i = 0; i < 25; i++) { s = ""; for (j = 0; j < 400; j++) s = s "0123456789"; printf "{\"type\":\"user\",\"toolUseResult\":\"%s\"}\n", s } }' >> "$t"
input "$t" | run
expect_says "100 KB of tool results after the reading: it still reads" "$MAIN_700"
assistant 720000 > "$t"
awk 'BEGIN { for (i = 0; i < 40; i++) { s = ""; for (j = 0; j < 400; j++) s = s "0123456789"; printf "{\"type\":\"user\",\"toolUseResult\":\"%s\"}\n", s } }' >> "$t"
input "$t" | run
expect_silent "128 KiB of tool results after the last reading: silent"
expect_state "and the state stands" "$t" 700
assistant 720000 >> "$t"
input "$t" | run
expect_silent "the next reading, still past: no second message"
t=$tmp/tail2.jsonl
awk 'BEGIN { s = ""; for (j = 0; j < 14000; j++) s = s "0123456789"; printf "{\"message\":{\"content\":\"%s\",\"usage\":{\"input_tokens\":1,\"cache_creation_input_tokens\":0,\"cache_read_input_tokens\":720000}},\"type\":\"assistant\",\"uuid\":\"u\"}\n", s }' > "$t"
input "$t" | run
expect_says "a line longer than the tail, cut at its head: still reads" "$MAIN_700"
t=$tmp/tail3.jsonl
assistant 720000 | awk '{ print substr($0, 1, length($0) - 200) }' > "$t"
input "$t" | run
expect_silent "a line still being written, its marker not yet there: silent"

echo "-- no transcript, bad input"
input "$tmp/absent.jsonl" | run
expect_silent "no file at the path"
expect_state "and no state" "$tmp/absent.jsonl" absent
printf '{"session_id":"s","cwd":"/w","hook_event_name":"PostToolBatch","tool_calls":[]}\n' | run
expect_silent "no transcript_path"
input "" | run
expect_silent "an empty transcript_path"
mkdir "$tmp/dir.jsonl"
input "$tmp/dir.jsonl" | run
expect_silent "a directory at the path"
run < /dev/null
expect_silent "empty stdin"
printf 'not json at all\n' | run
expect_silent "not JSON"
head -c 8192 /dev/urandom | run
expect_silent "binary"
assistant 720000 > "$tmp/malformed.jsonl"
printf '{"transcript_path":"%s"' "$tmp/malformed.jsonl" | run
expect_silent "truncated before hook_event_name"
printf '{"transcript_path":"%s' "$tmp/malformed.jsonl" | run
expect_silent "truncated inside the path"
printf '{"transcript_path":null,"hook_event_name":"PostToolBatch"}' | run
expect_silent "a null transcript_path"
expect_state "bad input wrote nothing" "$tmp/malformed.jsonl" absent
if [ "$(id -u)" -ne 0 ]; then
  t=$tmp/unreadable.jsonl
  assistant 720000 > "$t"
  chmod 000 "$t"
  input "$t" | run
  expect_silent "an unreadable transcript: silent"
  expect_state "and no state" "$t" absent
  chmod 600 "$t"
  mkdir "$tmp/readonly"
  t=$tmp/readonly/r.jsonl
  assistant 720000 > "$t"
  chmod 555 "$tmp/readonly"
  input "$t" | run
  code=$(cat "$tmp/code")
  if [ "$code" -eq 1 ] && [ ! -s "$tmp/out" ]; then ok "a state that cannot be written: exit 1, no message"; else fail "unwritable state: exit $code, printed $(cat "$tmp/out")"; fi
  input "$t" | run
  code=$(cat "$tmp/code")
  if [ "$code" -eq 1 ] && [ ! -s "$tmp/out" ]; then ok "and no message on the next batch"; else fail "unwritable state, next batch: exit $code, printed $(cat "$tmp/out")"; fi
  chmod 755 "$tmp/readonly"
else
  echo "info unreadable and unwritable cases skipped as root"
fi

echo "-- a damaged state"
t=$tmp/damaged.jsonl
assistant 720000 > "$t"
: > "$t.headsup"
input "$t" | run
expect_says "an empty state speaks" "$MAIN_700"
expect_state "and is written whole" "$t" 700
printf 'junk' > "$t.headsup"
input "$t" | run
expect_says "a junk state speaks" "$MAIN_700"
expect_state "and is written whole" "$t" 700

echo "-- odd paths, a large stdin"
mkdir -p "$tmp/a b [c] *d/s1/subagents/workflows/wf_1"
t="$tmp/a b [c] *d/s1.jsonl"
assistant 720000 > "$t"
input "$t" | run
expect_says "spaces and glob characters in the path, main" "$MAIN_700"
assistant 720000 > "$tmp/a b [c] *d/s1/subagents/workflows/wf_1/agent-q.jsonl"
input "$t" q | run
expect_says "and a worker under them" "$WORKER_700"
t=$tmp/large.jsonl
assistant 720000 > "$t"
{ printf '{"session_id":"s","transcript_path":"%s","hook_event_name":"PostToolBatch","tool_calls":[{"tool_response":"' "$t"; head -c 4000000 /dev/zero | tr '\0' 'x'; printf '"}]}\n'; } | run
expect_says "4 MB of tool_calls on stdin" "$MAIN_700"

echo "-- concurrent agents"
t=$tmp/parallel.jsonl
assistant 100 > "$t"
mkdir -p "$tmp/parallel/subagents"
i=0
while [ "$i" -lt 40 ]; do
  assistant 720000 > "$tmp/parallel/subagents/agent-p$i.jsonl"
  input "$t" "p$i" > "$tmp/parallel/in$i"
  i=$((i + 1))
done
i=0
while [ "$i" -lt 40 ]; do
  sh "$hook" < "$tmp/parallel/in$i" > "$tmp/parallel/out$i" 2>&1 &
  i=$((i + 1))
done
wait
spoke=0 i=0
while [ "$i" -lt 40 ]; do
  [ "$(jq -r .hookSpecificOutput.additionalContext "$tmp/parallel/out$i" 2>&1)" = "$WORKER_700" ] && spoke=$((spoke + 1))
  i=$((i + 1))
done
if [ "$spoke" -eq 40 ]; then ok "40 workers at once: each told once"; else fail "40 workers at once: $spoke told"; fi
i=0
while [ "$i" -lt 40 ]; do
  sh "$hook" < "$tmp/parallel/in$i" >> "$tmp/parallel/again" 2>&1 &
  i=$((i + 1))
done
wait
if [ ! -s "$tmp/parallel/again" ]; then ok "and silent on the next batch"; else fail "40 workers at once spoke again"; fi

echo "-- a real transcript"
# The test's own reader, by keys and not by position: when the two disagree the transcript's shape has moved,
# and the hook would go dark with no other sign.
root=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects
newest=$tmp/newest
[ -d "$root" ] && find "$root" -type f -name '*.jsonl' -mtime -30 -exec ls -t {} + 2>/dev/null | head -n 50 > "$newest"
if [ -s "$newest" ]; then
  figure=0
  while IFS= read -r real; do
    tail -c 131072 "$real" | jq -Rr 'select((fromjson? // null) != null)' > "$tmp/real.jsonl"
    figure=$(jq -n 'reduce (inputs | select(.type == "assistant" and .message.model != "<synthetic>") | .message.usage | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)) as $u (0; if $u > 0 then $u else . end)' "$tmp/real.jsonl")
    [ "$figure" -gt 0 ] && break
  done < "$newest"
  if [ "$figure" -gt 0 ]; then
    sed -e "s/700000/$figure/" -e "s/800000/$((figure + 1000000))/" "$hook" > "$tmp/at-figure.sh"
    sed -e "s/700000/$((figure + 1))/" -e "s/800000/$((figure + 1000000))/" "$hook" > "$tmp/above-figure.sh"
    input "$tmp/real.jsonl" > "$tmp/in"
    sh "$tmp/at-figure.sh" < "$tmp/in" > "$tmp/out" 2> "$tmp/err"
    echo $? > "$tmp/code"
    expect_says "the hook reads a real line's figure" "$MAIN_700"
    rm -f "$tmp/real.jsonl.headsup"
    sh "$tmp/above-figure.sh" < "$tmp/in" > "$tmp/out" 2> "$tmp/err"
    echo $? > "$tmp/code"
    expect_silent "and reads no more than it"
  else
    fail "none of the newest 50 transcripts holds an assistant line with usage: the transcript's shape has moved"
  fi
else
  echo "info no transcript under $root in 30 days: real-shape case skipped"
fi

echo "passed $passed, failed $failed"
[ "$failed" -eq 0 ]
