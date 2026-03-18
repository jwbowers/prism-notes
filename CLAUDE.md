# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

Documentation and configuration for cloud research workstations built on [Prism](https://github.com/scttfrdmn/prism). There is no application code to build, test, or lint. The repo contains:

- A **Prism template** (`r-research-complete.yml`) that provisions a complete R research environment (RStudio Server, Neovim/AstroNvim, Quarto, LaTeX, Python/Jupyter) on an EC2 instance
- **Operational guides** for launching workspaces, managing collaborators, and controlling costs
- A **standalone shell script** (`setup-astro-nvim.sh`) for installing Neovim + AstroNvim on any Ubuntu machine

## Template architecture

`r-research-complete.yml` is a Prism template file with these sections, in order:

1. **Metadata** — name, slug, description, version, base image (`ubuntu-24.04`)
2. **Parameters** — user-configurable values (RStudio password, git identity, GitHub repo URL, Neovim toggle). Uses Go template syntax: `{{.parameter_name}}`, `{{if .flag}}...{{end}}`, `{{if ne .param ""}}`
3. **Packages** — APT packages grouped by purpose (system, R deps, LaTeX, databases, Python, etc.)
4. **Services/ports** — RStudio on 8787, Jupyter on 8888, SSH on 22
5. **`post_install`** — a large bash script (embedded in YAML) that runs via cloud-init after boot. Installs R, RStudio Server, Quarto, R packages (via Posit Package Manager binaries), JupyterLab, Git LFS, optionally Neovim/AstroNvim, configures SSH deploy keys for GitHub, and installs the `add-collaborator` helper script

### Key design decisions in the template

- **LaTeX subset, not `texlive-full`**: The full meta-package (~5 GB) times out on EC2 mirrors. The curated subset covers academic publishing with R/Quarto/biblatex/tikz/XeTeX plus Spanish language support.
- **Posit Package Manager**: R packages install as pre-built binaries (`packagemanager.posit.co/cran/__linux__/noble/latest`) instead of compiling from source.
- **JupyterLab in a venv**: Installed in `/opt/jupyterlab` with `--system-site-packages` to avoid pip/apt conflicts under Ubuntu 24.04's PEP 668 restrictions.
- **Deploy key model**: A single ed25519 key in `/etc/prism/` is shared across all user accounts for GitHub access to one repository. Individual git identity comes from per-user `git config`.

## Prism source code

The Prism tool itself lives at `~/src/prism`. Consult that codebase when answering questions about how Prism works, its template format, CLI commands, or internal behavior.

## Editing conventions

- The guides (`prism-workspace-guide.md`, `prism-github-collaboration-guide.md`) are written for researchers who may not be comfortable with the command line. Keep the tone direct and concrete, with copy-pasteable commands.
- The template YAML uses Go template conditionals. When editing the `post_install` script, preserve proper `{{if}}...{{end}}` nesting — these are processed by Prism before the script runs.
- The symlink workflow matters: users symlink the template into `~/.prism/` from this repo, so the filename `r-research-complete.yml` should not change without updating the guide.
