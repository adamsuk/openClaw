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
printf '**2026-05-22 · [adamsuk/openClaw](https://github.com/adamsuk/openClaw)**\n\n**Top priorities:**\n- review [PR #4](https://github.com/adamsuk/openClaw/pull/4) (stale 3d)\n- fix CI on main (lint failing since yesterday)\n\n**PR reviews waiting:**\n- [#4 Add feature](https://github.com/adamsuk/openClaw/pull/4) (Adam)\n\n**CI red:**\n- [adamsuk/openClaw](https://github.com/adamsuk/openClaw) · lint failing since 2026-05-21\n\n**Blocked issues:**\n- none\n\n**Suggested next action:** kick the lint job, then review #4.\n' \
    | ~/code/openClaw/skills/repo-triage/triage.sh --summary "1 PR waiting, 1 CI red"
```

Expect: a banner from "openClaw triage", the plan echoed to stdout, and
a file written to `$OPENCLAW_TRIAGE_DIR` (default `~/.openclaw/triage/`).
Filename is `YYYY-MM-DD.md` without Dendron config, or
`<prefix>.YYYY.MM.DD.md` with it (see §5).

**All PRs, issues, and repo names are rendered as clickable markdown hyperlinks**
to their GitHub URLs. Opening the file in Obsidian (or any markdown editor)
lets you click through directly to GitHub.

## 5. Obsidian + Dendron integration (optional, recommended)

If you use [ObsidianClaw](https://www.obsidianclaw.ai/) with
[Dendron](https://www.dendron.so/) naming conventions, set these env vars
in your shell profile (`~/.zshrc` or equivalent):

```sh
export OPENCLAW_OBSIDIAN_VAULT="Vault"                    # vault name as Obsidian knows it
export OPENCLAW_OBSIDIAN_VAULT_PATH="$HOME/Vault"         # vault root on disk

# Dendron: notes live flat at vault root, hierarchy is encoded in the filename.
# Set OPENCLAW_TRIAGE_DIR to vault root (or your notes/ subfolder if using Dendron v2).
export OPENCLAW_TRIAGE_DIR="$OPENCLAW_OBSIDIAN_VAULT_PATH"

# Dendron prefix — sets the hierarchy and switches the date format to YYYY.MM.DD.
# Produces notes like: work.triage.2026.05.22.md
export OPENCLAW_DENDRON_PREFIX="work.triage"
```

Reload your shell, then re-run the section 4 smoke test.

> **Important — launchd and the gateway service don't read your shell profile.**
> If you run triage via `openclaw agent` (through the gateway service) or via
> the scheduled launchd job (§7), the vars must be injected into the gateway
> process. How depends on how openclaw installed the gateway plist:
>
> **Check which pattern you have:**
> ```sh
> head -20 ~/Library/LaunchAgents/ai.openclaw.gateway.plist | grep -A2 ProgramArguments
> ```
> If the first `<string>` is a path ending in `-env-wrapper.sh`, you have the
> **env-file pattern** (openclaw's default install). Otherwise you have the
> **EnvironmentVariables plist pattern**.
>
> **Env-file pattern** (env-wrapper install — most common):
> ```sh
> # Append vars to the gateway env file:
> cat >> ~/.openclaw/service-env/ai.openclaw.gateway.env <<'EOF'
> OPENCLAW_OBSIDIAN_VAULT=Vault
> OPENCLAW_OBSIDIAN_VAULT_PATH=/Users/you/Vault
> OPENCLAW_TRIAGE_DIR=/Users/you/Vault
> OPENCLAW_DENDRON_PREFIX=work.triage
> EOF
>
> # Reload the gateway:
> launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist \
>   && launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist
> ```
>
> **EnvironmentVariables plist pattern** (non-default install):
> ```sh
> # Edit ~/Library/LaunchAgents/ai.openclaw.gateway.plist and add inside
> # the existing <dict> under <key>EnvironmentVariables</key>
> # (create the block if absent):
> #
> #   <key>OPENCLAW_OBSIDIAN_VAULT</key>
> #   <string>Vault</string>
> #   <key>OPENCLAW_OBSIDIAN_VAULT_PATH</key>
> #   <string>/Users/you/Vault</string>
> #   <key>OPENCLAW_TRIAGE_DIR</key>
> #   <string>/Users/you/Vault</string>
> #   <key>OPENCLAW_DENDRON_PREFIX</key>
> #   <string>work.triage</string>
>
> # Then reload:
> launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist \
>   && launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist
> ```
>
> The repo-triage plist template already has these as `{{placeholders}}`
> that the sed command in §7 fills in. Expect:
- File written as `$OPENCLAW_TRIAGE_DIR/work.triage.2026.05.22.md`
- Symlink updated: `work.triage.latest.md` → today's file
- Banner fires; click opens `work.triage.2026.05.22` **in Obsidian**

Daily-note template snippet (Dendron date format):

```markdown
## Morning triage
![[work.triage.{{date:YYYY.MM.DD}}]]
```

Adjust the prefix to match your `OPENCLAW_DENDRON_PREFIX` if you chose
something different (e.g. `daily.standup` or `areas.eng.triage`).

**Without Dendron** (plain Obsidian, no prefix): set `OPENCLAW_TRIAGE_DIR`
to a subfolder inside your vault instead, e.g.
`$OPENCLAW_OBSIDIAN_VAULT_PATH/Inbox/triage`, and omit
`OPENCLAW_DENDRON_PREFIX`. The transclusion is then
`![[Inbox/triage/{{date:YYYY-MM-DD}}]]`.

Caveat: spaces in vault names / paths are URL-encoded. Other unusual
characters (`?`, `#`, `&`) are not — keep names alphanumeric/dots/dashes.

## 6. Run via the agent

```sh
openclaw agent --message "run repo triage"
```

Expect the agent to call the skill, gather data via its GitHub tool, and
fire the same notification — this time with real content. The output note
will contain clickable markdown hyperlinks to all PRs, issues, and repos
mentioned, so you can click directly from Obsidian to GitHub.

## 7. Schedule it (optional)

Copy and edit the launchd template:

```sh
sed -e "s|{{USER_HOME}}|$HOME|g" \
    -e "s|{{OPENCLAW_BIN}}|$(which openclaw)|g" \
    -e "s|{{OPENCLAW_OBSIDIAN_VAULT}}|${OPENCLAW_OBSIDIAN_VAULT:-}|g" \
    -e "s|{{OPENCLAW_OBSIDIAN_VAULT_PATH}}|${OPENCLAW_OBSIDIAN_VAULT_PATH:-}|g" \
    -e "s|{{OPENCLAW_TRIAGE_DIR}}|${OPENCLAW_TRIAGE_DIR:-}|g" \
    -e "s|{{OPENCLAW_DENDRON_PREFIX}}|${OPENCLAW_DENDRON_PREFIX:-}|g" \
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
