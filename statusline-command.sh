#!/bin/bash

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // ""')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
used_percentage=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

branch="no-git"
if [ -n "$project_dir" ] && [ -d "$project_dir/.git" ]; then
    branch=$(git -C "$project_dir" --no-optional-locks branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch="detached"
fi

common_branch=""
common_dir="$project_dir/services/common"
if [ -n "$project_dir" ] && [ -d "$common_dir/.git" ]; then
    common_branch=$(git -C "$common_dir" --no-optional-locks branch --show-current 2>/dev/null)
fi

format_tokens() {
    local tokens=$1
    if [ $tokens -ge 1000000 ]; then
        printf "%.1fm" $(echo "scale=1; $tokens/1000000" | bc)
    elif [ $tokens -ge 1000 ]; then
        printf "%.0fk" $(echo "scale=0; $tokens/1000" | bc)
    else
        echo "${tokens}"
    fi
}

# Calculate used tokens from percentage
used_tokens=$(printf "%.0f" $(echo "scale=0; $context_size * $used_percentage / 100" | bc 2>/dev/null || echo "0"))
used_formatted=$(format_tokens $used_tokens)
max_formatted=$(format_tokens $context_size)

# Progress bar (20 chars)
filled=$(printf "%.0f" $(echo "scale=2; $used_percentage * 20 / 100" | bc 2>/dev/null || echo "0"))
[ $filled -gt 20 ] && filled=20
[ $filled -lt 0 ] && filled=0
empty=$((20 - filled))

bar=""
for ((i=0; i<filled; i++)); do bar="${bar}="; done
for ((i=0; i<empty; i++)); do bar="${bar}-"; done

percentage_str=$(printf "%.0f%%" "$used_percentage")

branch_display="$branch"
[ -n "$common_branch" ] && branch_display="$branch | common:$common_branch"

printf "\033[1;36m%s\033[0m \033[1;33m[%s]\033[0m \033[1;32m%s\033[0m | \033[1;35m%s/%s\033[0m | \033[1;34m%s\033[0m\n" \
    "$model" \
    "$bar" \
    "$percentage_str" \
    "$used_formatted" \
    "$max_formatted" \
    "$branch_display"
