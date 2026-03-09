#!/bin/bash
# Setup AstroNvim with R.nvim on a Prism research instance
# Usage: scp this to the instance, then run it
#
#   scp setup-astro-nvim.sh jwbowers@<instance-ip>:~
#   ssh jwbowers@<instance-ip>
#   chmod +x setup-astro-nvim.sh
#   sudo ./setup-astro-nvim.sh
#
# Or in one shot:
#   scp setup-astro-nvim.sh jwbowers@<ip>:~ && ssh jwbowers@<ip> 'chmod +x setup-astro-nvim.sh && sudo ./setup-astro-nvim.sh'

set -e

# Who is the target user? Default to whoever invoked sudo, fall back to jwbowers
TARGET_USER="${SUDO_USER:-jwbowers}"
TARGET_HOME=$(eval echo "~${TARGET_USER}")

echo "Setting up AstroNvim for user: ${TARGET_USER}"
echo ""

# --- Install neovim from GitHub releases ---
if command -v nvim &>/dev/null; then
    echo "Neovim already installed: $(nvim --version | head -n1)"
else
    echo "Installing Neovim (latest stable)..."
    curl -sLO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    rm nvim-linux-x86_64.tar.gz
    ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    echo "Installed: $(nvim --version | head -n1)"
fi

# --- Install dependencies ---
echo "Installing dependencies (ripgrep, fd-find, nodejs, npm, xclip)..."
apt-get update -qq
apt-get install -y -qq ripgrep fd-find nodejs npm xclip >/dev/null

# --- Clone AstroNvim starter ---
NVIM_CONFIG="${TARGET_HOME}/.config/nvim"

if [ -d "${NVIM_CONFIG}" ]; then
    echo "Existing nvim config found at ${NVIM_CONFIG}"
    echo "Backing up to ${NVIM_CONFIG}.bak"
    rm -rf "${NVIM_CONFIG}.bak"
    mv "${NVIM_CONFIG}" "${NVIM_CONFIG}.bak"
fi

echo "Cloning AstroNvim starter template..."
git clone --depth 1 https://github.com/AstroNvim/template "${NVIM_CONFIG}"
rm -rf "${NVIM_CONFIG}/.git"

mkdir -p "${NVIM_CONFIG}/lua/plugins"

# --- init.lua ---
cat > "${NVIM_CONFIG}/init.lua" <<'ENDFILE'
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  local result = vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { ("Error cloning lazy.nvim:\n%s\n"):format(result), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
    vim.fn.getchar()
    vim.cmd.quit()
  end
end
vim.opt.rtp:prepend(lazypath)
if not pcall(require, "lazy") then
  vim.api.nvim_echo({ { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end
require "lazy_setup"
require "polish"
ENDFILE

# --- lazy_setup.lua ---
cat > "${NVIM_CONFIG}/lua/lazy_setup.lua" <<'ENDFILE'
require("lazy").setup({
  {
    "AstroNvim/AstroNvim",
    import = "astronvim.plugins",
    opts = {
      mapleader = " ",
      maplocalleader = "\\",
      icons_enabled = true,
      pin_plugins = nil,
      update_notifications = true,
    },
  },
  { import = "community" },
  { import = "plugins" },
}, {
  install = { colorscheme = { "astrotheme" } },
  ui = { backdrop = 100 },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "netrwPlugin", "tarPlugin", "tohtml", "zipPlugin",
      },
    },
  },
})
ENDFILE

# --- community.lua ---
cat > "${NVIM_CONFIG}/lua/community.lua" <<'ENDFILE'
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.colorscheme.catppuccin" },
  { import = "astrocommunity.colorscheme.solarized-osaka-nvim" },
  { import = "astrocommunity.colorscheme.monokai-pro-nvim" },
}
ENDFILE

