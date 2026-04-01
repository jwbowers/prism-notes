# Handoff Summary

Session date: 2026-04-01 (fourth session, extends prior handoffs)

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

### This session

11. **Updated README.md with automated daily startup documentation.** Added a new "Automated daily startup" section describing the full workflow for auto-starting the Bristol workspace before collaborators in earlier time zones begin work. The section documents:

   - **`start_bristol.sh`** -- the script that starts the workspace, waits for RUNNING state, and posts the public IP to Slack (with up to 3 retries and failure notification). This script was already committed in `c6a20bb`; this session documented it in the README.
   - **`pmset` wake schedule** -- `sudo pmset repeat wakeorpoweron MTWRFSU 04:55:00` wakes the Mac at 4:55 AM daily so cron can fire.
   - **Crontab entry** -- `0 5 * * * /bin/bash ~/repos/prism-notes/start_bristol.sh >> ~/repos/prism-notes/start_bristol.log 2>&1` runs the script at 5:00 AM.
   - **Why shutdown is manual** -- RStudio Server background traffic defeats Prism's idle detection, so the instance never looks idle. Stop by hand with `prism workspace stop bristol-workspace`.
   - Also fixed an em dash (unicode) to `---` (ASCII) in the editor setup bullet, per Jake's ASCII-only convention in his global CLAUDE.md.

## Key decisions made

1. **Auto-start + manual stop is the current operational workflow.** The Mac wakes at 4:55 AM, cron fires `start_bristol.sh` at 5:00 AM, Slack gets the IP. Jake stops the workspace manually when collaborators are done.
2. **Idle detection is not relied upon.** Still effectively broken for RStudio Server workloads (see session 3 notes above).
3. **Documentation-only session.** The `start_bristol.sh` script and cron/pmset config already existed; this session added the README documentation explaining them.

## Files changed

### Modified (not yet committed)

- **`README.md`** -- Added "Automated daily startup" section between the guides list and the editor setup section. Documents `start_bristol.sh`, the `pmset` wake command, the crontab entry, and why manual shutdown is necessary. Fixed one unicode em dash to ASCII `---`.

### Not modified

- `start_bristol.sh` -- already committed in `c6a20bb`, unchanged this session.
- `HANDOFF.md` -- this file (rewritten this session).

### Git state

- Branch: `main`, 1 commit ahead of `origin/main` (commit `c6a20bb` not yet pushed).
- `README.md` has unstaged changes from this session.
- No other uncommitted work.

## Open questions / potential follow-ups

### Active operational concerns

1. **The Mac must stay plugged in and not shut down for the cron workflow to work.** If the Mac is off (not just sleeping), `pmset wakeorpoweron` cannot wake it. Power outages or manual shutdowns will silently skip the morning start. There is no monitoring for missed starts -- the only signal is that collaborators don't get a Slack message.
2. **The public IP may change on each start.** The Slack notification handles this, but collaborators need to check Slack for the current IP each morning rather than bookmarking a fixed address.
3. **Shutdown is purely manual.** No scheduled stop, no reminder. If Jake forgets, the instance runs (and costs money) until someone notices.

### Feature ideas (carried forward)

4. **Web-based start/stop UI for collaborators.** The main unbuilt feature idea. Minimal version: static HTML page + Lambda + API Gateway, with auth via shared URL secret or lightweight login. See `memory/project_web_start_stop.md`.
5. **Idle detection is architecturally broken for persistent web services.** Worth raising as a Prism issue. Possible fixes: (a) raise network threshold, (b) add on-instance agent, (c) CPU-only detection.

### Infrastructure issues (carried forward)

6. **Relaunch bristol-workspace with `--hibernation`.** Current instance doesn't support hibernate. Relaunch requires: commit all work to GitHub, tear down, relaunch with flag, redo collaborator accounts and security group changes.
7. **Silent hibernate fallback is a UX problem.** `prism workspace hibernate` falls back to stop without warning. Feature request candidate.
8. **No CLI option for additional CIDRs.** Prism doesn't support opening ports to arbitrary IP ranges at launch time.
9. **Port 8888 (Jupyter)** still restricted to `142.204.67.0/24`.
10. **Security group on relaunch.** Prism creates a new security group per launch, so the manual 8787 open-to-all edit will be lost.
11. **Guides don't document the security group workaround.**

## Important context

- User is Jake Bowers, political science faculty at UIUC, applied statistician. Collaborators are in Chile (earlier time zone, hence the 5 AM auto-start).
- Current workspace: "bristol-workspace" on `m7i.xlarge` in us-east-2. Does NOT support hibernation (launched without `--hibernation`).
- Security group `sg-0f316041b4b0cab8a` ("prism-access") has port 8787 manually opened to 0.0.0.0/0.
- The "research" idle policy is active but effectively non-functional due to RStudio Server background traffic.
- `start_bristol.sh` contains a Slack webhook URL -- do not commit this to a public repo without redacting it.
- Prism source is at `~/src/prism`. Claude has read permissions via `.claude/settings.local.json`.
- Persistent memory includes: Prism source location, web-based start/stop feature idea.
- Jake's global CLAUDE.md requires ASCII-only text (no unicode em dashes, smart quotes, etc.) in all files.
