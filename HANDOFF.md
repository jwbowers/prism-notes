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

### Template discovery was broken; fixed 2026-08-26

A `--dry-run` launch on 2026-08-26 failed with `template not found:
R Research Complete`, and `prism templates` did not list it. The
cause was not the symlink, which is intact
(`~/.prism/templates/r-research-complete.yml` ->
`~/repos/prism-notes/r-research-complete.yml`). Prism found the file
and then skipped it:

    Warning: skipping template R Research Complete:
      parent template not found: Ubuntu 24.04 LTS (x86_64)

Our template declares `inherits: ["Ubuntu 24.04 LTS (x86_64)"]`.
Prism v0.36.1 (homebrew) searches only two directories --
`~/.prism/templates` and `/opt/homebrew/share/prism/templates` -- and
the second does not exist, so no base template was on the search
path. The base templates ship in the *source* tree only, at
`~/src/prism/templates/base/`.

Fix applied: symlink the base template into the user template
directory, which Prism does search.

    ln -sf ~/src/prism/templates/base/ubuntu-24.04-x86.yml \
           ~/.prism/templates/ubuntu-24.04-x86.yml

After this, `prism templates validate "R Research Complete"` reports
`Valid (0 warnings, 5 suggestions)` and a dry-run launch succeeds.
This is an environment fix on Jake's laptop, not a repo change; any
other host that launches this template needs the same symlink. It
depends on `~/src/prism` staying checked out.

Two cautions learned here. First, do **not** follow Prism's suggested
remedy `rm -rf ~/.prism/templates` -- that directory holds the
symlink to this repo, and deleting it breaks the whole workflow.
Second, `prism workspace launch --dry-run` prints
`Instance <name> launched successfully` even though it creates
nothing; verified against `aws ec2 describe-instances`, which showed
only the original instance. Trust AWS, not that message.

### `--dry-run` leaves a phantom that blocks the real launch

Prism v0.36.1 bug, hit on 2026-08-26 and worth reporting upstream. A
`--dry-run` launch writes a record into `~/.prism/state.json` with
`state: dry-run` and an empty instance id. The real launch of that
same name then fails:

    API error 409: Instance named "bristol-workspace-2" already
    exists (state: dry-run, id: ). Use a different name, or
    terminate the existing instance first.

So a dry run burns the name it was testing. The fix was to stop the
daemon (`prism admin daemon stop`), delete that one record from
`~/.prism/state.json`, and let the daemon restart on the next
command. Back the file up first, and match on both `state == "dry-run"`
and an empty id before deleting, so a real instance can never be hit
by mistake. A backup sits at `~/.prism/state.json.pre-phantom-cleanup.bak`.

An unrelated stub, `~/.prism/templates/new-template.yml`, is invalid
YAML and prints a harmless warning on every prism command. Deleting
it would quiet the noise.

`check_activity.sh` was added in commit `c0ae87a` (2026-05-19): a
script that reports who is currently using the workspace (SSH logins,
RStudio Server sessions, active R / Quarto / Jupyter processes, load
average) via `prism workspace exec`. See the file header for usage.

## The two instances, as of 2026-08-26

`bristol-workspace-2` was launched on 2026-08-26 from the refreshed
template, alongside the old instance rather than replacing it.

| | old `bristol-workspace` | new `bristol-workspace-2` |
|---|---|---|
| instance id | `i-0183fcfa9115a8f55` | `i-0f863fb51586f1e90` |
| launched | 2026-03-18 | 2026-08-26 |
| type | m7i.xlarge | m7i.xlarge (`--size L`) |
| hibernation | no | **yes** |
| R | 4.5.3 | **4.6.1** |
| Quarto | 1.6.33 | **1.10.18** |
| RStudio Server | 2026.01.1+403 | **2026.08.1+195** |
| renv | 1.1.8 | **1.2.3** (pinned for laptop parity) |
| languageserver | not checked | **0.3.18** |
| Neovim | not checked | **0.12.5** |

