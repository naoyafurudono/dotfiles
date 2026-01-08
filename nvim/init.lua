vim.g.mapleader = " "

-- 行番号の表示
vim.opt.number = true

-- True Color有効化
vim.opt.termguicolors = true

-- lazy.nvim ブートストラップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- プラグイン設定
require("lazy").setup({
  -- カラースキーム
  {
    "navarasu/onedark.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require('onedark').setup({
        style = 'light',
        highlights = {
          GitSignsAdd = { fg = '#50a14f' },
          GitSignsChange = { fg = '#c18401' },
          GitSignsDelete = { fg = '#e45649' },
        },
      })
      require('onedark').load()
    end,
  },

  -- LSP設定
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.enable('gopls')
    end,
  },

  -- gitsigns
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      vim.api.nvim_set_hl(0, 'MyGitSignsAdd', { fg = '#50a14f' })
      vim.api.nvim_set_hl(0, 'MyGitSignsChange', { fg = '#c18401' })
      vim.api.nvim_set_hl(0, 'MyGitSignsDelete', { fg = '#e45649' })

      require('gitsigns').setup({
        signs = {
          add          = { text = '│', hl = 'MyGitSignsAdd' },
          change       = { text = '│', hl = 'MyGitSignsChange' },
          delete       = { text = '_', hl = 'MyGitSignsDelete' },
          topdelete    = { text = '‾', hl = 'MyGitSignsDelete' },
          changedelete = { text = '~', hl = 'MyGitSignsChange' },
        },
      })
    end,
  },

  -- gitlinker (GitHub パーマリンク)
  {
    "ruifm/gitlinker.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require('gitlinker').setup({
        mappings = "<leader>gy",
      })
    end,
  },
})

-- LSP診断の表示設定
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
  },
})

-- 診断のキーマップ
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = '前の診断へ' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = '次の診断へ' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = '診断を表示' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = '診断一覧' })
