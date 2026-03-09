# Setting Up GitHub Collaboration on a Prism Research Instance

This guide walks you through configuring a Prism cloud workstation so that
collaborators can pull, commit, and push to a shared GitHub repository from
RStudio's Git tab --- without touching SSH keys or the terminal.

The approach uses a **deploy key**: a single SSH key that lives on the instance
and authenticates to one GitHub repository. You set it up once. Every user
account on the instance inherits access through a copy of that key. Their
commits carry their own name and email.

**Prerequisites**: A running Prism instance with RStudio Server (the
`r-research-complete` template, `r-rstudio-server`, or any R template that
includes RStudio). SSH access to the instance as the `jwbowers` user.

---

## Part 1: Generate the Deploy Key

SSH into your instance:

```bash
prism workspace connect my-analysis
```

Generate an ed25519 key pair and store it in a shared location:

```bash
sudo mkdir -p /etc/prism
sudo ssh-keygen -t ed25519 -f /etc/prism/github_deploy_key -N "" -C "prism-deploy-key"
sudo chmod 640 /etc/prism/github_deploy_key
sudo chgrp sudo /etc/prism/github_deploy_key
```

Display the public key:

```bash
sudo cat /etc/prism/github_deploy_key.pub
```

Copy the output. You will paste it into GitHub in the next step.

---

## Part 2: Add the Deploy Key to Your GitHub Repository

1. Open your repository on GitHub.
2. Go to **Settings > Deploy keys > Add deploy key**.
3. Give it a title (e.g., "Prism research instance").
4. Paste the public key.
5. **Check "Allow write access"** --- collaborators need to push, not just pull.
6. Click **Add key**.

The instance can now authenticate to this repository. No other repository is
affected.

---

## Part 3: Configure Your Own Account

Still on the instance, set up your `jwbowers` account to use the deploy key:

```bash
mkdir -p ~/.ssh
sudo cp /etc/prism/github_deploy_key ~/.ssh/github_deploy_key
chmod 600 ~/.ssh/github_deploy_key

cat > ~/.ssh/config <<'EOF'
Host github.com
    IdentityFile ~/.ssh/github_deploy_key
    StrictHostKeyChecking accept-new
EOF
chmod 600 ~/.ssh/config
```

Configure your git identity:

```bash
git config --global user.name "Jake Bowers"
git config --global user.email "your-email@illinois.edu"
```

Store the repo URL so the `add-collaborator` script knows which repo to clone
for new users:

```bash
echo "git@github.com:your-org/your-repo.git" | sudo tee /etc/prism/github_repo_url
```

Clone the repository:

```bash
git clone git@github.com:your-org/your-repo.git ~/projects/your-repo
```

Test the round trip:

```bash
cd ~/projects/your-repo
git pull
echo "test" >> /dev/null  # no actual change needed
git status
```

If `git pull` succeeds without a password prompt, the deploy key is working.

---

## Part 4: Install the add-collaborator Script

If you launched from the `r-research-complete` template (v1.0.0+), this script
is already installed at `/usr/local/bin/add-collaborator`. Otherwise, create it
manually:

```bash
sudo tee /usr/local/bin/add-collaborator > /dev/null <<'SCRIPT'
#!/bin/bash
set -e

if [ $# -lt 3 ]; then
    echo "Usage: sudo add-collaborator <username> \"<Full Name>\" <email>"
    echo ""
    echo "Example:"
    echo "  sudo add-collaborator jsmith \"Jane Smith\" jane.smith@university.edu"
    echo ""
    echo "Creates a user account, sets an RStudio password, configures git"
    echo "identity, copies the GitHub deploy key, and clones the project repo."
    exit 1
fi

USERNAME="$1"
FULLNAME="$2"
EMAIL="$3"

echo "Creating user: ${USERNAME}..."
useradd -m -s /bin/bash -G sudo "${USERNAME}" 2>/dev/null || true

PASSWORD=$(openssl rand -base64 12)
echo "${USERNAME}:${PASSWORD}" | chpasswd

su - "${USERNAME}" -c "git config --global user.name '${FULLNAME}'"
su - "${USERNAME}" -c "git config --global user.email '${EMAIL}'"

DEPLOY_KEY="/etc/prism/github_deploy_key"
if [ -f "${DEPLOY_KEY}" ]; then
    mkdir -p "/home/${USERNAME}/.ssh"
    cp "${DEPLOY_KEY}" "/home/${USERNAME}/.ssh/github_deploy_key"
    chmod 600 "/home/${USERNAME}/.ssh/github_deploy_key"

    cat > "/home/${USERNAME}/.ssh/config" <<SSHEOF
Host github.com
    IdentityFile ~/.ssh/github_deploy_key
    StrictHostKeyChecking accept-new
SSHEOF
    chmod 600 "/home/${USERNAME}/.ssh/config"
    chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.ssh"

    REPO_URL_FILE="/etc/prism/github_repo_url"
    if [ -f "${REPO_URL_FILE}" ]; then
        REPO_URL=$(cat "${REPO_URL_FILE}")
        REPO_NAME=$(basename "${REPO_URL}" .git)
        echo "Cloning ${REPO_URL}..."
        su - "${USERNAME}" -c "git clone '${REPO_URL}' ~/projects/${REPO_NAME}" \
            || echo "  Clone failed - is the deploy key added to GitHub?"
    fi
fi

su - "${USERNAME}" -c "mkdir -p ~/projects ~/data ~/scripts"

INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')
echo ""
echo "============================================="
echo "  Collaborator Added"
echo "  Username: ${USERNAME}"
echo "  Password: ${PASSWORD}"
echo "  Name:     ${FULLNAME}"
echo "  Email:    ${EMAIL}"
echo ""
echo "  RStudio:  http://${INSTANCE_IP}:8787"
echo "============================================="
echo ""
echo "Share these credentials with ${FULLNAME}."
echo "They can change their password in the RStudio terminal: passwd"
SCRIPT
sudo chmod +x /usr/local/bin/add-collaborator
```

