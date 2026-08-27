# Handoff Summary

Rolling state of the repository. Per-session work logs are archived
in `HANDOFF_HISTORY.md`.

Last reorganized: 2026-08-26.

## Start here

The working tree is clean apart from four untracked files, and both
EC2 instances are stopped. Nothing is half-finished.

The 2026-08-26 session refreshed the template and cut over to a new
instance, `bristol-workspace-2`, which is ready for collaborators.
What remains is three decisions for Jake, listed under "Pending work"
below. No code or configuration is waiting to be written.

Before trusting any claim in this file, check it. The 2026-08-26
session found that a previous version of this file asserted
uncommitted template changes that had in fact been committed four
months earlier, and separately asserted that the security group is
recreated on every launch when it is reused. Both cost time. Run
`git status`, and confirm anything about AWS against
`aws ec2 describe-instances` rather than against Prism's output.

## Current state

- **`r-research-complete.yml`** -- refreshed 2026-08-26 to current
  releases: R comment 4.6.1 (2026-06-24), RStudio Server
  2026.08.1-195 (jammy deb URL verified reachable, HTTP 200), Quarto
  1.10.18 (GitHub release asset verified to exist), languageserver
  0.3.18 and renv 1.2.4/1.2.3 added to choice lists (older entries
  kept), and `libpq-dev` plus `libmysqlclient-dev` added so the
  database packages build from source. Template `version:` field is
  now **1.2.0** (1.0.0 -> 1.1.0 for the version refresh, -> 1.2.0 for
  the added packages). The earlier April bump was committed in
  `407b660` (2026-04-27); a prior note here claiming it was
  uncommitted was stale.
- **`start_bristol.sh`** -- targets `bristol-workspace-2`. Both
  `WORKSPACE` and `SLACK_WEBHOOK` read from the environment first, so
  neither needs a file edit to change. The webhook in the file is a
  dead placeholder by design; see pending item 3.
- **Versioning convention for the template**: the filename, `name`,
  and `slug` never change (users symlink `r-research-complete.yml`
  into `~/.prism/templates/`, and the guides reference it by name).
  The `version:` field carries the template version: bump the minor
  number when installed software changes, the patch number for
  comment or documentation edits. Git history holds the details.
- **Four untracked files**, none of them accidental leftovers:
  `start_bristol.log` is a run log (note that `.gitignore` does *not*
  cover it, contrary to an earlier note here, so it shows up in every
  `git status`). `INSTANCE_SIZING.md`, `ipad-termius-setup.md`, and
  `remote-prismd-host-setup.md` are finished documents that have
  simply never been committed. Committing them, or adding the log to
  `.gitignore`, is an open question nobody has decided.

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

## Cutover completed 2026-08-26

The new instance is set up and ready for collaborators. All of the
following was done and verified, then the instance was stopped.

**Deploy key.** The instance's ed25519 public key is registered on
`bowers-illinois-edu/fully_specified_bf` as deploy key 161423167,
titled "bristol-workspace-2", read-write. The old instance's key
("Prism R-Research-Complete", 146008562) is still there and still
serves the old instance. Remove it whenever the old instance goes.

**Accounts.** `mlopez` and `drgarjardo` were created with
`add-collaborator`, matching the old instance's usernames. Note that
the username `drgarjardo` carries a transposed "r": his own git author
name is `drgajardo`. The username was kept as-is for continuity with
the old instance, but it is worth deciding whether to correct it.

Git identities were taken from the project's own commit history
rather than invented: `Matias Lopez <matiaslopez.uy@gmail.com>` (99
commits) and `drgajardo <daniel.98.g@gmail.com>` (28 commits, the
most recent on 2026-08-22).

**Clones.** All three accounts have
`~/projects/fully_specified_bf` on `main` at the same commit. The
launch-time clone had indeed failed, because the key was not yet
registered; re-running it after registration worked, which is the
end-to-end proof that the key is good.

**Passwords.** Collaborator passwords are in
`/root/collaborator-credentials.txt` (mode 600) on the instance, not
in any transcript or repo. Jake's RStudio password is in
`/home/jwbowers/.rstudio-credentials`. Read either with:

    prism workspace exec bristol-workspace-2 'cat /root/collaborator-credentials.txt'

**Codelens.** `codelens = true` in
`~/.config/nvim/lua/plugins/astrolsp.lua`, AstroNvim tracks `^6`, and
headless `nvim` exits 0. Whether it renders against the R language
server still wants a human opening an R file.

