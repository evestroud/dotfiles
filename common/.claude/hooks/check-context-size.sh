#!/bin/bash
# check-context-size.sh — UserPromptSubmit hook.
#
# Catches the "left a long session open, came back later with something
# small and unrelated" habit. If a session's context is large AND it's been
# idle past the prompt-cache TTL (so the cache has likely gone cold), block
# the next prompt and ask whether to /clear or /compact — then stay quiet
# for that session for a cooldown period so it doesn't nag every turn.
#
# Lives in the dotfiles repo as common/.claude/hooks/check-context-size.sh and
# is stowed into ~/.claude/hooks/ — ~/.claude/ is per-device and does not sync
# on its own, so a new machine gets this by `git pull` plus
# `stow -t ~ common <host>`, not by hand-copying.
#
# The ~/.claude/settings.json half still has to be merged in per machine
# (Claude Code writes to that file, so it can't be a symlink):
#
#   "hooks": {
#     "UserPromptSubmit": [
#       { "hooks": [ { "type": "command",
#                      "command": "~/.claude/hooks/check-context-size.sh" } ] }
#     ]
#   }
#
# Requires jq. Without it, session_id comes back empty and the hook exits 0 —
# it fails silent, not loud, so a machine missing jq looks identical to one
# where the hook simply never fires.

# --- Tunable constants ---
CONTEXT_TOKEN_THRESHOLD=40000   # below this estimated token count, never nag
CACHE_TTL_SECONDS=3600          # 1 hour: the automatic TTL on any Claude subscription
                                 # (Pro/Max/Team/Enterprise) in Claude Code. Only bare
                                 # API-key/third-party usage gets the 5-minute default.
NAG_COOLDOWN_SECONDS=3600       # once nagged, stay quiet for this session for this long

STATE_DIR="${TMPDIR:-/tmp}/claude-cold-context-hook"
mkdir -p "$STATE_DIR" 2>/dev/null

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null)
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)

[ -z "$session_id" ] && exit 0

state_file="$STATE_DIR/$session_id"
now=$(date +%s)

# Estimate context size from transcript file size (~4 chars/token heuristic).
est_tokens=0
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  bytes=$(wc -c < "$transcript_path" 2>/dev/null || echo 0)
  est_tokens=$(( bytes / 4 ))
fi

last_seen=0
last_nag=0
if [ -f "$state_file" ]; then
  read -r last_seen last_nag < "$state_file" 2>/dev/null
fi
last_seen=${last_seen:-0}
last_nag=${last_nag:-0}

idle=$(( now - last_seen ))

# Only nag if: context is large, we've seen this session before (so "idle"
# is meaningful, not just session startup), the cache has actually gone
# cold, and the cooldown since the last nag has elapsed.
if [ "$est_tokens" -ge "$CONTEXT_TOKEN_THRESHOLD" ] && [ "$last_seen" -ne 0 ] \
   && [ "$idle" -ge "$CACHE_TTL_SECONDS" ] && [ $(( now - last_nag )) -ge "$NAG_COOLDOWN_SECONDS" ]; then
  echo "$now $now" > "$state_file"
  cat <<EOF
{"decision":"block","reason":"This session has roughly ${est_tokens} estimated tokens of context and has been idle ${idle}s, past the ~${CACHE_TTL_SECONDS}s prompt-cache TTL — the cache has likely gone cold. If this prompt is unrelated to the prior work, /clear first (cheap: it just drops the old conversation without resending it). If you want to keep working in this area and need the continuity, /compact instead — but note /compact still has to read the whole stale conversation once to build the summary, so it's not free the way /clear is. Resend your prompt to proceed once you've decided."}
EOF
  exit 0
fi

echo "$now $last_nag" > "$state_file"
exit 0
