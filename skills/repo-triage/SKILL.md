---
name: repo-triage
description: |
  Produce a 150-word morning action plan covering open PR reviews, failing
  CI/CD pipelines, and blocked issues across the user's GitHub repositories,
  then deliver it via macOS notification. Use when the user says "run repo
  triage", "morning brief", "what needs my attention today", or the skill is
  invoked by a scheduled launchd job. Do not use for ad-hoc single-repo
  questions — point those at the built-in GitHub tools instead.
---

# repo-triage

Unified morning brief across the user's active GitHub repositories. Pulls
review-blocked PRs, failing CI runs, and blocked issues; writes a 150-word
action plan to disk; pops a short macOS banner so the user knows it's ready.

This skill is **agent-driven**: the LLM uses openClaw's built-in GitHub tools
to gather data and compose the plan, then hands the plan to `triage.sh` for
delivery. The script itself does no GitHub I/O — that keeps auth in one place
(the GitHub tool) and the script trivially testable.

## When to use

- User says "run repo triage", "morning brief", "what's on fire", or similar.
- The launchd job `ai.openclaw.repo-triage` fires (scheduled run).
- Do **not** invoke for narrow questions like "what's the status of PR #42" —
  use the GitHub tool directly for those.

## Inputs

- **Repo scope** — read from `~/.openclaw/repo-triage.repos` if it exists
  (one `owner/repo` per line, `#` comments allowed). Otherwise ask the user
  once which repos to cover and offer to write the file for next time. Do not
  guess; an empty scope means the skill cannot run.
- **Lookback window** — default 7 days for PR / CI activity. Honour
  `--since "<n>d"` if the user passes one.

## How to use

1. Load the repo list. If missing or empty, stop and ask the user.
2. For each repo, via the built-in GitHub tool, gather:
   - Open PRs where review is the bottleneck: requested-reviewer present
     **or** last activity > 2 days **or** mergeable but no approvals.
   - CI runs on the default branch with `conclusion = failure` in the
     lookback window. Group by workflow; only report the latest failure per
     workflow.
   - Open issues with the `blocked` label, or with no activity > 14 days.
3. Compose a single action plan, **target 150 words (130–170 acceptable)**,
   structured as:

   ```
   Date · repos covered

   Top priorities (3 bullets max, ordered by urgency)

   PR reviews waiting: <list, "owner/repo#123 — title (reviewer)">
   CI red: <list, "owner/repo · <workflow> failing since <date>">
   Blocked / stale issues: <list, "owner/repo#456 — title">

   Suggested next action: <one sentence>
   ```

   Be concrete. No filler ("you might want to consider"). Skip empty
   sections entirely rather than writing "nothing here".
4. Pipe the plan into `triage.sh`:

   ```sh
   printf '%s\n' "$PLAN" | ./triage.sh --summary "<short banner text>"
   ```

   `--summary` is a one-line banner body, e.g. `3 PRs waiting, 1 CI red`.
   Keep it under 100 chars — macOS truncates.
5. Report the script's stdout back to the user. If it exits non-zero,
   surface stderr and stop.

## What the script does

- Reads the plan from stdin (or `--plan-file <path>`).
- Writes it to `~/.openclaw/triage/YYYY-MM-DD.md` (overwrites if re-run).
- Updates symlink `~/.openclaw/triage/latest.md` → today's file.
- Fires a macOS banner: title `openClaw triage`, body = `--summary` value.
- Prints the full plan to stdout.

No network calls. State limited to `~/.openclaw/triage/`. macOS-only.

## Scheduled runs

A launchd template lives at `ai.openclaw.repo-triage.plist`. See
[SETUP.md](./SETUP.md) for install + schedule editing.
