# AGENTS.md — openClaw workspace skill bundle

## What this repo is

Personal skill bundle for [openClaw](https://github.com/openclaw/openclaw) daemon. Skills are symlinked into `~/.openclaw/workspace/skills/` on a Mac running the openClaw agent. This repo does **not** contain openClaw itself.

## Repo layout

```
.
├── INSTALL.md              # macOS daemon install + onboarding runbook
├── README.md               # Skills overview + ObsidianClaw integration notes
├── AGENTS.md               # This file — agent ramp-up + gotchas
└── skills/
    ├── hello/              # Smoke-test skill: greeting + macOS notification
    │   ├── SKILL.md
    │   └── hello.sh
    └── repo-triage/        # GitHub morning brief (PRs, CI, issues)
        ├── SKILL.md
        ├── SETUP.md        # Symlink, scope, launchd schedule, Obsidian/Dendron
        ├── triage.sh       # Delivery script: writes note + fires notification
        └── ai.openclaw.repo-triage.plist  # launchd template (8:30 AM daily)
```

## Critical constraints

- **macOS only** — skills use `osascript` and launchd; won't work on Linux/Windows
- **Daemon must be running** — skills are invoked via `openclaw agent --message "..."`
- **No network in scripts** — `triage.sh` and `hello.sh` do no I/O; agent gathers data via built-in tools
- **launchd/gateway don't read shell profiles** — env vars for Obsidian/Dendron must be in plist `EnvironmentVariables` dict

## Developer commands

```sh
# Health check
openclaw doctor

# Test skill standalone (proves notification path without agent)
~/code/openClaw/skills/hello/hello.sh --name "Test"

# Test via agent
openclaw agent --message "use the hello skill to greet me as Test"

# Negative check (agent should NOT invoke hello for unrelated prompts)
openclaw agent --message "what's the weather"

# Run repo-triage
openclaw agent --message "run repo triage"

# Gateway log (debug ObsidianClaw plugin failures)
tail -n 40 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
```

## ObsidianClaw integration (non-obvious)

**Origin allowlist** — Obsidian's `app://obsidian.md` origin doesn't parse as HTTP. Use wildcard in `~/.openclaw/openclaw.json`:

```json
"gateway": {
  "controlUi": { "allowedOrigins": ["*"] }
}
```

Then `openclaw gateway restart`.

**Device commands need `--token`** — `openclaw devices approve/remove/revoke` require `--token <value>` from `gateway.auth.token` in `~/.openclaw/openclaw.json`.

**Env vars for Obsidian/Dendron delivery** — add to gateway plist (not just shell profile):

```
OPENCLAW_OBSIDIAN_VAULT="Vault"
OPENCLAW_OBSIDIAN_VAULT_PATH="$HOME/Vault"
OPENCLAW_TRIAGE_DIR="$OPENCLAW_OBSIDIAN_VAULT_PATH"
OPENCLAW_DENDRON_PREFIX="work.triage"  # produces work.triage.YYYY.MM.DD.md
```

See `skills/repo-triage/SETUP.md` §5 for full setup.

## Skill conventions

- **SKILL.md format** — YAML frontmatter (`name`, `description`) followed by markdown usage guide
- **Scripts are delivery-only** — agent gathers data, script writes to disk + fires notification
- **repo-triage output** — all PRs, issues, repos rendered as clickable markdown hyperlinks to GitHub
- **Word target** — repo-triage plans target 150 words (130–170 acceptable)

## Testing expectations

- Smoke test standalone script first (proves notification path)
- Then test via agent
- Negative check: confirm agent doesn't invoke skill for unrelated prompts
- For repo-triage: verify symlinks, file format, and notification click behavior

## launchd operations

```sh
# Install scheduled triage (edit placeholders first)
sed -e "s|{{USER_HOME}}|$HOME|g" \
    -e "s|{{OPENCLAW_BIN}}|$(which openclaw)|g" \
    ai.openclaw.repo-triage.plist \
    > ~/Library/LaunchAgents/ai.openclaw.repo-triage.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.repo-triage.plist

# Dry-run fire
launchctl kickstart -k gui/$(id -u)/ai.openclaw.repo-triage

# Logs
~/.openclaw/triage/launchd.{out,err}.log
```

## Prereqs

- Node 22.19+ (Node 24 recommended)
- LLM API key (Anthropic default)
- macOS notification permission for Script Editor / Terminal
- `terminal-notifier` (optional, enables click-to-open in Obsidian)
