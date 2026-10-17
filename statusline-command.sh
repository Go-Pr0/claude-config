#!/bin/bash

input=$(cat)

IFS=$'\t' read -r model project_dir ctx_size ctx_pct h5_pct h5_reset d7_pct cost session_name <<<"$(echo "$input" | jq -r '[
    .model.display_name // "Claude",
    .workspace.project_dir // "",
    .context_window.context_window_size // 200000,
    .context_window.used_percentage // 0,
    .rate_limits.five_hour.used_percentage // "",
    .rate_limits.five_hour.resets_at // "",
    .rate_limits.seven_day.used_percentage // "",
    .cost.total_cost_usd // 0,
    .session_name // ""
] | @tsv')"

CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; WHITE=$'\033[37m'
DIM=$'\033[90m'; RESET=$'\033[0m'
SEP=" ${DIM}|${RESET} "

branch="no-git"
if [ -n "$project_dir" ] && [ -d "$project_dir/.git" ]; then
    branch=$(git -C "$project_dir" --no-optional-locks branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch="detached"
fi
common_dir="$project_dir/services/common"
if [ -n "$project_dir" ] && [ -d "$common_dir/.git" ]; then
    common_branch=$(git -C "$common_dir" --no-optional-locks branch --show-current 2>/dev/null)
    [ -n "$common_branch" ] && branch="$branch common:$common_branch"
fi

format_tokens() {
    local t=$1
    if [ "$t" -ge 1000000 ]; then
        if [ $((t % 1000000)) -eq 0 ]; then echo "$((t / 1000000))M"; else awk -v t="$t" 'BEGIN { printf "%.1fM", t / 1000000 }'; fi
    elif [ "$t" -ge 1000 ]; then
        echo "$((t / 1000))K"
    else
        echo "$t"
    fi
}

# bar <percent> <width> <filled char> <empty char>
bar() {
    local filled=$(( ($1 * $2 + 50) / 100 )) out="" i
    [ "$filled" -gt "$2" ] && filled=$2
    out="$GREEN"
    for ((i = 0; i < filled; i++)); do out+="$3"; done
    out+="$DIM"
    for ((i = filled; i < $2; i++)); do out+="$4"; done
    printf '%s%s' "$out" "$RESET"
}

ctx_pct=${ctx_pct%.*}
used_tokens=$(( ctx_size * ctx_pct / 100 ))
line="${CYAN}${model}${RESET} $(bar "$ctx_pct" 10 ● ○) ${DIM}$(format_tokens "$used_tokens")/$(format_tokens "$ctx_size") (${ctx_pct}%)${RESET}"

if [ -n "$h5_pct" ]; then
    h5_pct=${h5_pct%.*}
    line+="${SEP}${DIM}5H:${RESET} $(bar "$h5_pct" 8 ▬ ▬) ${WHITE}${h5_pct}%${RESET}"
    if [ -n "$h5_reset" ]; then
        left=$(( h5_reset - $(date +%s) ))
        [ "$left" -lt 0 ] && left=0
        line+=" ${DIM}$((left / 3600))H $((left % 3600 / 60))M${RESET}"
    fi
fi
if [ -n "$d7_pct" ]; then
    d7_pct=${d7_pct%.*}
    line+="${SEP}${DIM}7D:${RESET} $(bar "$d7_pct" 8 ▬ ▬) ${WHITE}${d7_pct}%${RESET}"
fi

line+="${SEP}${GREEN}${branch}${RESET}"
line+="${SEP}${YELLOW}\$$(printf '%.3f' "$cost")${RESET}"
tail_name=${session_name:-$(basename "$project_dir")}
[ -n "$tail_name" ] && line+="${SEP}${DIM}${tail_name}${RESET}"

printf '%s\n' "$line"
