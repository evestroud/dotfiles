#!/usr/bin/env bash
# Claude Code statusLine, built to mirror the user's starship prompt
# (~/.config/starship.toml only overrides icons/symbols there; it sets no
# custom `format`, so starship's default module set/order/colors apply).
#
# Replicated here: directory (contracted, truncated to 3 components,
# read-only marker), git_branch, git_status (ahead/behind, staged/
# modified/untracked/conflicted/stashed counts) -- using starship's
# default colors (directory = bold cyan, git_branch = bold purple,
# git_status = bold red) and the symbols this user's starship.toml
# overrides (git_branch's " ", directory's read-only " 󰌾").
#
# Skipped (starship defaults that don't make sense / aren't derivable
# in a Claude Code statusLine, rather than a real interactive shell):
#   - username/hostname/localip: starship only shows these for SSH
#     sessions or root; not meaningful here.
#   - every per-language module (python, nodejs, rust, golang, java,
#     ...): each is conditional on starship's own project-file
#     detection for that language; not practical to reimplement here
#     for the full module list, and this session isn't a language repo.
#   - cloud/env modules (aws, gcloud, azure, kubernetes, docker_context,
#     nix_shell, conda, direnv, container, netns): tied to shell env
#     state (assumed roles, activated shells) this script doesn't have.
#   - system modules (battery, memory_usage, shlvl, sudo, os, jobs,
#     cmd_duration, time): not meaningful, or not exposed by the
#     statusLine JSON.
#   - character (the trailing $/❯ colored by last exit code): there's
#     no shell command / exit code in Claude Code's statusLine context.
#   - git_commit/git_state/git_metrics/hg_branch/fossil_branch/
#     pijul_channel/vcsh: alternate-VCS or commit-detail modules, not
#     relevant to a plain git-status line.
#
# Addition beyond starship: a right-aligned "Context usage: NN.Nk tokens"
# segment from the statusLine JSON's context_window (green/yellow/red at
# <50% / 50-79% / >=80% of the window).

input=$(cat)
# python3 rather than jq: jq isn't installed on every machine.
# Tokens in context = the current request's input side (uncached +
# cache-write + cache-read); total_input_tokens is cumulative, not current.
{ IFS= read -r dir; IFS= read -r used; IFS= read -r ctx_k; } < <(printf '%s' "$input" | python3 -c '
import json, sys
d = json.load(sys.stdin)
print((d.get("workspace") or {}).get("current_dir") or d.get("cwd") or "")
cw = d.get("context_window") or {}
u = cw.get("used_percentage")
print("" if u is None else u)
cu = cw.get("current_usage")
if cu:
    n = sum(cu.get(k) or 0 for k in ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))
    print(f"{n/1000:.1f}")
else:
    print("")
')
[ -n "$dir" ] || dir="$PWD"

RESET='\033[0m'
BOLD_CYAN='\033[1;36m'
BOLD_PURPLE='\033[1;35m'
BOLD_RED='\033[1;31m'
DIM='\033[2m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'

# --- directory module ---
disp="$dir"
case "$disp" in
  "$HOME") disp="~" ;;
  "$HOME"/*) disp="~${disp#$HOME}" ;;
esac
IFS='/' read -ra parts <<< "$disp"
clean=()
for p in "${parts[@]}"; do
  [ -n "$p" ] && clean+=("$p")
done
n=${#clean[@]}
if [ "$n" -gt 3 ]; then
  trunc="…/${clean[$((n-3))]}/${clean[$((n-2))]}/${clean[$((n-1))]}"
else
  trunc="$disp"
fi
PLAIN_RED='\033[31m'
read_only=""
[ -w "$dir" ] || read_only=" 󰌾"
dir_seg="${BOLD_CYAN}${trunc}${RESET}${PLAIN_RED}${read_only}${RESET}"

# --- git_branch / git_status modules ---
git_seg=""
if git -C "$dir" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  branch_seg="${BOLD_PURPLE} ${branch}${RESET}"

  ahead=0
  behind=0
  staged=0
  modified=0
  untracked=0
  conflicted=0
  while IFS= read -r line; do
    case "$line" in
      "# branch.ab "*)
        set -- $line
        ahead="${3#+}"
        behind="${4#-}"
        ;;
      "1 "*|"2 "*)
        xy="${line:2:2}"
        x="${xy:0:1}"
        y="${xy:1:1}"
        [ "$x" != "." ] && staged=$((staged+1))
        [ "$y" != "." ] && modified=$((modified+1))
        ;;
      "u "*)
        conflicted=$((conflicted+1))
        ;;
      "? "*)
        untracked=$((untracked+1))
        ;;
    esac
  done <<< "$(git -C "$dir" --no-optional-locks status --porcelain=2 --branch 2>/dev/null)"
  stashed=$(git -C "$dir" --no-optional-locks stash list 2>/dev/null | wc -l | tr -d ' ')

  status_str=""
  [ "$conflicted" -gt 0 ] && status_str="${status_str}=${conflicted}"
  [ "${stashed:-0}" -gt 0 ] && status_str="${status_str}\$${stashed}"
  [ "$modified" -gt 0 ] && status_str="${status_str}!${modified}"
  [ "$staged" -gt 0 ] && status_str="${status_str}+${staged}"
  [ "$untracked" -gt 0 ] && status_str="${status_str}?${untracked}"
  [ "${ahead:-0}" -gt 0 ] && status_str="${status_str}⇡${ahead}"
  [ "${behind:-0}" -gt 0 ] && status_str="${status_str}⇣${behind}"

  status_seg=""
  [ -n "$status_str" ] && status_seg=" ${BOLD_RED}[${status_str}]${RESET}"

  git_seg=" ${branch_seg}${status_seg}"
fi

# --- context-window usage (Claude Code addition, not part of starship) ---
ctx_seg=""
if [ -n "$ctx_k" ]; then
  pct=$(printf '%.0f' "${used:-0}")
  if [ "$pct" -ge 80 ]; then
    ctx_color="$RED"
  elif [ "$pct" -ge 50 ]; then
    ctx_color="$YELLOW"
  else
    ctx_color="$GREEN"
  fi
  ctx_seg="${DIM}Context usage:${RESET} ${ctx_color}${ctx_k}k tokens${RESET}"
fi

# Right-align the context segment: Claude Code sets COLUMNS for the command.
# Visible width = text with ANSI escapes stripped (bash counts UTF-8 chars;
# the nerd-font glyphs are one cell each). MARGIN leaves room for Claude
# Code's own padding so the line never wraps.
left=$(printf "%b" "${dir_seg}${git_seg}")
right=$(printf "%b" "${ctx_seg}")
visible() { local s; s=$(printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g'); echo "${#s}"; }
MARGIN=4
gap=2
if [ -n "$right" ] && [ -n "$COLUMNS" ]; then
  pad=$(( COLUMNS - MARGIN - $(visible "$left") - $(visible "$right") ))
  [ "$pad" -gt "$gap" ] && gap=$pad
fi
[ -n "$right" ] && printf '%s%*s%s' "$left" "$gap" "" "$right" || printf '%s' "$left"