# --- plugins/r-nvim.lua ---
cat > "${NVIM_CONFIG}/lua/plugins/r-nvim.lua" <<'ENDFILE'
return {
  {
    "R-nvim/R.nvim",
    branch = "main",
    lazy = false,
    opts = {
      pdfviewer = "",
    },
    config = function(_, opts)
      vim.g.rout_follow_colorscheme = true
      require("r").setup(opts)
      require("r.pdf.generic").open = vim.ui.open
    end,
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "shunsambongi/neotest-testthat",
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
  { "shunsambongi/neotest-testthat" },
}
ENDFILE

# --- plugins/treesitter.lua ---
cat > "${NVIM_CONFIG}/lua/plugins/treesitter.lua" <<'ENDFILE'
return {
  "nvim-treesitter/nvim-treesitter",
  run = ":TSUpdate",
  opts = {
    ensure_installed = {
      "lua", "vim", "markdown", "markdown_inline",
      "r", "rnoweb", "yaml", "latex", "csv",
    },
  },
}
ENDFILE

# --- plugins/mason.lua ---
cat > "${NVIM_CONFIG}/lua/plugins/mason.lua" <<'ENDFILE'
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "debugpy",
        "tree-sitter-cli",
      },
    },
  },
}
ENDFILE

# --- plugins/astrocore.lua ---
cat > "${NVIM_CONFIG}/lua/plugins/astrocore.lua" <<'ENDFILE'
return {
  "AstroNvim/astrocore",
  opts = {
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 },
      autopairs = true,
      cmp = true,
      diagnostics = { virtual_text = true, virtual_lines = false },
      highlighturl = true,
      notifications = true,
    },
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    options = {
      opt = {
        relativenumber = false,
        number = true,
        spell = false,
        signcolumn = "yes",
        wrap = true,
      },
    },
    mappings = {
      n = {
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },
        ["c"] = false,
      },
    },
  },
}
ENDFILE

# --- plugins/astroui.lua ---
cat > "${NVIM_CONFIG}/lua/plugins/astroui.lua" <<'ENDFILE'
return {
  "AstroNvim/astroui",
  opts = {
    colorscheme = "astrodark",
  },
}
ENDFILE

# --- plugins/astrolsp.lua ---
cat > "${NVIM_CONFIG}/lua/plugins/astrolsp.lua" <<'ENDFILE'
return {
  "AstroNvim/astrolsp",
  opts = {
    features = {
      codelens = true,
      inlay_hints = false,
      semantic_tokens = true,
    },
    formatting = {
      format_on_save = { enabled = true },
      timeout_ms = 1000,
    },
  },
}
ENDFILE

# --- plugins/none-ls.lua ---
cat > "${NVIM_CONFIG}/lua/plugins/none-ls.lua" <<'ENDFILE'
return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require "null-ls"
    opts.sources = require("astrocore").list_insert_unique(opts.sources, {})
    table.insert(opts.sources, null_ls.builtins.diagnostics.write_good)
    return opts
  end,
}
ENDFILE

# --- plugins/user.lua ---
cat > "${NVIM_CONFIG}/lua/plugins/user.lua" <<'ENDFILE'
return {
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function() require("lsp_signature").setup() end,
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    opts = {
      bigfile = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      picker = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      dashboard = { enabled = true },
    },
  },
  { "max397574/better-escape.nvim", enabled = false },
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.luasnip"(plugin, opts)
      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", { "javascriptreact" })
    end,
  },
  {
    "windwp/nvim-autopairs",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts)
      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      local cond = require "nvim-autopairs.conds"
      npairs.add_rules({
        Rule("$", "$", { "tex", "latex" })
          :with_pair(cond.not_after_regex "%%")
          :with_pair(cond.not_before_regex("xxx", 3))
          :with_move(cond.none())
          :with_del(cond.not_after_regex "xx")
          :with_cr(cond.none()),
        Rule("a", "a", "-vim"),
      })
    end,
  },
}
ENDFILE

# --- polish.lua ---
cat > "${NVIM_CONFIG}/lua/polish.lua" <<'ENDFILE'
if true then return end
ENDFILE

# --- Fix ownership ---
chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config"
mkdir -p "${TARGET_HOME}/.local/share/nvim"
chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.local"

# --- Bootstrap plugins ---
echo ""
echo "Installing plugins (this takes about a minute)..."
su - "${TARGET_USER}" -c 'nvim --headless "+Lazy! sync" +qa 2>/dev/null' || true

echo ""
echo "============================================="
echo "  AstroNvim setup complete"
echo ""
echo "  Leader:       Space  (AstroNvim commands)"
echo "  LocalLeader:  \\      (R.nvim commands)"
echo ""
echo "  Quick start:"
echo "    nvim my_analysis.R"
echo "    \\rf   - start R console"
echo "    \\l    - send current line to R"
echo "    \\ss   - send visual selection to R"
echo "    \\rq   - quit R"
echo "============================================="
