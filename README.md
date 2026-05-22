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
| [`repo-triage`](./skills/repo-triage/) | 150-word morning brief across your GitHub repos — review-blocked PRs, failing CI, blocked issues. Run via the agent or scheduled with launchd; delivers via macOS notification. Click-to-open routes into Obsidian when ObsidianClaw is in use. See [SETUP.md](./skills/repo-triage/SETUP.md). |

## Layout

```
.
├── INSTALL.md            macOS install + onboarding runbook
└── skills/
    ├── hello/            first skill — SKILL.md + hello.sh
    └── repo-triage/      GitHub morning brief — SKILL.md + triage.sh + launchd template
```
