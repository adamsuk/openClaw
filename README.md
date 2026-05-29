# openClaw — workspace skill bundle

Personal skill bundle for [openClaw](https://github.com/openclaw/openclaw),
the open-source local AI agent. Skills in this repo are designed to be
symlinked into `~/.openclaw/workspace/skills/` on a Mac running the openClaw
daemon.

This repo does **not** contain openClaw itself. To install the daemon and
load these skills, follow [INSTALL.md](./INSTALL.md).

## Skills

| Skill | What it does |
| --- | --- |
| [`hello`](./skills/hello/) | Greets a person by name and shows a macOS notification banner. Smoke test for the skill loader. |
| [`repo-triage`](./skills/repo-triage/) | 150-word morning brief across your GitHub repos — review-blocked PRs, failing CI, blocked issues. Run via the agent or scheduled with launchd; delivers via macOS notification. All PRs, issues, and repos are clickable markdown hyperlinks. Click-to-open routes into Obsidian when ObsidianClaw is in use. See [SETUP.md](./skills/repo-triage/SETUP.md). |

## ObsidianClaw plugin

Connecting [ObsidianClaw](https://www.obsidianclaw.ai/) to a local gateway has a few non-obvious requirements:

**Origin allowlist** — Obsidian's Electron origin (`app://obsidian.md`) doesn't parse as a standard HTTP origin, so a literal allowlist entry is silently dropped. Set a wildcard instead in `~/.openclaw/openclaw.json` (safe: gateway is loopback-only + token-authed):

```json
"gateway": {
  "controlUi": {
    "allowedOrigins": ["*"]
  }
}
```

Then `openclaw gateway restart`.

**Device commands need `--token`** — `openclaw devices approve/remove/revoke` all require `--token <value>` to act through the live gateway. Without it they hit a local fallback that grants minimal scope (`operator.pairing` only) and partially applies changes. The token is at `gateway.auth.token` in `~/.openclaw/openclaw.json`.

```sh
# Approve a pending pairing request authoritatively:
openclaw devices approve --latest --token <gateway-token>
# Or by explicit id (safer — --latest is preview-only):
openclaw devices approve <requestId> --token <gateway-token>
```

**Check the gateway log first** — when the plugin fails, the log shows the exact rejection reason immediately and saves everything else:

```sh
tail -n 40 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
# Log path is also shown in: openclaw gateway status
```

## Layout

```
.
├── INSTALL.md            macOS install + onboarding runbook
└── skills/
    ├── hello/            first skill — SKILL.md + hello.sh
    └── repo-triage/      GitHub morning brief — SKILL.md + triage.sh + launchd template
```
