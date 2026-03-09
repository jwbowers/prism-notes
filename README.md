# Computational Workflow Notes

Personal notes on setting up and managing computational research environments, with a focus on cloud workstations via [Prism](https://github.com/scttfrdmn/prism).

## What's here

### Prism templates and guides

- **`r-research-complete.yml`** — Prism template for a complete R research environment (RStudio Server, Neovim/AstroNvim, Quarto, LaTeX, Python/Jupyter, and common R packages). Launches a ready-to-use cloud workstation.
- **`prism-workspace-guide.md`** — How to launch a Prism workspace, add collaborators, hibernate/resume instances, and set idle policies to control costs.
- **`prism-github-collaboration-guide.md`** — Step-by-step guide for configuring GitHub access on a shared Prism instance using deploy keys, so collaborators can pull/commit/push from RStudio without touching SSH keys or the terminal.

### Editor setup

- **`setup-astro-nvim.sh`** — Standalone script to install Neovim + AstroNvim with R.nvim, treesitter, and LSP support on a Prism instance (or any Ubuntu machine).
