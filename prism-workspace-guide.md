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

The simplest launch uses just the template name and a workspace name:

```bash
prism workspace launch "R Research Complete" jake-workspace
```

### Template parameters

The R Research Complete template accepts `--param` flags that customize
the workspace at launch time. Parameters you don't set use sensible
defaults.

**RStudio password.** RStudio Server requires a system password for
login. By default a random password is generated. You can set your own:

```bash
prism workspace launch "R Research Complete" jake-workspace \
  --param rstudio_password="my-chosen-password"
 --param primary_user_email="jake@jakebowers.org" --param primary_user_name="Jake Bowers"
```

If you let the template generate a random password, retrieve it after
setup completes by SSH-ing into the instance and running:

```bash
cat ~/.rstudio-credentials
```

The credentials file is readable only by your user (mode 600). You can
also reset the password at any time with `sudo passwd jwbowers`.

**Git identity.** Set your name and email so git commits on the
workspace are attributed correctly:

```bash
prism workspace launch "R Research Complete" jake-workspace \
  --param primary_user_name="Jake Bowers" \
  --param primary_user_email="jake@jakebowers.org"
```

**GitHub repository.** Auto-clone a repository into `~/projects/` at
launch. The template generates a deploy key --- after launch, add the
public key to the repo's deploy keys on GitHub (the key is printed in
the cloud-init log and saved to `~/.ssh/github_deploy_key.pub`):

```bash
prism workspace launch "R Research Complete" jake-workspace \
  --param github_repo_url="git@github.com:org/repo.git"
```

**Neovim.** Neovim + AstroNvim is installed by default. To skip it or
to supply your own config:

```bash
# Skip neovim entirely
--param install_neovim=false

# Use your own neovim config repository
--param neovim_config_repo="https://github.com/you/nvim-config.git"
```

**Putting it all together.** A typical launch with all the common
parameters:

```bash
prism workspace launch "R Research Complete" jake-workspace \
  --param rstudio_password="my-password" \
  --param primary_user_name="Jake Bowers" \
  --param primary_user_email="jwbowers@illinois.edu" \
  --param github_repo_url="git@github.com:org/repo.git"
```

### All available parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `rstudio_password` | (random) | Password for RStudio Server login |
| `primary_user_name` | (empty) | Your name for git commits |
| `primary_user_email` | (empty) | Your email for git commits |
| `github_repo_url` | (empty) | SSH URL of repo to auto-clone |
| `rstudio_version` | `latest` | RStudio Server version |
| `install_neovim` | `true` | Install Neovim + AstroNvim |
| `neovim_config_repo` | (empty) | Git URL for custom Neovim config |
| `install_languageserver` | `true` | Install R language server for LSP |
| `install_renv` | `true` | Install renv for reproducible environments |

### After launch: apply idle policy

The template does not automatically apply an idle policy. Apply one
right after launch so the workspace hibernates when nobody is using it:

```bash
prism idle policy apply jake-workspace research
```

This auto-hibernates after 30 minutes of inactivity. A hibernated
instance costs only EBS storage (~$0.24/day for the 80 GB volume)
instead of ~$19/day running. Resume takes about 30--60 seconds and
restores everything in memory.

### Monitoring setup progress

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

### GitHub access for RStudio-only collaborators

Collaborators who only use RStudio (no command line) can push and pull
from GitHub without any terminal setup. The workspace handles SSH key
configuration automatically. Here is what happens and what each person
needs to do.

**What the workspace admin does (once, at setup):**

1. Launch the workspace with a GitHub repo URL:
   ```bash
   prism workspace launch "R Research Complete" jake-workspace \
     --param github_repo_url="git@github.com:org/repo.git"
   ```

2. Add the workspace deploy key to GitHub. SSH into the instance and
   print the public key:
   ```bash
   cat /etc/prism/github_deploy_key.pub
   ```
   Then go to the GitHub repository: **Settings > Deploy keys > Add
   deploy key**. Paste the key and check **Allow write access**.

3. Add each collaborator:
   ```bash
   sudo add-collaborator maria "Maria Garcia" maria@university.edu
   ```
   This creates their account, configures their SSH key for GitHub,
   sets their git identity, and clones the repo into their home
   directory. **Save the password it prints** --- the collaborator
   needs it to log into RStudio.

**What you send the collaborator:**

> Open your browser to `http://<workspace-ip>:8787`
>
> - Username: `maria`
> - Password: (the password from the add-collaborator output)
>
> The project is already cloned in `~/projects/<repo-name>/`.

**How the collaborator uses git from RStudio (no terminal needed):**

1. **Open the project.** In RStudio: File > Open Project, navigate to
   `~/projects/<repo-name>/`, and open the `.Rproj` file (or any file
   in the directory).

2. **Pull before working.** In the Git pane (top-right by default),
   click the blue **Pull** arrow. This fetches the latest changes from
   GitHub.

3. **Edit files normally.** Work in the editor. Modified files appear
   in the Git pane with an "M" status.

4. **Commit changes.** In the Git pane, check the boxes next to the
   files to stage. Click **Commit**. Write a short message describing
   the changes, then click **Commit**.

5. **Push to GitHub.** Click the green **Push** arrow. The changes go
   to GitHub under the collaborator's name and email.

6. **Create a branch (optional).** In the Git pane, click the purple
   branch icon next to "main". Type a branch name and click **Create**.
   Work on the branch, commit, and push. The collaborator (or you) can
   open a pull request on GitHub to merge.

**If RStudio does not show the Git pane:** the project directory may
not be recognized as a git repository. In RStudio, go to
Tools > Terminal > New Terminal, then run:

```
cd ~/projects/<repo-name>
git status
```

If git is working there, close and reopen the project (File > Open
Project) and the Git pane should appear.

**If push fails with "Permission denied":** the deploy key may not
have write access on GitHub. Ask the admin to check Settings > Deploy
keys and confirm "Allow write access" is checked.

### Collaborative git workflow

Since everyone is on the same instance, git operations are fast
regardless of each person's local internet speed. A reasonable workflow:

1. Each collaborator works in their own home directory
   (`~/projects/<repo-name>/`).
2. Pull before starting work.
3. Each collaborator works on their own branch.
4. Commit under their own name, push to the remote repository.
5. Merge via pull requests on GitHub.

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
| Launch with params          | `prism workspace launch "template" name --param key=value` |
| Connect via SSH             | `prism workspace connect name`                       |
| List workspaces             | `prism workspace list`                               |
| List (refresh from AWS)     | `prism workspace list --refresh`                     |
| Monitor setup progress      | `prism logs name --type cloud-init-out --follow`     |
| Get RStudio password        | `cat ~/.rstudio-credentials` (on instance)           |
| Add a collaborator          | `prism user create username --full-name "Name"`      |
| Hibernate (save state)      | `prism workspace hibernate name --wait`              |
| Resume from hibernation     | `prism workspace resume name --wait`                 |
| Stop (discard memory state) | `prism workspace stop name`                          |
| Start after stop            | `prism workspace start name`                         |
| Apply idle policy           | `prism idle policy apply name research`              |
| Delete workspace            | `prism workspace delete name`                        |
