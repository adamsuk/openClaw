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

## Layout

```
.
├── INSTALL.md            macOS install + onboarding runbook
└── skills/
    └── hello/            first skill — SKILL.md + hello.sh
```
