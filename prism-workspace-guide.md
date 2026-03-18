# Prism Workspace Guide: Collaboration and Cost Management

This guide covers how to set up a shared research workspace on Prism,
invite collaborators, and manage costs through hibernation and idle
policies.

## Setup

First we are using our own template that we are storing outside of the ~/.prism
directory for ease in maintenance. So we need to have done this first and after
doing `prism init`  and after pulling/updating the prism-notes directory from
github.

```bash
ln -s ~/repos/prism-notes/r-research-complete.yml r-research-complete.yml
```

## Launching a workspace

```bash
prism workspace launch "R Research Complete" jake-workspace
```

The post-install script runs via cloud-init in the background after the
instance boots. The workspace is SSH-accessible immediately, but
software installation (R, RStudio, Quarto, LaTeX, etc.) continues for
15--30 minutes. Monitor progress with:

```bash
# From your local machine
prism logs jake-workspace --type cloud-init-out --follow

# Or from inside the instance
tail -f /var/log/cloud-init-output.log
```

Check whether setup is complete:

```bash
# From inside the instance
cloud-init status
# "running" = still installing, "done" = ready
```

## Adding collaborators

Each collaborator gets their own user account on the instance. This
gives everyone a separate home directory, their own RStudio session, and
a distinct git identity.

### Create user accounts

```bash
prism user create maria --full-name "Maria Garcia" --email "maria@university.edu"
prism user create carlos --full-name "Carlos Silva" --email "carlos@university.edu"
```

This generates SSH keys automatically. Retrieve connection details with:

```bash
prism user info maria
prism user keys list maria
```

### How collaborators connect

**RStudio Server (recommended for collaborators with limited local
resources):** Open a browser to `http://<workspace-ip>:8787` and log in
with the username and system password. All computation runs on the
instance---collaborators only need a web browser.

**SSH:** Connect via terminal for command-line work.

**Jupyter Lab:** Start from the terminal with `jupyter lab --ip=0.0.0.0
--no-browser`, then open `http://<workspace-ip>:8888` in a browser.

### Collaborative git workflow

Since everyone is on the same instance, git operations are fast
regardless of each person's local internet speed. A reasonable workflow:

1. Keep a shared project directory (e.g., `/home/researcher/projects/`
   or a location all users can access).
2. Each collaborator works on their own branch.
3. Commit under their own name, push to the remote repository.
4. Merge via pull requests on GitHub.

Each research user has their own git identity, so commits are properly
attributed.

## Saving money when no one is using it

An `m7i.xlarge` costs roughly $0.20/hour. Left running 24/7, that is
about $144/month. If your team works 8 hours/day on weekdays (~168
hours/month), hibernating during off-hours cuts the bill by roughly 75%.

### Hibernate and resume (recommended)

Hibernate saves the full memory state to disk, then stops the instance.
When you resume, open R sessions, Jupyter notebooks, and unsaved work
are restored exactly as you left them.

```bash
# When everyone is done for the day
prism workspace hibernate jake-workspace --wait

# When someone needs it again
prism workspace resume jake-workspace --wait
```

### Stop and start

Stop shuts down the instance without saving memory state. Installed
software and files on disk survive, but anything in RAM (open R
sessions, variables in memory) is lost.

```bash
prism workspace stop jake-workspace
prism workspace start jake-workspace
```

Use stop instead of hibernate when you don't need to preserve in-memory
state and want to avoid the EBS storage cost of the memory snapshot.

### Automatic idle policies

Apply an idle policy so the workspace hibernates or stops on its own
when no one is using it:

```bash
# Apply the research-optimized policy
prism idle policy apply jake-workspace research

# Check what the policy does
prism idle policy details research
```

The `research` policy:

- **Nightly hibernation window:** 2:00 AM -- 6:00 AM daily.
- **Idle detection:** Stops the instance after 15 minutes of low CPU
  (<20%), low memory (<30%), and low network (<10 MB/s) activity.
- **Estimated savings:** ~45%.

Other available policies:

| Policy           | Savings | Best for                         |
|------------------|---------|----------------------------------|
| `conservative`   | ~15%    | Production, always-on workloads  |
| `balanced`       | ~40%    | General use                      |
| `research`       | ~45%    | ML, data science, research       |
| `aggressive-cost`| ~65%    | Dev/test environments            |
| `development`    | ~75%    | Development instances            |

List all policies with `prism idle policy list`.

## Quick reference

| Task                        | Command                                              |
|-----------------------------|------------------------------------------------------|
| Launch workspace            | `prism workspace launch "template" name`             |
| Connect via SSH             | `prism workspace connect name`                       |
| List workspaces             | `prism workspace list`                               |
| Monitor setup progress      | `prism logs name --type cloud-init-out --follow`     |
| Add a collaborator          | `prism user create username --full-name "Name"`      |
| Hibernate (save state)      | `prism workspace hibernate name --wait`              |
| Resume from hibernation     | `prism workspace resume name --wait`                 |
| Stop (discard memory state) | `prism workspace stop name`                          |
| Start after stop            | `prism workspace start name`                         |
| Apply idle policy           | `prism idle policy apply name research`              |
| Delete workspace            | `prism workspace delete name`                        |