Both columns are measured, not inferred. The new instance matches
Jake's laptop exactly on R, Quarto, and renv. RStudio Server is
active with port 8787 listening, `library(tidyverse)` loads, and 181
packages sit in the site library.

Pinning renv to 1.2.3 rather than accepting "latest" exercised the
`remotes::install_version` branch of the template, which had never
run before. It works.

The old instance was measured, not guessed: it was started briefly on
2026-08-26 to read these versions and then stopped again. The
divergence was wider than the earlier note assumed -- Quarto was four
minor versions behind, and renv a full minor version behind.

Hibernation is confirmed enabled on the new instance
(`HibernationOptions.Configured = true` in
`aws ec2 describe-instances`) and confirmed absent on the old one,
which settles the standing question about the silent fallback.

### Work at risk on the old instance: none of substance

Every home directory was checked on 2026-08-26. Accounts are
`jwbowers`, `mlopez`, `drgarjardo`, plus `ubuntu`. No unpushed
commits and no stashes anywhere. The only uncommitted changes are
four regenerated CSVs in `/home/jwbowers/repos/fully_specified_bf`
(`replications/*/sensitivity_axes.csv`, modified 2026-05-04), and
they differ only in the last digit or two of floating-point values --
for example `3.426868736` against `3.42686873600001`. An untracked
`.claude/settings.local.json` sits alongside them. The diff is saved
outside the repo in case it is ever wanted.

That last-digit drift is the environment divergence showing up in
output.

**Check git as the owning user, or with `safe.directory` set.**
`prism workspace exec` runs as root over SSM, so plain `git -C` calls
against a user-owned repo fail the dubious-ownership guard. With
stderr discarded they return empty strings, which read as "clean
working tree, nothing unpushed" -- a false all-clear on exactly the
question that gates terminating an instance. Set
`GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory
GIT_CONFIG_VALUE_0='*'` and let stderr through.

### Posit Package Manager served sources, not binaries

The standing question is answered, and not the way the April note
guessed: on the 2026-08-26 launch every R package compiled from
source under R 4.6.1. Cloud-init ran about 50 minutes instead of the
usual few. Nothing broke, but two consequences matter.

First, the slow launch is expected until PPM indexes noble binaries
for R 4.6. Second, source builds need C headers that binaries never
did, which is how the `RPostgres` and `RMySQL` failures surfaced. The
template now installs `libpq-dev` and `libmysqlclient-dev` (commit
`c08aa7f`), and both packages were installed by hand on the running
instance, so `bristol-workspace-2` already matches the fixed
template. A future launch needs no manual step.

If a later launch is fast and the database packages arrive as
binaries, PPM has caught up and the two `-dev` packages become
harmless insurance. Keep them.

**Installing R packages one at a time over `prism workspace exec`
invites a lock collision.** `install.packages` takes a lock on
`/usr/local/lib/R/site-library`, and a second call while the first
still runs dies with `failed to lock directory`, leaving a stale
`00LOCK-<pkg>` that fails every retry until it is deleted. Both
RMySQL failures were this, not a missing header. Install in one call,
and if a retry fails, `rm -rf /usr/local/lib/R/site-library/00LOCK-*`
first.

## Pending work

1. **Register the new deploy key on GitHub.** The new instance
   generated its own ed25519 key. Until the public key is added to
   the deploy keys of `bowers-illinois-edu/fully_specified_bf`, no
   account on the new instance can clone or push. The launch-time
   auto-clone almost certainly failed for the same reason, though
   that was inferred rather than checked in the log. Only Jake can
   grant this. The key is:

       ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ3z7fwZV5dxi2xz1sA3/VEygRuphrMbBEfZuOOjmxnC prism-ip-172-31-7-125-deploy-key

2. **Check at next start, before assuming anything works**: that
   `/usr/local/bin/add-collaborator` exists (step 3 below assumes it),
   that the repo clone succeeded once the deploy key is registered,
   and that AstroNvim codelens behaves when an R file is opened. None
   of the three was verified on 2026-08-26.
3. **Retrieve the RStudio password.** The launch set no
   `rstudio_password`, so the template generated a random one:
   `prism workspace exec bristol-workspace-2 'cat
   /home/jwbowers/.rstudio-credentials'`. Without it there is no
   RStudio login on the new instance.
