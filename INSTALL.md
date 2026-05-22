# Install openClaw on macOS

Runbook for getting openClaw running on your Mac and loading the `hello` skill
from this repo. Run these commands on your Mac — not in a remote container.

Docs: <https://docs.openclaw.ai>  Source: <https://github.com/openclaw/openclaw>

## 1. Prereqs

- Node 22.19+ (Node 24 recommended). Check with `node --version`. If missing,
  install via `brew install node` or your preferred node manager.
- An LLM API key. This guide assumes Anthropic; substitute as needed.
- Notification permission for Script Editor / Terminal (macOS will prompt the
  first time `osascript` fires a banner — approve it).

## 2. Install the CLI

```sh
npm install -g openclaw@latest
# or: pnpm add -g openclaw@latest
```

Verify:

```sh
openclaw --version
```

## 3. Onboard and install the daemon

```sh
openclaw onboard --install-daemon
```

This walks through gateway, workspace, channels, and skills, and installs a
launchd user service so the daemon stays always-on across reboots.

When the onboarding asks about channels, **skip pairing a chat app** for now —
this setup uses macOS notifications as the output. You can add Telegram /
Signal / Discord later.

## 4. Configure the model

Edit `~/.openclaw/openclaw.json`:

```json
{
  "agent": {
    "model": "anthropic/claude-sonnet-4-6"
  }
}
```

Export your API key in your shell profile (`~/.zshrc` or equivalent):

```sh
export ANTHROPIC_API_KEY="sk-ant-..."
```

Reload the shell, then restart the daemon so it picks up the env:

```sh
launchctl kickstart -k gui/$(id -u)/ai.openclaw.daemon
# (exact service label may differ; `openclaw doctor` will report the real one)
```

## 5. Health check

```sh
openclaw doctor
```

All checks should be green. If the model check fails, the API key isn't
reaching the daemon — confirm it's exported in the shell that launched the
daemon, or set it inside `~/.openclaw/openclaw.json` per the docs.

## 6. Load the hello skill

Clone this repo and symlink the skill into the openClaw workspace:

```sh
git clone https://github.com/adamsuk/openClaw.git ~/code/openClaw
chmod +x ~/code/openClaw/skills/hello/hello.sh
mkdir -p ~/.openclaw/workspace/skills
ln -s ~/code/openClaw/skills/hello ~/.openclaw/workspace/skills/hello
```

Verify the symlink resolves:

```sh
ls -l ~/.openclaw/workspace/skills/hello/SKILL.md
```

## 7. Smoke test

Run the script standalone first — this proves the macOS notification path
without involving openClaw at all:

```sh
~/code/openClaw/skills/hello/hello.sh --name "Adam"
```

Expect `Hello, Adam!` on stdout and a banner from "openClaw" in Notification
Center. If no banner appears, open **System Settings → Notifications → Script
Editor** (or Terminal, whichever ran the command) and enable banners.

Now exercise the full agent path:

```sh
openclaw agent --message "use the hello skill to greet me as Adam"
```

Expect the same greeting back in the terminal **and** a banner.

Negative check (agent should *not* invoke hello):

```sh
openclaw agent --message "what's the weather"
```

If the agent runs `hello.sh` for that prompt, the skill `description` is too
broad — tighten it.

## 8. Next steps

- **Pair a real chat channel** (Telegram is the easiest first one: BotFather
  token + your chat ID). See <https://docs.openclaw.ai> for per-channel
  pairing flows and `openclaw pairing approve <channel> <code>`.
- **Build a useful skill** — the next planned skill is a GitHub repo-triage
  brief for the `adamsuk` org. It will live at `skills/repo-triage/` in this
  repo.
- **Update channel** — `openclaw update --channel beta` if you want
  pre-release features.
