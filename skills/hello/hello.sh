#!/bin/sh
# usage: hello.sh --name "Adam"
# prints a greeting and shows a macOS notification banner via osascript.
set -eu

name=""
while [ $# -gt 0 ]; do
    case "$1" in
        --name)
            shift
            [ $# -gt 0 ] || { echo "error: --name requires a value" >&2; exit 2; }
            name="$1"
            ;;
        --name=*)
            name="${1#--name=}"
            ;;
        -h|--help)
            echo "usage: $0 --name \"<name>\""
            exit 0
            ;;
        *)
            echo "error: unknown argument: $1" >&2
            exit 2
            ;;
    esac
    shift
done

if [ -z "$name" ]; then
    echo "error: --name is required" >&2
    exit 2
fi

greeting="Hello, ${name}!"
printf '%s\n' "$greeting"

if command -v osascript >/dev/null 2>&1; then
    # Escape any double quotes in the name to keep AppleScript happy.
    escaped=$(printf '%s' "$name" | sed 's/"/\\"/g')
    osascript -e "display notification \"Hello, ${escaped}!\" with title \"openClaw\"" >/dev/null 2>&1 || true
fi
