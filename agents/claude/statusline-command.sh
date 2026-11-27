#!/bin/sh
# Claude Code statusLine command

input=$(cat)

# --- model ---
model=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

# --- git branch ---
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
git_branch=$(git -C "$current_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# --- rate limits ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
now=$(date +%s)

# helper: convert future unix epoch to relative string
rel_time() {
  resets_at="$1"
  if [ -z "$resets_at" ]; then
    echo ""
    return
  fi
  diff=$((resets_at - now))
  if [ "$diff" -le 0 ]; then
    echo "まもなく"
  elif [ "$diff" -lt 3600 ]; then
    mins=$(( (diff + 59) / 60 ))
    echo "あと${mins}m"
  elif [ "$diff" -lt 86400 ]; then
    hrs=$(awk "BEGIN { printf \"%.1f\", $diff / 3600 }")
    echo "あと${hrs}h"
  else
    days=$(awk "BEGIN { printf \"%.1f\", $diff / 86400 }")
    echo "あと${days}d"
  fi
}

five_rel=$(rel_time "$five_resets")
week_rel=$(rel_time "$week_resets")

# --- assemble output ---
WHITE='\033[38;2;255;255;255m'
DIM='\033[38;2;120;120;120m'
RESET='\033[0m'
SEP="${DIM} - ${WHITE}"
out=""

# 🤖 model (effort)
if [ -n "$model" ]; then
  out="🤖${model}"
  [ -n "$effort" ] && out="${out}(${effort})"
fi

# 🔧 git branch
if [ -n "$git_branch" ]; then
  [ -n "$out" ] && out="${out}${SEP}"
  out="${out}🔧${git_branch}"
fi

# 🧠 context remaining
ctx_remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
if [ -n "$ctx_remaining" ]; then
  ctx_rem=$(printf "%.0f" "$ctx_remaining")
  [ -n "$out" ] && out="${out}${SEP}"
  out="${out}🧠${ctx_rem}%"
fi

# 🕰️ 5h rate limit
if [ -n "$five_pct" ]; then
  five_rem=$(printf "%.0f" "$(awk "BEGIN { print 100 - $five_pct }")")
  five_str="🕰️${five_rem}%残"
  [ -n "$five_rel" ] && five_str="${five_str} ${five_rel}"
  [ -n "$out" ] && out="${out}${SEP}"
  out="${out}${five_str}"
fi

# 📅 7d rate limit
if [ -n "$week_pct" ]; then
  week_rem=$(printf "%.0f" "$(awk "BEGIN { print 100 - $week_pct }")")
  week_str="📅${week_rem}%残"
  [ -n "$week_rel" ] && week_str="${week_str} ${week_rel}"
  [ -n "$out" ] && out="${out}${SEP}"
  out="${out}${week_str}"
fi

printf "%b" "${WHITE}${out}${RESET}"