4. **Recreate the collaborator accounts** on the new instance:
   `sudo add-collaborator mlopez ...` and
   `sudo add-collaborator drgarjardo ...`, then send each person
   their new password. Account names should match the old instance so
   paths in their notes still read correctly.
5. ~~Reopen port 8787.~~ **Already done, and the belief behind this
   item was wrong.** The security group is *not* recreated per
   launch: `bristol-workspace-2` was placed in the same
   `sg-0f316041b4b0cab8a` ("prism-access") as the old instance,
   which already carries 8787 open to `0.0.0.0/0`. So RStudio on the
   new instance is reachable with no security-group work. Port 8888
   (Jupyter) remains restricted to `142.204.67.0/24`, and port 22 is
   open to the world. Because the group is shared, editing it affects
   both instances at once.
6. **Decide the name question.** The new workspace is
   `bristol-workspace-2` because the old one still holds
   `bristol-workspace`. Either keep the suffixed name and update
   `start_bristol.sh` and the cron line, or terminate the old
   instance and relaunch under the original name.
7. **Terminate the old instance** once collaborators have moved. This
   is the only destructive step and nothing above depends on it. The
   work-at-risk check above is already done.
8. **The 5 AM cron is currently commented out** in `crontab -l`, and
   the last entry in `start_bristol.log` is 2026-06-29. Separately,
   `start_bristol.sh` had its Slack webhook redacted in commit
   `098c0c5` (2026-04-20), so `SLACK_WEBHOOK` is now the bare
   `https://hooks.slack.com/services/` and any post would fail. Both
   need attention before auto-start and its Slack notice work again.
   Keep the real webhook out of the repo.

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

- **AstroNvim v6 + Neovim codelens.** AstroNvim v6.0.2 disabled
  codelens by default due to a Neovim 0.12.1 issue. The 2026-08-26
  launch installed Neovim 0.12.5 and AstroNvim set up cleanly, but
  nobody has opened an R file in it yet, so whether codelens is back
  on is still unconfirmed.
- **`spored` failed to install** on the 2026-08-26 launch: the log
  shows `spored download failed` and `spored install failed`, though
  the systemd unit was still linked. `spored` is Prism's idle-activity
  daemon, so this may be one more reason idle detection never fires.
  Worth a look if idle shutdown is ever wanted.
- **`cloud-init status` never reached `done`** on the new instance. It
  still reported `running` with `errors: []` and a 1970 timestamp long
  after the setup script had finished and every service was up. The
  environment validates, so this looks like stuck status bookkeeping
  rather than unfinished work -- possibly the `spored` failure above.
  Do not wait on `cloud-init status`; check the services instead.
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
- **Security groups are reused across launches, not recreated.**
  Corrected 2026-08-26: the 2026-08-26 launch reused
  `sg-0f316041b4b0cab8a`, so the manual open-to-all edit on 8787
  survived and needed no repeating. The flip side is that both
  instances share one group, so any rule change hits both.
- **Guides do not document the security group workaround for Jupyter.**
  RStudio is documented; Jupyter is not.

## Important context

- User is Jake Bowers, political science faculty at UIUC, applied
  statistician. Collaborators are in Chile (earlier time zone, hence
  the 5 AM auto-start cron).
- Two workspaces exist as of 2026-08-26, both `m7i.xlarge` in
  `us-east-2` with 80 GB gp3 root volumes, and both STOPPED.
  "bristol-workspace" is the old one, without hibernation.
  "bristol-workspace-2" is the new one, with hibernation, and is the
  one to move to. Storage is the only cost while they sit stopped.
  Note that `--size L` advertises "+2TB" but the template's
  `root_volume_gb: 80` wins, so the volume is 80 GB either way.
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
  R 4.6.1, renv 1.2.3, Quarto 1.10.18, so a fresh launch matches it
  on R and Quarto; renv defaults to "latest" (1.2.4), or pick 1.2.3
  from the choices list at launch for exact laptop parity.
