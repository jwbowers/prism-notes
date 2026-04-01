# Computational Workflow Notes

Personal notes on setting up and managing computational research environments, with a focus on cloud workstations via [Prism](https://github.com/scttfrdmn/prism).

## What's here

### Prism templates and guides

- **`r-research-complete.yml`** — Prism template for a complete R research environment (RStudio Server, Neovim/AstroNvim, Quarto, LaTeX, Python/Jupyter, and common R packages). Launches a ready-to-use cloud workstation.
- **`prism-workspace-guide.md`** — How to launch a Prism workspace, add collaborators, hibernate/resume instances, and set idle policies to control costs.
- **`prism-github-collaboration-guide.md`** — Step-by-step guide for configuring GitHub access on a shared Prism instance using deploy keys, so collaborators can pull/commit/push from RStudio without touching SSH keys or the terminal.

### Automated daily startup

The Bristol workspace needs to be running before collaborators in earlier time zones start their day. Since Prism's idle detection never fires when RStudio Server is running (background keepalives exceed the network threshold), the workflow is: auto-start in the morning, manual stop when everyone is done.

**`start_bristol.sh`** starts the workspace, waits for it to reach RUNNING state, and posts the public IP to a Slack channel so collaborators know where to connect. It retries up to 3 times before posting a failure notice.

The script runs on a local Mac via cron. Because a sleeping Mac will not fire cron jobs, `pmset` wakes the machine 5 minutes before the job:

```bash
# Wake the Mac at 4:55 AM every day
sudo pmset repeat wakeorpoweron MTWRFSU 04:55:00

# Crontab entry (crontab -e) -- runs at 5:00 AM daily
0 5 * * * /bin/bash ~/repos/prism-notes/start_bristol.sh >> ~/repos/prism-notes/start_bristol.log 2>&1
```

**Shutdown is manual.** RStudio Server's background processes (health pings, session keepalives, rsession daemons) generate enough network traffic that the Prism "research" idle policy never considers the instance idle. Stop the workspace by hand when collaborators are done for the day:

```bash
prism workspace stop bristol-workspace
```

### Editor setup

- **`setup-astro-nvim.sh`** --- Standalone script to install Neovim + AstroNvim with R.nvim, treesitter, and LSP support on a Prism instance (or any Ubuntu machine).
