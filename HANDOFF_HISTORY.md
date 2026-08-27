# Handoff History

Append-only archive of per-session work logs for this repository.
The current rolling state lives in `HANDOFF.md`. When a session
finishes and its work is summarised in `HANDOFF.md` (or the work has
been committed and is no longer load-bearing for the next session),
move the session log into this file in reverse-chronological order
(newest at the top).

---

## Session 2026-08-26 (seventh session): template refresh and cutover to bristol-workspace-2

### Where this started

Jake noticed that his laptop's R, renv, and other versions had drifted
away from the `bristol-workspace` instance and asked how to bring the
instance up to date. The answer split the problem in two, and that
split is worth keeping.

System software -- R, Quarto, RStudio Server -- is controlled by the
template, so a relaunch replaces it. Per-project package versions are
controlled by `renv.lock` travelling through git, so `renv::snapshot()`
on the laptop and `renv::restore()` on the instance keep analyses
agreeing no matter what the instance's own R version is. For an
applied statistician worried that results will not match, the lockfile
is the answer; the instance version is the slower, separate concern.

The recommendation was to relaunch rather than upgrade in place,
because an in-place 4.5 to 4.6 upgrade leaves
`/usr/local/lib/R/site-library` full of packages built against the old
R. Jake agreed and asked for the refresh plus "the other things
necessary," then later "please do the next steps."

### Key decisions

1. **Relaunch, not in-place upgrade.** A half-stale site library is
   the honest reason, not tidiness.
2. **The template filename, `name`, and `slug` never change.** Users
   symlink `r-research-complete.yml` into `~/.prism/templates/` and
   the guides reference it by name, so renaming would break both. The
   `version:` field carries versioning instead: minor bump when
   installed software changes, patch bump for comment or doc edits.
   It went 1.0.0 -> 1.1.0 (version refresh) -> 1.2.0 (added the two
   database `-dev` packages).
3. **Launch alongside, never replace.** The old instance was left
   untouched and running work was never at risk. Terminating it stays
   Jake's call.
4. **Keep the name `bristol-workspace-2`** rather than terminating the
   old instance to reclaim the original name. Jake chose this; the
   start script was pointed at the new name accordingly.
5. **Pin renv to 1.2.3** rather than accepting "latest" (1.2.4), for
   exact parity with Jake's laptop.
6. **Collaborator usernames match the old instance**, including the
   transposed "r" in `drgarjardo` whose own git author name is
   `drgajardo`. Continuity beat correctness, but this is reversible
   and worth revisiting.
7. **Credentials never enter the transcript or the repo.** Passwords
   live in mode-600 files on the instance and are named by path only.

### What was actually wrong, in the order it was found

**The old handoff lied about uncommitted work.** It claimed
`r-research-complete.yml` had unstaged April changes. The working tree
was clean; that bump had been committed in `407b660` back on
2026-04-27. Anything in a handoff that says "uncommitted" should be
checked against `git status` before being believed.

**Template discovery was broken and would have failed any launch.**
A free `--dry-run` returned `template not found`. The symlink was
fine; Prism found the template and skipped it because its declared
parent, `Ubuntu 24.04 LTS (x86_64)`, was not on the search path. Prism
searches only `~/.prism/templates` and
`/opt/homebrew/share/prism/templates`, and the latter does not exist,
while the base templates ship only in the source tree. Fixed by
symlinking `~/src/prism/templates/base/ubuntu-24.04-x86.yml` into
`~/.prism/templates/`. This is a laptop-environment fix, not a repo
change, and any other host needs it too.

**A dry run burns the name it tests.** Prism v0.36.1 writes a record
with `state: dry-run` and an empty instance id into
`~/.prism/state.json`, so the real launch of that name fails with a
409 conflict. Cleaned by stopping the daemon and deleting that one
record, guarded by asserting both the dry-run state and the empty id.

**`--dry-run` also prints "launched successfully" while creating
nothing.** Every claim about what exists was checked against
`aws ec2 describe-instances` rather than Prism's output.

**The first work-at-risk check was a false all-clear.** Running git
over `prism workspace exec` means running as root, which trips git's
dubious-ownership guard. With stderr discarded, the commands returned
empty strings that read as "clean working tree, nothing unpushed" --
on exactly the question that gates terminating an instance. Redone
with `safe.directory` set and stderr shown, the real answer was: no
unpushed commits or stashes anywhere, and four regenerated CSVs whose
only changes are last-digit floating-point drift.

**Posit Package Manager served sources, not noble binaries, for
R 4.6.** Cloud-init took about 50 minutes. Nothing broke, but source
builds need C headers that binaries never did, which is how
`RPostgres` and `RMySQL` failed. The template installed the database
*clients* but not the `-dev` packages carrying `libpq-fe.h` and
`mysql.h`. Fixed in the template and by hand on the instance.

**Two later RMySQL failures were my own fault, not the template's.**
`install.packages` locks the site library, and a second call while
the first is running dies and leaves a stale `00LOCK-RMySQL` that
fails every retry until deleted.

**The security group is reused, not recreated.** A long-standing
handoff note said the manual open-to-all edit on port 8787 would be
lost on relaunch. It was not: the new instance was placed in the same
`sg-0f316041b4b0cab8a`, so port 8787 needed no work at all. The flip
side is that both instances share one group.

**The prism daemon spawned competing copies** late in the session,
after which `prism workspace stop` failed outright. Recovery is
`pkill -f /opt/homebrew/bin/prismd`, delete the two stale pid files,
then run any prism command. The AWS CLI was used to stop the instance
instead, and is the reliable fallback.

### Files changed and why

- **`r-research-complete.yml`** -- version pins refreshed to R 4.6.1,
  RStudio Server 2026.08.1-195, Quarto 1.10.18, with languageserver
  0.3.18 and renv 1.2.4/1.2.3 added to the choice lists and older
  entries kept. Added `libpq-dev` and `libmysqlclient-dev` so the two
  database packages build when PPM serves sources. Two unicode em
  dashes replaced with ASCII. `version:` 1.0.0 -> 1.2.0.
- **`start_bristol.sh`** -- `WORKSPACE` now defaults to
  `bristol-workspace-2`, and both it and `SLACK_WEBHOOK` read from the
  environment first, so the target can change without editing the file
  and the real webhook can be supplied without being committed. The
  header explains how.
- **`HANDOFF.md`** -- rewritten across the session to record measured
  state rather than assumptions, and to correct the stale claims above.

Every version was verified before it was written: deb URLs by HTTP
status, CRAN versions by the crandb API, and afterwards by reading
them off the running instance.

### Commits

    f0f202a  Refresh template to current releases
    bd6917f  HANDOFF: renv parity is opt-in, not the default
    0423896  Launch bristol-workspace-2; template-discovery fix, prism bugs
    c08aa7f  Add libpq-dev and libmysqlclient-dev
    9589a21  Record validated state; ASCII cleanup
    30f782f  Correct handoff: scope unverified claims, fix numbering
    30a9dee  Correct the security-group claim
    164ea75  Point start_bristol.sh at bristol-workspace-2
    a1cfed9  Record the completed cutover

### What was left undone, and why

Terminating the old instance is the only destructive step and was
deliberately not taken; the check that nothing is at risk is done, so
it is a one-command decision whenever collaborators confirm they have
moved. The 5 AM cron was left commented out because re-enabling it
resumes daily billing, which is a decision rather than a fix. Whether
AstroNvim codelens renders against the R language server still needs a
human to open an R file.

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
