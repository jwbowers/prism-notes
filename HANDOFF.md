# Handoff Summary

Session date: 2026-04-04 (fifth session, extends prior handoffs)

## What was done

### Prior sessions (preserved for context)

1. **Created CLAUDE.md** -- project-level instructions for Claude Code sessions.
2. **Updated `.claude/settings.local.json`** -- added read/glob/grep permissions for `~/src/prism/**`.
3. **Created persistent memory** -- `memory/reference_prism_source.md` and `memory/MEMORY.md`.
4. **Opened RStudio port 8787 to 0.0.0.0/0** -- manual security group edit in AWS console (`sg-0f316041b4b0cab8a`) so collaborators in Chile could connect. Port 8888 (Jupyter) was left restricted.
5. **Researched idle vs. stop vs. hibernate in Prism** -- key findings: idle is a policy (not a state) that triggers stop or hibernate; the research policy stops after 15 min of low activity during daytime; hibernate requires `--hibernation` flag at launch; costs are identical once stopped.
6. **Discovered bristol-workspace does not support hibernation** -- launched without `--hibernation`, so hibernate falls back to stop.
7. **Updated `prism-workspace-guide.md`** -- added hibernation flag section, cost comparison, updated idle policy and hibernate sections, updated examples and quick reference.
8. **Diagnosed why Prism idle detection fails with RStudio Server.** RStudio's background processes (health pings, session keepalives, rsession daemons) generate enough network traffic to exceed the research policy's 10 bytes/sec network threshold. The idle policy effectively never fires. Key code: `~/src/prism/pkg/idle/metrics_collector.go` (IsInstanceIdle), `~/src/prism/pkg/idle/policies.go` (research policy at line 152).
9. **Discussed workaround options.** Chose option (c) -- drop idle detection entirely, rely on manual stop via Slack coordination.
10. **Discussed feature idea: web-based start/stop for collaborators.** Saved to persistent memory (`memory/project_web_start_stop.md`).
11. **Updated README.md with automated daily startup documentation.** Added "Automated daily startup" section documenting `start_bristol.sh`, `pmset` wake schedule, crontab entry, and why shutdown is manual.

### This session

12. **Updated AstroNvim setup to target v6 in both `setup-astro-nvim.sh` and `r-research-complete.yml`.** The AstroNvim template repo (`github.com/AstroNvim/template`, main branch) was updated for v6 on 2026-03-30. The old config targeted v4/v5 patterns that no longer work correctly. Three specific problems were fixed:

    - **Treesitter configuration moved from `nvim-treesitter` plugin opts to `astrocore` opts.** In v6, `nvim-treesitter` is just a parser download utility. Highlight, indent, auto_install, and ensure_installed are now configured under `AstroNvim/astrocore` opts at the `treesitter` key. Both files were updated accordingly.
    - **`nvim-treesitter` branch renamed from `master` to `main`.** Both files now explicitly set `branch = "main"` on the nvim-treesitter plugin spec.
    - **`tree-sitter-cli` added to the Prism template's mason config.** The standalone script already had it; the template did not. tree-sitter-cli is needed to compile treesitter parsers. Mason auto-installs it during the headless plugin sync.

    Additionally, `setup-astro-nvim.sh` now pins `version = "^6"` in its `lazy_setup.lua` AstroNvim spec. The Prism template does not need this because it clones the upstream template which already contains `version = "^6"`.

## Key decisions made

