# repo-triage — setup

Assumes the daemon is already running and the `hello` skill works
end-to-end (see top-level `INSTALL.md`).

## 0. Optional: click-to-open notifications

Plain `osascript` banners can't carry a click action. Install
`terminal-notifier` so clicking the banner opens today's brief:

```sh
brew install terminal-notifier
```

The script auto-detects it and falls back to `osascript` (no click) if
absent. Section 5 wires the click target to Obsidian; without that, the
click just opens the markdown file in your default app.

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

## 5. Obsidian integration (optional, recommended)

If you use [ObsidianClaw](https://www.obsidianclaw.ai/), point the triage
output into your vault so each morning's brief becomes a real note —
searchable, backlinkable, and transcludable into your daily note.

Set three env vars in your shell profile (`~/.zshrc` or equivalent),
replacing the paths with your vault location:

```sh
export OPENCLAW_OBSIDIAN_VAULT="Vault"                       # vault name as Obsidian knows it
export OPENCLAW_OBSIDIAN_VAULT_PATH="$HOME/Vault"            # vault root on disk
export OPENCLAW_TRIAGE_DIR="$OPENCLAW_OBSIDIAN_VAULT_PATH/Inbox/triage"
```

Reload your shell, then re-run the section 4 smoke test. Expect the
banner to fire as before — but clicking it now opens today's note **in
Obsidian** (via `obsidian://open?vault=…&file=…`) instead of the default
markdown app. If you didn't install `terminal-notifier` in section 0,
the banner still appears but the click does nothing.

Daily-note template snippet — drop this in your daily note to pull in
today's brief automatically:

```markdown
## Morning triage
![[Inbox/triage/{{date:YYYY-MM-DD}}]]
```

(Adjust the path if you chose a different `OPENCLAW_TRIAGE_DIR`.)

Caveat: spaces in vault names / triage paths are URL-encoded by the
script. Other unusual characters (`?`, `#`, `&`) are not — keep the
vault name and triage subdir alphanumeric/dashes to be safe.

## 6. Run via the agent

```sh
openclaw agent --message "run repo triage"
```

Expect the agent to call the skill, gather data via its GitHub tool, and
fire the same notification — this time with real content.

## 7. Schedule it (optional)

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
