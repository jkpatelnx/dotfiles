#!/bin/sh
input=$(cat)

# ── Raw data from Claude Code ─────────────────────────────────────────────────
model_name=$(echo "$input"      | jq -r '.model.display_name           // "Claude"')
model_id=$(echo "$input"        | jq -r '.model.id                     // empty')
ctx_size=$(echo "$input"        | jq -r '.context_window.context_window_size // 0')
used_pct=$(echo "$input"        | jq -r '.context_window.used_percentage     // empty')
total_in=$(echo "$input"        | jq -r '.context_window.total_input_tokens  // 0')
total_out=$(echo "$input"       | jq -r '.context_window.total_output_tokens // 0')
cwd=$(echo "$input"             | jq -r '.workspace.current_dir              // empty')
effort=$(echo "$input"          | jq -r '.effort.level                       // empty')
thinking=$(echo "$input"        | jq -r '.thinking.enabled                   // false')
rl_5h_pct=$(echo "$input"       | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_5h_reset=$(echo "$input"     | jq -r '.rate_limits.five_hour.resets_at       // empty')
rl_7d_pct=$(echo "$input"       | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_reset=$(echo "$input"     | jq -r '.rate_limits.seven_day.resets_at       // empty')
git_worktree=$(echo "$input"    | jq -r '.workspace.git_worktree               // empty')
version=$(echo "$input"         | jq -r '.version                             // empty')

# ── ANSI colours (work in dimmed terminal environment) ────────────────────────
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
MAGENTA='\033[35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Date / time ───────────────────────────────────────────────────────────────
datestamp=$(date "+%a %b %d")
timestamp=$(date "+%H:%M")

# ── Model + context window size label ─────────────────────────────────────────
ctx_label=""
if [ "$ctx_size" -ge 1000000 ] 2>/dev/null; then
  ctx_label="$(( ctx_size / 1000000 ))M"
elif [ "$ctx_size" -ge 1000 ] 2>/dev/null; then
  ctx_label="$(( ctx_size / 1000 ))K"
fi
[ -n "$ctx_label" ] && model_str="${model_name} [${ctx_label}]" || model_str="${model_name}"

# Append effort level when present
if [ -n "$effort" ]; then
  model_str="${model_str} effort:${effort}"
fi

# ── Context bar (width 20) ────────────────────────────────────────────────────
make_bar() {
  pct="$1"; width=20
  filled=$(( pct * width / 100 ))
  bar=""; i=0
  while [ $i -lt $filled ];  do bar="${bar}█"; i=$(( i + 1 )); done
  while [ $i -lt $width ];   do bar="${bar}░"; i=$(( i + 1 )); done
  printf "%s" "$bar"
}

if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  ctx_bar=$(make_bar "$used_int")
  # colour the bar by pressure
  if   [ "$used_int" -ge 85 ]; then bar_color="$RED"
  elif [ "$used_int" -ge 60 ]; then bar_color="$YELLOW"
  else                               bar_color="$GREEN"
  fi
  ctx_display=$(printf "${bar_color}[${ctx_bar}]${RESET} ${used_int}%%")
else
  # No data yet (session start) - show empty bar with "ready" label
  ctx_display="[$(make_bar 0)] ready"
fi

# ── Token count (input + output combined) ─────────────────────────────────────
total_tokens=$(( total_in + total_out ))

# Format token count human-readable
if [ "$total_tokens" -ge 1000 ] 2>/dev/null; then
  tok_display="$(( total_tokens / 1000 ))K"
else
  tok_display="$total_tokens"
fi

# ── Current directory (basename only, tilde for home) ─────────────────────────
if [ -n "$cwd" ]; then
  home_prefix="$HOME"
  case "$cwd" in
    "$home_prefix") dir_display="~" ;;
    "$home_prefix"/*) dir_display="~${cwd#$home_prefix}" ; dir_display=$(basename "$dir_display") ;;
    *) dir_display=$(basename "$cwd") ;;
  esac
  # Prefer repo root name when inside a git repo
  repo_root=$(cd "$cwd" 2>/dev/null && git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  [ -n "$repo_root" ] && dir_display=$(basename "$repo_root")
else
  dir_display=$(basename "$PWD")
fi

# ── Git branch + status ───────────────────────────────────────────────────────
git_str=""
repo_cwd="${cwd:-$PWD}"
if git -C "$repo_cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$repo_cwd" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$repo_cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  staged=$(git -C "$repo_cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git -C "$repo_cwd" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git -C "$repo_cwd" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  git_str="${branch}"
  [ "$staged"    -gt 0 ] && git_str="${git_str} ${GREEN}+${staged}${RESET}"
  [ "$modified"  -gt 0 ] && git_str="${git_str} ${YELLOW}~${modified}${RESET}"
  [ "$untracked" -gt 0 ] && git_str="${git_str} ${RED}?${untracked}${RESET}"
fi

# ── Rate-limit helper ─────────────────────────────────────────────────────────
format_rl() {
  pct="$1"; reset_ts="$2"; label="$3"
  [ -z "$pct" ] && return
  pct_int=$(printf "%.0f" "$pct")
  if   [ "$pct_int" -ge 90 ]; then rl_color="$RED"
  elif [ "$pct_int" -ge 70 ]; then rl_color="$YELLOW"
  else                              rl_color="$GREEN"
  fi
  # Time remaining until reset
  now=$(date +%s)
  if [ -n "$reset_ts" ] && [ "$reset_ts" -gt "$now" ] 2>/dev/null; then
    secs_left=$(( reset_ts - now ))
    mins_left=$(( secs_left / 60 ))
    if [ "$mins_left" -ge 60 ]; then
      hrs=$(( mins_left / 60 )); mins=$(( mins_left % 60 ))
      time_str=$(printf "%dh%02dm" "$hrs" "$mins")
    else
      time_str="${mins_left}m"
    fi
    reset_str="resets in ${time_str}"
  else
    reset_str=""
  fi
  rl_bar=$(make_bar "$pct_int")
  if [ -n "$reset_str" ]; then
    printf "${rl_color}${label} [${rl_bar}] ${pct_int}%% (${reset_str})${RESET}"
  else
    printf "${rl_color}${label} [${rl_bar}] ${pct_int}%%${RESET}"
  fi
}

# ── Thinking indicator ────────────────────────────────────────────────────────
thinking_str=""
[ "$thinking" = "true" ] && thinking_str=" 💡"

# ── Worktree indicator ────────────────────────────────────────────────────────
worktree_str=""
[ -n "$git_worktree" ] && worktree_str=" | wt:${git_worktree}"

# ── Assemble rate-limit line (only shown when data is available) ───────────────
rl_5h_str=$(format_rl "$rl_5h_pct" "$rl_5h_reset" "5h-limit")
rl_7d_str=$(format_rl "$rl_7d_pct" "$rl_7d_reset" "7d-limit")

# ── Build output ──────────────────────────────────────────────────────────────
# Line 1: Date | Model | Context bar | Tokens | Directory | Git
line1=""
printf -v line1 \
  "${CYAN}%s %s${RESET} | ${BOLD}${MAGENTA}%s${RESET}%s | %b | Tokens: ${BLUE}%s${RESET} | 📁 ${BOLD}%s${RESET}" \
  "$datestamp" "$timestamp" \
  "$model_str" \
  "$thinking_str" \
  "$ctx_display" \
  "$tok_display" \
  "$dir_display"

# Append git info when available
if [ -n "$git_str" ]; then
  line1="${line1} | 🌿 $(printf "${CYAN}%b${RESET}" "$git_str")"
fi
line1="${line1}${worktree_str}"

# Line 2: Rate-limit meters (console/Pro subscription)
line2=""
if [ -n "$rl_5h_str" ] && [ -n "$rl_7d_str" ]; then
  line2=$(printf "Rate Limits: %b  |  %b" "$rl_5h_str" "$rl_7d_str")
elif [ -n "$rl_5h_str" ]; then
  line2=$(printf "Rate Limits: %b" "$rl_5h_str")
elif [ -n "$rl_7d_str" ]; then
  line2=$(printf "Rate Limits: %b" "$rl_7d_str")
else
  line2=$(printf "${DIM}Rate Limits: awaiting first response...${RESET}")
fi

# ── Print ─────────────────────────────────────────────────────────────────────
printf "%b" "$line1"
if [ -n "$line2" ]; then
  printf "\n%b" "$line2"
fi
printf "\n"