# Handoff Summary

Rolling state of the repository. Per-session work logs are archived
in `HANDOFF_HISTORY.md`.

Last reorganized: 2026-05-19.

## Current uncommitted state

- **`r-research-complete.yml`** -- has unstaged changes from the
  2026-04-27 session bumping R / RStudio Server / Quarto /
  languageserver / AstroNvim versions. See `HANDOFF_HISTORY.md` for
  the per-line breakdown. Suggested commit message:
  `Update R, RStudio Server, and Quarto to latest stable releases`.
- **`start_bristol.log`** -- untracked log file, gitignored.

`check_activity.sh` was added in commit `c0ae87a` (2026-05-19): a
script that reports who is currently using the workspace (SSH logins,
RStudio Server sessions, active R / Quarto / Jupyter processes, load
average) via `prism workspace exec`. See the file header for usage.

## Pending work

1. **Commit and push the version-bump changes** in
   `r-research-complete.yml`. Diff also contains pre-existing
   whitespace-only YAML reformatting from earlier sessions (multi-line
   `choices:` arrays, comment alignment) that was never committed; that
   noise is mixed in.
2. **Test the version-bump changes on a live launch.** None of them
   have been exercised end-to-end. Specifically:
   - PPM noble may not have R 4.6 binaries indexed yet. If R packages
     start compiling from source instead of installing as binaries,
     that is the cause -- the install will still succeed, just slower.
   - RStudio Server 2026.04.0-526 jammy deb on noble: URL verified
     reachable, not yet booted.
   - Quarto 1.9.37 deb: URL pattern is stable but not explicitly
     verified.

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

- **PPM R 4.6 binary index lag.** If the next workspace launch shows
  slow R package compilation, check whether
  `packagemanager.posit.co/cran/__linux__/noble/latest` has indexed
  R 4.6 binaries yet. Usually catches up within days of an R release.
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

- **Relaunch bristol-workspace with `--hibernation`.** Current instance
  was launched without it.
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
- Version pins as of last edit: R 4.6.0 (released 2026-04-24), RStudio
  Server 2026.04.0+526 (released 2026-04-18), Quarto 1.9.37, Neovim
  0.12.2.
