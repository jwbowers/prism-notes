# Handoff Summary

Rolling state of the repository. Per-session work logs are archived
in `HANDOFF_HISTORY.md`.

Last reorganized: 2026-08-26.

## Current state

- **`r-research-complete.yml`** -- refreshed 2026-08-26 to current
  releases: R comment 4.6.1 (2026-06-24), RStudio Server
  2026.08.1-195 (jammy deb URL verified reachable, HTTP 200), Quarto
  1.10.18 (GitHub release asset verified to exist), languageserver
  0.3.18 and renv 1.2.4 added to choice lists (older entries kept).
  Template `version:` field bumped 1.0.0 -> 1.1.0. The earlier
  April bump was committed in `407b660` (2026-04-27); a prior note
  here claiming it was uncommitted was stale.
- **Versioning convention for the template**: the filename, `name`,
  and `slug` never change (users symlink `r-research-complete.yml`
  into `~/.prism/`, and the guides reference it by name). The
  `version:` field carries the template version: bump the minor
  number when installed software changes, the patch number for
  comment or documentation edits. Git history holds the details.
- **`start_bristol.log`** -- untracked log file, gitignored.

`check_activity.sh` was added in commit `c0ae87a` (2026-05-19): a
script that reports who is currently using the workspace (SSH logins,
RStudio Server sessions, active R / Quarto / Jupyter processes, load
average) via `prism workspace exec`. See the file header for usage.

## Pending work

1. **Relaunch bristol-workspace from the refreshed template, with
   `--hibernation`.** The current instance (launched 2026-03-18,
   STOPPED, pre-dates R 4.6) has never run any of the version bumps.
   Sequence: launch the new workspace alongside the old one, validate,
   then terminate the old one. Before terminating: confirm
   `check_activity.sh` shows it idle and every home directory's work
   is pushed to GitHub (the deploy-key model means unpushed work dies
   with the instance).
2. **On relaunch, redo what the relaunch destroys**: the security
   group is recreated per launch, so the open-to-all edit on port
   8787 must be reapplied; if the new workspace name differs from
   `bristol-workspace`, the 5 AM cron and `start_bristol.sh` need the
   new name.
3. **Watch the first launch for slow R package installs.** The April
   worry was PPM noble not yet indexing R 4.6 binaries. Four months
   on, that is likely resolved, but if installs run slow it is
   compilation from source, not a failure.

## Durable design rationale (carry forward indefinitely)

These are decisions about the template itself, not session-specific
choices. Keep them in mind when editing the YAML.

1. **R install stays version-agnostic.** The CRAN PPA installs whatever
   R it serves. The template documents the current version in a
   comment but does not pin it -- pinning would mean editing the
   template on every R release.
2. **RStudio Server jammy deb on noble continues.** Posit does not
   publish a native noble (Ubuntu 24.04) deb at any version. The glibc
   backward-compatibility path is documented in an in-file comment
   and works.
3. **languageserver and renv choice lists keep older entries.** Users
   may need to reproduce older environments. Add new versions; do not
   drop old ones.

## Open follow-ups to check next launch

- **AstroNvim v6 + Neovim 0.12.2 codelens.** AstroNvim v6.0.2 disabled
  codelens by default due to a Neovim 0.12.1 issue. Neovim 0.12.2 is
  now current and the template installs `latest`. Confirm nothing
  regresses.
- **noble-native RStudio Server debs.** Worth checking quarterly. If
  Posit publishes them, switch the URL to `noble/` for cleaner
  install -- no functional benefit, the jammy path works.

## Active operational concerns

- **The Mac running the cron must stay plugged in and not shut down.**
  No monitoring for missed starts.
- **The public IP may change on each start.** Collaborators check Slack
  each morning (the `start_bristol.sh` script posts it).
- **Shutdown is purely manual.** No scheduled stop, no reminder.
- **Idle detection is architecturally broken for persistent web
  services.** RStudio Server's background traffic exceeds the
  "research" policy's network threshold, so the policy never fires.
  Worth raising as a Prism issue.

## Feature ideas (carry-forward)

- **Web-based start/stop UI for collaborators.** See
  `memory/project_web_start_stop.md`.
- **Activity-check script (now exists).** `check_activity.sh` is a
  first step; could grow into a "safe to stop?" oracle that the
  shutdown automation consults before terminating.

## Infrastructure issues (carry-forward)

- **Silent hibernate fallback is a UX problem in Prism itself.**
  Feature request candidate: warn or refuse instead of silently falling
  back to stop.
- **No CLI option for additional CIDRs at launch.** Prism does not yet
  support opening ports to arbitrary IP ranges.
- **Port 8888 (Jupyter)** still restricted to `142.204.67.0/24`.
- **Security group is recreated per launch.** The manual open-to-all
  edit on 8787 will be lost on relaunch.
- **Guides do not document the security group workaround for Jupyter.**
  RStudio is documented; Jupyter is not.

## Important context

- User is Jake Bowers, political science faculty at UIUC, applied
  statistician. Collaborators are in Chile (earlier time zone, hence
  the 5 AM auto-start cron).
- Current workspace: "bristol-workspace" on `m7i.xlarge` in
  `us-east-2`. Does NOT support hibernation (launched without
  `--hibernation`).
- Security group `sg-0f316041b4b0cab8a` ("prism-access") has port
  8787 manually opened to `0.0.0.0/0`.
- The "research" idle policy is active but effectively non-functional
  due to RStudio Server background traffic.
- `start_bristol.sh` contains a Slack webhook URL -- do not commit
  this to a public repo without redacting it.
- Prism source is at `~/src/prism`. Claude has read permissions via
  `.claude/settings.local.json`.
- Persistent memory includes: Prism source location, web-based
  start/stop feature idea.
- Jake's global CLAUDE.md requires ASCII-only text (no unicode em
  dashes, smart quotes, ellipses, etc.) in all files.
- AstroNvim upstream template moved to v6 on 2026-03-30. The `main`
  branch of `github.com/AstroNvim/template` is now v6.
- Version pins as of last edit (2026-08-26): R 4.6.1 (released
  2026-06-24), RStudio Server 2026.08.1-195, Quarto 1.10.18,
  languageserver 0.3.18, renv 1.2.4 on CRAN. Jake's laptop runs
  R 4.6.1, renv 1.2.3, Quarto 1.10.18, so a fresh launch matches it.
