#!/bin/sh
# usage: triage.sh --summary "<banner text>" [--plan-file <path>]
#        echo "$plan" | triage.sh --summary "3 PRs, 1 CI red"
#
# Saves a triage action plan to ~/.openclaw/triage/YYYY-MM-DD.md, updates a
# `latest.md` symlink, fires a macOS notification with the short summary, and
# echoes the full plan to stdout for the caller to relay.
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
if [ "$word_count" -lt 100 ] || [ "$word_count" -gt 200 ]; then
    echo "warning: plan is ${word_count} words (target 150, range 100–200)" >&2
fi

triage_dir="${OPENCLAW_TRIAGE_DIR:-$HOME/.openclaw/triage}"
mkdir -p "$triage_dir"

today=$(date +%Y-%m-%d)
out_file="${triage_dir}/${today}.md"
printf '%s\n' "$plan" > "$out_file"

# Refresh the `latest.md` symlink. ln -sf is portable; rm-then-ln avoids
# stale-dir-symlink edge case on macOS.
latest_link="${triage_dir}/latest.md"
rm -f "$latest_link"
ln -s "$out_file" "$latest_link"

# Banner — title fixed, body = summary. Truncate hard at 240 chars so macOS
# doesn't silently drop the notification.
if command -v osascript >/dev/null 2>&1; then
    banner=$(printf '%s' "$summary" | cut -c1-240)
    escaped=$(printf '%s' "$banner" | sed 's/\\/\\\\/g; s/"/\\"/g')
    osascript -e "display notification \"${escaped}\" with title \"openClaw triage\"" >/dev/null 2>&1 || true
fi

# Echo the plan so the caller (agent) can relay to chat / channel too.
printf '%s\n' "$plan"
printf '\n[saved to %s]\n' "$out_file"
