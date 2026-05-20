# Handoff History

Append-only archive of per-session work logs for this repository.
The current rolling state lives in `HANDOFF.md`. When a session
finishes and its work is summarised in `HANDOFF.md` (or the work has
been committed and is no longer load-bearing for the next session),
move the session log into this file in reverse-chronological order
(newest at the top).

---

## Session 2026-04-27 (sixth session): R / RStudio / Quarto version bumps

### What was done this session

Updated `r-research-complete.yml` to use the latest stable releases of R
and the major bundled tools, three days after R 4.6.0 shipped.

#### Version bumps in `r-research-complete.yml`

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

#### Verification done before editing

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

#### CLI walkthrough cross-checked against Prism source

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

Two small notes:

- `--hibernation` is now an alias for `--idle-policy`
  (`commands.go:262-266`). Both work; the guide uses the older name
  and is still correct.
- A top-level `prism launch <template> <name>` shortcut exists
  (`root_command.go:28`).

The guide does not name version numbers, so it needed no edits.

### Session-specific decision

- **`prism-workspace-guide.md` not edited.** It refers to the template
  generically, so version bumps in the YAML do not require guide
  changes. Better hygiene to leave it alone.

### Git state at end of session

- Branch: `main`, up to date with `origin/main`.
- Last commit `a8ef1a5 Update to use AstroNvim v6` (committed the
  prior session's AstroNvim v6 work).
- `r-research-complete.yml` has unstaged changes from this session.
- `start_bristol.log` is untracked (gitignored log).
