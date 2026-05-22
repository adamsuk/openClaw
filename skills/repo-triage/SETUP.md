# repo-triage — setup

Assumes the daemon is already running and the `hello` skill works
end-to-end (see top-level `INSTALL.md`).

## 1. Symlink the skill into the workspace

```sh
chmod +x ~/code/openClaw/skills/repo-triage/triage.sh
ln -s ~/code/openClaw/skills/repo-triage ~/.openclaw/workspace/skills/repo-triage
```

Verify:

```sh
ls -l ~/.openclaw/workspace/skills/repo-triage/SKILL.md
```

## 2. Configure repo scope

Create `~/.openclaw/repo-triage.repos` with one `owner/repo` per line:

```sh
mkdir -p ~/.openclaw
cat > ~/.openclaw/repo-triage.repos <<'EOF'
# adamsuk active repos — edit freely
adamsuk/openClaw
# adamsuk/other-repo
EOF
```

The skill will refuse to run with an empty scope rather than guessing.

## 3. Confirm GitHub auth

The skill leans on openClaw's built-in GitHub tool. If you've already used
the agent for any GitHub query (e.g. "what's my latest PR"), auth is set
up. If not, run `openclaw doctor` — the GitHub check will tell you what's
missing (usually a personal access token in `~/.openclaw/openclaw.json` or
a `GITHUB_TOKEN` env var).

## 4. Smoke test the script alone

The script doesn't touch GitHub — it just delivers a plan. Test it with a
canned plan:

```sh
printf '2026-05-22 · adamsuk/openClaw\n\nTop priorities:\n- review PR #4 (stale 3d)\n- fix CI on main (lint failing since yesterday)\n\nPR reviews waiting: adamsuk/openClaw#4\nCI red: adamsuk/openClaw · lint failing since 2026-05-21\nBlocked issues: none\n\nSuggested next action: kick the lint job, then review #4.\n' \
    | ~/code/openClaw/skills/repo-triage/triage.sh --summary "1 PR waiting, 1 CI red"
```

Expect: a banner from "openClaw triage", the plan echoed to stdout, and
the file `~/.openclaw/triage/<today>.md` written.

## 5. Run via the agent

```sh
openclaw agent --message "run repo triage"
```

Expect the agent to call the skill, gather data via its GitHub tool, and
fire the same notification — this time with real content.

## 6. Schedule it (optional)

Copy and edit the launchd template:

```sh
sed -e "s|{{USER_HOME}}|$HOME|g" \
    -e "s|{{OPENCLAW_BIN}}|$(which openclaw)|g" \
    ai.openclaw.repo-triage.plist \
    > ~/Library/LaunchAgents/ai.openclaw.repo-triage.plist
launchctl bootstrap gui/$(id -u) \
    ~/Library/LaunchAgents/ai.openclaw.repo-triage.plist
```

Default schedule is 08:30 daily. Edit `Hour` / `Minute` in the plist
before bootstrapping if you want a different time. A dry-run fire:

```sh
launchctl kickstart -k gui/$(id -u)/ai.openclaw.repo-triage
```

Logs land in `~/.openclaw/triage/launchd.{out,err}.log`.