1. **AstroNvim v6, not v4/v5.** The upstream template already moved to v6. The old treesitter-via-plugin-opts pattern was silently broken (parsers might install but highlight/indent would not be configured through AstroCore). Pinning v6 explicitly in the standalone script prevents accidental rollback.
2. **tree-sitter-cli via Mason, not system-wide.** Mason handles the install during the headless `Lazy! sync` step. No npm or cargo install needed at the system level. A C compiler is required (already provided by `build-essential` in the template's APT packages).
3. **Treesitter config lives in astrocore.lua, not treesitter.lua.** The treesitter.lua file is kept but reduced to just setting the branch. The substantive config (ensure_installed, highlight, indent, auto_install) is in astrocore.lua. This matches AstroNvim v6 conventions.

## Files changed

### Modified (not yet committed)

- **`setup-astro-nvim.sh`** -- Three changes:
  - Added `version = "^6"` to AstroNvim spec in lazy_setup.lua (line 81)
  - Replaced treesitter.lua content: was `nvim-treesitter` with `opts.ensure_installed`; now just `branch = "main"` (lines 148--156)
  - Added `treesitter` key to astrocore.lua opts with highlight, indent, auto_install, and ensure_installed (lines 180--188)

- **`r-research-complete.yml`** -- Three changes in the `{{else}}` (built-in AstroNvim) branch of the post_install script:
  - Replaced treesitter.lua heredoc: was `nvim-treesitter` with `opts.ensure_installed`; now just `branch = "main"` (lines 468--474)
  - Added new astrocore.lua heredoc with treesitter config (lines 476--488)
  - Added new mason.lua heredoc ensuring tree-sitter-cli (lines 490--502)

### Not modified

- `HANDOFF.md` -- this file (rewritten this session).
- All other files unchanged.

### Git state

- Branch: `main`, up to date with `origin/main`.
- `r-research-complete.yml` and `setup-astro-nvim.sh` have unstaged changes from this session.
- `start_bristol.log` is untracked (gitignored log file from the cron auto-start script).

## Open questions / potential follow-ups

### From this session

1. **The v6 changes are untested on a live instance.** The next time bristol-workspace is relaunched (or a new workspace is created), the AstroNvim setup should be verified: treesitter parsers compile, R.nvim loads, Mason installs tree-sitter-cli. The headless `Lazy! sync` step swallows errors (`|| true`), so check manually with `nvim` after launch.
2. **AstroNvim v6 requires Neovim 0.11+.** The template installs `latest` from GitHub releases, which is currently 0.11.x. If Neovim ever ships a 0.10.x patch release as `latest` (unlikely but possible), v6 would break. Consider pinning a minimum Neovim version.
3. **The standalone script writes its own init.lua and lazy_setup.lua, overriding the cloned template.** This is intentional (the script is a self-contained setup). But it means the script and the template can drift. The Prism template relies on the upstream template's lazy_setup.lua (which already has `version = "^6"`); the standalone script writes its own.
4. **astrolsp.lua in the standalone script uses `codelens = true`.** AstroNvim v6.0.2 disabled codelens by default due to a Neovim 0.12.1 issue. If the instance ever runs Neovim 0.12.x, this could cause problems. Not urgent since we install stable (0.11.x).

### Active operational concerns (carried forward)

5. **The Mac must stay plugged in and not shut down for the cron workflow to work.** No monitoring for missed starts.
6. **The public IP may change on each start.** Collaborators must check Slack each morning.
7. **Shutdown is purely manual.** No scheduled stop, no reminder.

### Feature ideas (carried forward)

8. **Web-based start/stop UI for collaborators.** See `memory/project_web_start_stop.md`.
9. **Idle detection is architecturally broken for persistent web services.** Worth raising as a Prism issue.

### Infrastructure issues (carried forward)

10. **Relaunch bristol-workspace with `--hibernation`.** Current instance doesn't support hibernate.
11. **Silent hibernate fallback is a UX problem.** Feature request candidate.
12. **No CLI option for additional CIDRs.** Prism doesn't support opening ports to arbitrary IP ranges at launch.
13. **Port 8888 (Jupyter)** still restricted to `142.204.67.0/24`.
14. **Security group on relaunch.** Prism creates a new security group per launch; the manual 8787 open-to-all edit will be lost.
15. **Guides don't document the security group workaround.**

## Important context

- User is Jake Bowers, political science faculty at UIUC, applied statistician. Collaborators are in Chile (earlier time zone, hence the 5 AM auto-start).
- Current workspace: "bristol-workspace" on `m7i.xlarge` in us-east-2. Does NOT support hibernation (launched without `--hibernation`).
- Security group `sg-0f316041b4b0cab8a` ("prism-access") has port 8787 manually opened to 0.0.0.0/0.
- The "research" idle policy is active but effectively non-functional due to RStudio Server background traffic.
- `start_bristol.sh` contains a Slack webhook URL -- do not commit this to a public repo without redacting it.
- Prism source is at `~/src/prism`. Claude has read permissions via `.claude/settings.local.json`.
- Persistent memory includes: Prism source location, web-based start/stop feature idea.
- Jake's global CLAUDE.md requires ASCII-only text (no unicode em dashes, smart quotes, etc.) in all files.
- AstroNvim upstream template moved to v6 on 2026-03-30. The `main` branch of `github.com/AstroNvim/template` is now v6.
