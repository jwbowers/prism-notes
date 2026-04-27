# Handoff Summary

Session date: 2026-04-27 (sixth session)

## What was done this session

Updated `r-research-complete.yml` to use the latest stable releases of R
and the major bundled tools, three days after R 4.6.0 shipped.

### Version bumps in `r-research-complete.yml`

All changes are in a single file, currently unstaged. Specific edits:

1. **R**: comment in `post_install` updated from "Install R 4.6.0" to
   "Install R (latest stable from CRAN PPA; 4.6.0 as of 2026-04-24)".
   The install logic was already correct -- it pulls whatever the
   `cran40` PPA serves -- so no functional change, just truthful
   documentation. R 4.6.0 was released 2026-04-24.

2. **RStudio Server**: default `RSTUDIO_VERSION` bumped from
   `2026.01.1-403` to `2026.04.0-526` (released 2026-04-18). Choices
   list refreshed to include `2026.04.0-526`, `2026.01.2-418`,
   `2026.01.1-403`, `2026.01.0-392`, `2025.09.2-418`. The jammy deb URL
   was verified to return 200 (`curl -sI`); a noble deb does not exist
   at this version, so the existing jammy-on-noble glibc compatibility
   approach stays.

3. **Quarto**: bumped from `1.6.33` to `1.9.37` in the post_install
   wget/install/rm trio and in the comment. Latest stable on the
   quarto-cli releases page.

4. **languageserver**: `0.3.17` (current CRAN release) added to the
   choice list; `0.3.16` and `0.3.15` retained.

5. **renv**: already at `1.2.2` (current) from a prior session; no
   change.

6. **`components:` block** at the bottom: `r_version: "4.6.0"`,
   `rstudio_server_version: "2026.04.0-526"`, `quarto_version: "1.9.37"`,
   `astronvim_version: "v6"` (was "latest").

7. **`long_description:`**: human-readable version strings updated to
   match (R 4.6.0, RStudio Server 2026.04, Quarto 1.9).

### Verification done before editing

- R 4.6.0 release date: cran.r-project.org/sources.html.
- RStudio tags: github.com/rstudio/rstudio/tags -- v2026.04.0+526
  released 2026-04-18 is the most recent stable.
- Jammy deb URL `2026.04.0-526` returns HTTP 200; noble URL returns
  404 (expected).
- Quarto latest stable: 1.9.37 from quarto-cli releases page.
- Neovim latest stable: 0.12.2. Template uses `latest` redirect, no
  change needed.
- languageserver CRAN version: 0.3.17.
- renv CRAN version: 1.2.2 (already present).
- PPM noble repo reachable (PACKAGES URL returns 200).

### CLI walkthrough cross-checked against Prism source

User asked how to launch a workspace from the updated template. The
existing `prism-workspace-guide.md` was cross-checked against
`~/src/prism/internal/cli/`:

- `prism workspace launch <template> <name>` -- still canonical
  (`workspace_commands.go:50`).
- `--param key=value` and `--hibernation` flags both still wired
  (`workspace_commands.go:79,90`).
- `prism idle policy apply <workspace> <policy-id>` -- unchanged
  (`idle_cobra.go:144`).
- `prism workspace hibernate/resume/stop/start/exec` -- unchanged.

Two small notes for future sessions:

- `--hibernation` is now an alias for `--idle-policy`
  (`commands.go:262-266`). Both work; the guide uses the older name
  and is still correct.
- A top-level `prism launch <template> <name>` shortcut exists
  (`root_command.go:28`).

The guide does not name version numbers, so it needed no edits.

## Key decisions made

1. **R install stays version-agnostic.** The CRAN PPA installs the
   latest available R automatically. We document the version in a
   comment but do not pin it. This is intentional -- pinning would
   mean editing the template every time R ships a release.

2. **RStudio Server jammy deb on noble continues.** Posit still does
   not publish a native noble (Ubuntu 24.04) deb, even at 2026.04.0.
   The glibc backward-compatibility path is documented in an existing
   in-file comment and works fine.

3. **languageserver and renv choice lists keep older entries.** Users
   may need to reproduce older environments. We add the new version
   but do not drop the old ones.

4. **`prism-workspace-guide.md` not edited.** It refers to the
   template generically, so version bumps in the YAML do not require
   guide changes. Better hygiene.