---

## Part 5: Add a Collaborator

```bash
sudo add-collaborator jsmith "Jane Smith" jane.smith@university.edu
```

The script prints credentials. Send them to Jane. That is the only step.

Jane opens her browser, goes to `http://<instance-ip>:8787`, logs in with the
username and password you sent, and sees the project already cloned in
`~/projects/your-repo`. She clicks the **Git** tab in RStudio's top-right pane
and uses Pull, Commit, and Push.

Her commits show her name and email. She never interacts with SSH, the
terminal, or GitHub settings.

### Adding more collaborators

```bash
sudo add-collaborator mchen "Ming Chen" ming.chen@university.edu
sudo add-collaborator kgarcia "Kim Garcia" kgarcia@otheruni.edu
```

Each runs in a few seconds.

---

## Part 6: What Collaborators See in RStudio

When a collaborator opens RStudio and navigates to `~/projects/your-repo`:

1. **Git tab** (top-right pane): Shows changed files with checkboxes.
2. **Pull** (down arrow): Fetches and merges from GitHub. Click this before
   starting work.
3. **Stage** (checkboxes): Select files to include in a commit.
4. **Commit** (button): Opens a diff viewer and commit message box.
5. **Push** (up arrow): Sends commits to GitHub.

The workflow they should follow:

```
Pull  -->  Edit files  -->  Stage  -->  Commit  -->  Push
```

If they forget to pull first and someone else has pushed, RStudio will show a
merge conflict. The simplest resolution for non-technical users: save their
work, pull, and RStudio will attempt to merge automatically. If it fails, the
conflicting files show `<<<<<<<` markers. They should ask you for help at that
point rather than force-pushing.

---

## Removing a Collaborator

```bash
sudo deluser --remove-home jsmith
```

This deletes their account and home directory, including their copy of the
deploy key. They can no longer authenticate to the instance or to GitHub
through it.

---

## Multiple Repositories

Deploy keys are scoped to a single repository. If your team works across
several repos, you have two options:

**Option A: One deploy key per repo.** Generate additional keys with distinct
filenames and add separate `Host` entries in each user's `~/.ssh/config`:

```
Host github-repo-a
    HostName github.com
    IdentityFile ~/.ssh/deploy_key_repo_a
    StrictHostKeyChecking accept-new

Host github-repo-b
    HostName github.com
    IdentityFile ~/.ssh/deploy_key_repo_b
    StrictHostKeyChecking accept-new
```

Then clone using the alias: `git clone git@github-repo-a:org/repo-a.git`.

**Option B: GitHub machine user.** Create a dedicated GitHub account (e.g.,
`lab-bot`), grant it access to all relevant repos, and use its SSH key on the
instance. This is cleaner when you have more than two or three repos.

---

## Security Notes

- The deploy key grants access to **one repository**. It cannot read or write
  any other repo on GitHub.
- Every user on the instance shares the same authentication to GitHub, but
  commits carry individual identity (name and email from `git config`).
- If the instance is terminated or its EBS volume is deleted, the key is gone.
  Revoke it on GitHub under Settings > Deploy keys to be safe.
- Anyone with `sudo` on the instance can read the deploy key. This is
  appropriate for a trusted research team. For untrusted users, consider
  per-user keys instead.
- Collaborators should change their RStudio password after first login by
  opening the Terminal tab in RStudio and running `passwd`.

---

## Quick Reference

```bash
# Generate deploy key (one time)
sudo ssh-keygen -t ed25519 -f /etc/prism/github_deploy_key -N ""

# Show public key (paste into GitHub > Settings > Deploy keys)
sudo cat /etc/prism/github_deploy_key.pub

# Store repo URL for automatic cloning
echo "git@github.com:org/repo.git" | sudo tee /etc/prism/github_repo_url

# Add a collaborator
sudo add-collaborator <username> "<Full Name>" <email>

# Remove a collaborator
sudo deluser --remove-home <username>

# Reset a collaborator's password
echo "<username>:<new-password>" | sudo chpasswd
```
