#!/bin/sh
# usage: triage.sh --summary "<banner text>" [--plan-file <path>]
#        echo "$plan" | triage.sh --summary "3 PRs, 1 CI red"
#
# Saves a triage action plan to $OPENCLAW_TRIAGE_DIR (default
# ~/.openclaw/triage/), updates a `latest` symlink, fires a macOS
# notification with the short summary, and echoes the full plan to stdout for
# the caller to relay.
#
# Filename convention:
#   Default (no $OPENCLAW_DENDRON_PREFIX):  YYYY-MM-DD.md
#   Dendron ($OPENCLAW_DENDRON_PREFIX set): <prefix>.YYYY.MM.DD.md
#     e.g. OPENCLAW_DENDRON_PREFIX=work.triage → work.triage.2026.05.22.md
#
# If terminal-notifier is installed, clicking the banner opens today's file.
# If $OPENCLAW_OBSIDIAN_VAULT + $OPENCLAW_OBSIDIAN_VAULT_PATH are set and the
# file lives inside the vault, the click opens the note in Obsidian instead.
set -eu

summary=""
plan_file=""
while [ $# -gt 0 ]; do
    case "$1" in
        --summary)
            shift
            [ $# -gt 0 ] || { echo "error: --summary requires a value" >&2; exit 2; }
            summary="$1"
            ;;
        --summary=*)
            summary="${1#--summary=}"
            ;;
        --plan-file)
            shift
            [ $# -gt 0 ] || { echo "error: --plan-file requires a value" >&2; exit 2; }
            plan_file="$1"
            ;;
        --plan-file=*)
            plan_file="${1#--plan-file=}"
            ;;
        -h|--help)
            echo "usage: $0 --summary \"<banner text>\" [--plan-file <path>]"
            echo "       (or pipe the plan body on stdin)"
            exit 0
            ;;
        *)
            echo "error: unknown argument: $1" >&2
            exit 2
            ;;
    esac
    shift
done

if [ -z "$summary" ]; then
    echo "error: --summary is required" >&2
    exit 2
fi

# Load the plan body — from --plan-file if given, otherwise stdin.
if [ -n "$plan_file" ]; then
    [ -r "$plan_file" ] || { echo "error: cannot read plan file: $plan_file" >&2; exit 2; }
    plan=$(cat "$plan_file")
else
    if [ -t 0 ]; then
        echo "error: no plan provided — pipe it on stdin or pass --plan-file" >&2
        exit 2
    fi
    plan=$(cat)
fi

if [ -z "$plan" ]; then
    echo "error: plan body is empty" >&2
    exit 2
fi

# Soft word-count check. Warn but don't fail — the agent may have a reason.
word_count=$(printf '%s' "$plan" | wc -w | tr -d ' ')
if [ "$word_count" -lt 200 ] || [ "$word_count" -gt 400 ]; then
    echo "warning: plan is ${word_count} words (target 300, range 200–400)" >&2
fi

triage_dir="${OPENCLAW_TRIAGE_DIR:-$HOME/.openclaw/triage}"
mkdir -p "$triage_dir"

# Dendron uses dot-separated hierarchy and dot-delimited dates.
# Plain mode keeps the previous YYYY-MM-DD.md format.
dendron_prefix="${OPENCLAW_DENDRON_PREFIX:-}"
if [ -n "$dendron_prefix" ]; then
    today=$(date +%Y.%m.%d)
    out_file="${triage_dir}/${dendron_prefix}.${today}.md"
    latest_link="${triage_dir}/${dendron_prefix}.latest.md"
else
    today=$(date +%Y-%m-%d)
    out_file="${triage_dir}/${today}.md"
    latest_link="${triage_dir}/latest.md"
fi

printf '%s\n' "$plan" > "$out_file"

# Refresh the latest symlink. rm-then-ln avoids stale-dir-symlink edge case on macOS.
rm -f "$latest_link"
ln -s "$out_file" "$latest_link"

# Banner — title fixed, body = summary. Truncate hard at 240 chars so macOS
# doesn't silently drop the notification.
banner=$(printf '%s' "$summary" | cut -c1-240)

# Build the click action. Preference order:
#   1. If OPENCLAW_OBSIDIAN_VAULT and OPENCLAW_OBSIDIAN_VAULT_PATH are set, and
#      the saved file lives inside the vault, open it via obsidian:// so it
#      lands in the user's vault rather than the default markdown app.
#   2. Otherwise, plain `open <file>`.
# Spaces are the only realistic offenders in vault names / triage paths, so a
# single sed pass is enough — document the assumption in SETUP.md.
click_action="open '$out_file'"
if [ -n "${OPENCLAW_OBSIDIAN_VAULT:-}" ] && [ -n "${OPENCLAW_OBSIDIAN_VAULT_PATH:-}" ]; then
    case "$out_file" in
        "$OPENCLAW_OBSIDIAN_VAULT_PATH"/*)
            rel="${out_file#"$OPENCLAW_OBSIDIAN_VAULT_PATH"/}"
            vault_enc=$(printf '%s' "$OPENCLAW_OBSIDIAN_VAULT" | sed 's| |%20|g')
            rel_enc=$(printf '%s' "$rel" | sed 's| |%20|g')
            click_action="open 'obsidian://open?vault=${vault_enc}&file=${rel_enc}'"
            ;;
    esac
fi

# terminal-notifier supports click actions; osascript does not. Fall back
# gracefully so the script still works on a fresh Mac without Homebrew.
if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier \
        -title "openClaw triage" \
        -message "$banner" \
        -execute "$click_action" \
        >/dev/null 2>&1 || true
elif command -v osascript >/dev/null 2>&1; then
    escaped=$(printf '%s' "$banner" | sed 's/\\/\\\\/g; s/"/\\"/g')
    osascript -e "display notification \"${escaped}\" with title \"openClaw triage\"" >/dev/null 2>&1 || true
fi

# Post to a Teams channel via Workflows incoming webhook if configured. The
# plan is already on disk and on the banner — a webhook failure must not fail
# the run, just warn.
teams_url="${OPENCLAW_TEAMS_WEBHOOK_URL:-}"
if [ -n "$teams_url" ]; then
    if ! command -v jq >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
        echo "warning: OPENCLAW_TEAMS_WEBHOOK_URL set but jq and curl are required — skipping Teams post" >&2
    else
        teams_title="openClaw triage — ${summary}"
        teams_payload=$(jq -n \
            --arg title "$teams_title" \
            --arg body "$plan" \
            '{
              type: "message",
              attachments: [{
                contentType: "application/vnd.microsoft.card.adaptive",
                content: {
                  type: "AdaptiveCard",
                  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                  version: "1.4",
                  body: [
                    { type: "TextBlock", text: $title, weight: "Bolder", size: "Medium", wrap: true },
                    { type: "TextBlock", text: $body, wrap: true }
                  ]
                }
              }]
            }')
        if ! curl -fsS -X POST -H 'Content-Type: application/json' \
                --max-time 15 \
                --data-binary "$teams_payload" \
                "$teams_url" >/dev/null 2>&1; then
            echo "warning: teams webhook post failed (plan still saved locally)" >&2
        fi
    fi
fi

# Echo the plan so the caller (agent) can relay to chat / channel too.
printf '%s\n' "$plan"
printf '\n[saved to %s]\n' "$out_file"
