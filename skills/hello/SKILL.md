---
name: hello
description: |
  Greet a person by name and show a macOS notification banner. Use when the
  user says "hello", asks you to greet someone, or asks to test the skills
  system end-to-end. Do not use for any other request.
---

# hello

Smoke-test skill for verifying openClaw's skill loader, agent tool-use, and
macOS notification path. Does one thing: greets a named person and pops a
banner via `osascript`.

## When to use

- The user says hello and wants a reply.
- The user explicitly asks to "test the skills system" or "run the hello skill".
- Do **not** invoke for unrelated requests (weather, code, search, etc.).

## How to use

1. Determine the name to greet. If the user gave one ("greet me as Adam"), use
   it verbatim. If they didn't, ask once for a name; do not invent one.
2. From this skill's directory, run:

   ```sh
   ./hello.sh --name "<name>"
   ```

3. Report the script's stdout back to the user as the reply.
4. If the script exits non-zero, surface the stderr message to the user and
   stop — do not retry with a different name.

## What the script does

- Prints `Hello, <name>!` to stdout.
- Fires a macOS notification: title `openClaw`, body `Hello, <name>!`.

No network calls. No state. macOS-only (uses `osascript`).