## Pending work

Only three things are left, and all three are Jake's to decide rather
than anyone's to execute.

1. **Send the collaborators their passwords and the new address.**
   Read them from `/root/collaborator-credentials.txt` as shown
   above. The public IP changes on every start, so whatever address
   they get today is good only for today's session.
2. **Terminate the old instance** once Matias and Daniel have
   confirmed they are working on the new one. This is the only
   destructive step, nothing else depends on it, and the check for
   work at risk is already done. Delete deploy key 146008562 at the
   same time. Until then it costs about $6.40 a month in storage.
   Naming resolved: the new workspace keeps the name
   `bristol-workspace-2`, and `start_bristol.sh` now targets it.
3. **Decide whether to restore the 5 AM auto-start.** Two separate
   things are off. The cron line in `crontab -l` is commented out, so
   nothing starts automatically, and the last log entry is
   2026-06-29. And `SLACK_WEBHOOK` was stripped in `098c0c5`
   (2026-04-20), so a post would go to a dead URL and fail silently.
   Uncommenting the cron restores daily starts and daily billing;
   restoring the notice needs the real webhook exported from the
   environment, which the script header now explains. Keep the real
   value out of the repository.

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
- **The prism daemon spawned competing copies** on 2026-08-26. Each
  `prism` call started another `prismd` while an earlier one was
  still coming up, and calls then failed with "Check if 'prismd'
  binary is in your PATH" and a stale-pid muddle. Recovery:
  `pkill -f /opt/homebrew/bin/prismd`, delete `~/.prism/daemon.pid`
  and `~/.prism/prismd.pid`, then run any prism command to start one
  cleanly. `prism workspace stop` also failed this way, so the stop
  was issued with `aws ec2 stop-instances` instead. When prism is
  unreliable, the AWS CLI is the fallback for start, stop, and state.
- **`prismd` is a symlink into the source tree**
  (`/opt/homebrew/bin/prismd -> ~/src/prism/bin/prismd`), which is a
  second reason `~/src/prism` must stay checked out, alongside the
  base-template symlink described above.
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
- **The public IP changes on each start**, and as of 2026-08-26
  nothing announces it. The Slack notice in `start_bristol.sh` has
  been posting to a dead URL since the webhook was stripped on
  2026-04-20, and the cron that would run it is commented out, so
  collaborators currently have no automatic way to learn the address.
  Someone has to send it by hand each session until pending item 3 is
  settled.
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
- Security group `sg-0f316041b4b0cab8a` ("prism-access") is shared by
  both instances and has port 8787 open to `0.0.0.0/0`, port 22 open
  to `0.0.0.0/0`, and ports 80, 443, and 8888 limited to
  `142.204.67.0/24`.
- The "research" idle policy is active but effectively non-functional
  due to RStudio Server background traffic.
- **`start_bristol.sh` no longer contains a real Slack webhook.** It
  was stripped in `098c0c5` (2026-04-20) and the script now reads
  `SLACK_WEBHOOK` from the environment. Keep the real value in the
  environment and out of the repository.
- The project served by these workspaces is
  `bowers-illinois-edu/fully_specified_bf`, checked out locally at
  `~/repos/fully_specified_bf`. Collaborators are Matias Lopez
  (`mlopez`) and Daniel Gajardo (`drgarjardo` on the instances,
  `drgajardo` in git). Daniel committed on 2026-08-22, so the project
  is active, not dormant.
- Prism source is at `~/src/prism`. Claude has read permissions via
  `.claude/settings.local.json`. **Two things break if that checkout
  goes away**: the base-template symlink that makes the template
  loadable at all, and `/opt/homebrew/bin/prismd`, which is itself a
  symlink into `~/src/prism/bin/`.
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
- **The original question behind all of this**, worth restating
  because it is easy to lose in the operational detail: Jake's laptop
  had drifted away from the instance, and he asked how to close the
  gap. The answer has two halves. System software (R, Quarto, RStudio
  Server) is what the template controls, and a relaunch replaces it.
  Per-project package versions are what `renv.lock` controls, and
  they travel through git: `renv::snapshot()` on the laptop,
  `renv::restore()` on the instance, with renv bootstrapping the
  version the lockfile names. The second half is what makes analyses
  agree across machines, and it works regardless of the instance's
  own R version. Recommend the lockfile first when this comes up
  again; the instance version is the slower, separate concern.
