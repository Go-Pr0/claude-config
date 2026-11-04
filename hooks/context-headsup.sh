#!/bin/sh
# PostToolBatch: tells an agent, once per crossing, that its context has passed a mark.
# Runs on every tool-bearing message of every agent, so the silent path forks only head, tail and awk.
# Only ever a message: never exit 2, a `decision` or a `continue`, and never the figure read.
LC_ALL=C; export LC_ALL

# The common fields precede hook_event_name; tool_calls follows it, can run to megabytes and can hold any key.
input=$(head -c 4096)
common=${input%%\"hook_event_name\"*}
[ "$common" != "$input" ] || exit 0
case $common in *'"transcript_path":"'*) ;; *) exit 0 ;; esac
transcript=${common#*\"transcript_path\":\"}; transcript=${transcript%%\"*}

# A subagent's input names its main session's transcript; its own sits under that, deeper for a workflow's.
case $common in
*'"agent_id":"'*)
  agent=${common#*\"agent_id\":\"}; agent=${agent%%\"*}
  subagents=${transcript%.jsonl}/subagents
  transcript=$subagents/agent-$agent.jsonl
  [ -f "$transcript" ] || for found in "$subagents"/*/"agent-$agent.jsonl" "$subagents"/*/*/"agent-$agent.jsonl"; do
    [ -f "$found" ] && { transcript=$found; break; }
  done
  who=worker ;;
*) who=main ;;
esac
[ -f "$transcript" ] || exit 0

# 128 KiB holds nearly every gap from the last assistant line to the next request; a miss delays the message by one batch.
# The greedy match takes the line's last usage, since a tool_use input ahead of the real one can hold an object of that shape.
context=$(tail -c 131072 "$transcript" 2>/dev/null | awk '
  index($0, "\"type\":\"assistant\",\"uuid\":\"") &&
  match($0, /.*"usage":\{"input_tokens":[0-9]+,"cache_creation_input_tokens":[0-9]+,"cache_read_input_tokens":[0-9]+/) {
    k = split(substr($0, RSTART, RLENGTH), f, /[:,]/)
    sum = f[k] + f[k - 2] + f[k - 4]
    if (sum > 0) context = sum
  }
  END { if (context) print context }')

# A tail of tool results alone says nothing about context, so the state stands and the next batch reads it.
[ -n "$context" ] || exit 0

# Beside the transcript, and invisible to Claude Code's own listing of sessions, which filters on .jsonl.
state=$transcript.headsup

# Below the first mark /compact has shrunk the context, so a later crossing speaks again.
if [ "$context" -lt 700000 ]; then
  [ -e "$state" ] && rm -f "$state"
  exit 0
fi

if [ "$context" -ge 800000 ]; then level=800; else level=700; fi
said=
[ -f "$state" ] && read -r said < "$state"
case $level$said in 700700 | 700800 | 800800) exit 0 ;; esac

# Written before printing: a state that cannot be written would otherwise repeat the message every batch.
printf '%s\n' "$level" > "$state" || exit 1

case $who$level in
main700) message='Context heads-up: this session has passed 700 K tokens of context, and every further turn re-sends all of it. Start nothing new: no new plan, no wave or task not yet begun. Keep going on what is under way: harvest what returns and dispatch the fixes it needs. When nothing is in flight, read `~/.claude/skills/handoff/SKILL.md`, follow it, post the prompt it produces and end your turn: a fresh session takes over from that prompt. This overrides any instruction to keep going.' ;;
main800) message='Context heads-up: this session has passed 800 K tokens of context and should already have wrapped up. Spawn no more agents, fixes included. Let what is running return and record it, then read `~/.claude/skills/handoff/SKILL.md`, follow it, post the prompt it produces and end your turn: a fresh session takes over from that prompt and carries everything unfinished. This overrides any instruction to keep going.' ;;
worker700) message='Context heads-up: you have passed 700 K tokens of context, and every further turn re-sends all of it. Take on nothing new. Finish the step you are on, leave your work clean (landed, or in a state another worker can pick up) and return soon, saying what is done, what is left, and that what is left needs a fresh worker. This overrides any instruction to finish everything first.' ;;
worker800) message='Context heads-up: you have passed 800 K tokens of context and should already have returned. Start no further step: leave things clean and return now, saying what is done, what is left, any run of yours still alive, and that what is left needs a fresh worker. This overrides any instruction to finish everything first.' ;;
esac
printf '{"hookSpecificOutput":{"hookEventName":"PostToolBatch","additionalContext":"%s"}}\n' "$message"