## Files changed

### Modified (not yet committed)

- **`r-research-complete.yml`** -- version bumps described above. The
  diff also includes whitespace-only YAML reformatting (multi-line
  `choices:` arrays, comment alignment) that was applied in earlier
  sessions but never committed; that pre-existing noise is mixed into
  this diff.

### Not modified

- `HANDOFF.md` -- this file (rewritten this session).
- `prism-workspace-guide.md` -- intentionally untouched.
- `setup-astro-nvim.sh`, `README.md` -- untouched.

### Git state

- Branch: `main`, up to date with `origin/main`.
- Last commit `a8ef1a5 Update to use AstroNvim v6` (committed the
  prior session's AstroNvim v6 work).
- `r-research-complete.yml` has unstaged changes from this session.
- `start_bristol.log` is untracked (gitignored log).

## What's done vs. what remains

### Done

- All version bumps applied to `r-research-complete.yml`.
- Upstream URLs / package indexes verified to exist.
- CLI commands in the workspace guide cross-checked against current
  Prism source.

### Remaining

- **Commit and push the version-bump changes.** Suggested commit
  message: `Update R, RStudio Server, and Quarto to latest stable
  releases`.
- **Test on a live launch.** None of these version bumps have been
  exercised end-to-end yet. Specifically:
  - PPM noble may not yet have R 4.6 binaries indexed (release was
    2026-04-24, three days before this session). If R packages start
    compiling from source instead of installing as binaries, that is
    the cause -- the install will still succeed, just slower.
  - RStudio Server 2026.04.0-526 jammy deb on noble: URL verified,
    not yet booted.
  - Quarto 1.9.37 deb: URL not explicitly verified, but the
    quarto-dev release URL pattern has been stable.

## Open questions / potential follow-ups

### From this session

1. **PPM R 4.6 binary index lag.** If the next workspace launch shows
   slow R package compilation, check whether
   `packagemanager.posit.co/cran/__linux__/noble/latest` has indexed
   R 4.6 binaries yet. Usually catches up within days of an R release.

2. **AstroNvim v6 + Neovim 0.12.2 codelens issue.** The previous
   session noted that AstroNvim v6.0.2 disabled codelens by default
   due to a Neovim 0.12.1 issue. Latest stable Neovim is now 0.12.2
   and the template installs `latest`. Worth confirming nothing
   regresses on next launch.

3. **noble-native RStudio Server debs.** Worth checking quarterly. If
   Posit publishes them, switch the URL to `noble/` for cleaner
   install -- but no functional benefit, the jammy path works.

### Active operational concerns (carried forward)

4. **The Mac must stay plugged in and not shut down for the cron
   workflow to work.** No monitoring for missed starts.
5. **The public IP may change on each start.** Collaborators must
   check Slack each morning.
6. **Shutdown is purely manual.** No scheduled stop, no reminder.

### Feature ideas (carried forward)

7. **Web-based start/stop UI for collaborators.** See
   `memory/project_web_start_stop.md`.
8. **Idle detection is architecturally broken for persistent web
   services.** RStudio Server's background traffic exceeds the
   research policy's network threshold, so the policy effectively
   never fires. Worth raising as a Prism issue.

### Infrastructure issues (carried forward)

9. **Relaunch bristol-workspace with `--hibernation`.** Current
   instance was launched without it.
10. **Silent hibernate fallback is a UX problem in Prism itself.**
    Feature request candidate: warn or refuse instead of silently
    falling back to stop.
11. **No CLI option for additional CIDRs at launch.** Prism does not
    yet support opening ports to arbitrary IP ranges.
12. **Port 8888 (Jupyter)** still restricted to `142.204.67.0/24`.
13. **Security group is recreated per launch.** The manual
    open-to-all edit on 8787 will be lost on relaunch.
14. **Guides do not document the security group workaround for
    Jupyter.** RStudio is documented; Jupyter is not.

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
  branch of `github.com/AstroNvim/template` is now v6. The Prism
  template clones that template, so v6 is what users get.
- R 4.6.0 released 2026-04-24. RStudio Server 2026.04.0+526 released
  2026-04-18. Quarto 1.9.37 is current stable. Neovim 0.12.2 is
  current stable.
