vim.g.mapleader = " "
vim.lsp.enable('gopls')

-- 行番号の表示
vim.opt.number = true

-- True Color有効化
vim.opt.termguicolors = true

-- カラースキーム (Atom One Light)
require('onedark').setup({
  style = 'light',
  highlights = {
    GitSignsAdd = { fg = '#50a14f' },    -- 緑
    GitSignsChange = { fg = '#c18401' }, -- 黄
    GitSignsDelete = { fg = '#e45649' }, -- 赤
  },
})
require('onedark').load()

-- LSP診断の表示設定
vim.diagnostic.config({
  virtual_text = true,      -- 行末に警告/エラーを表示
  signs = true,             -- 左側にサインを表示
  underline = true,         -- 該当箇所に下線
  update_in_insert = false, -- インサートモード中は更新しない
  severity_sort = true,     -- 重要度順にソート
  float = {
    border = "rounded",
    source = true,          -- 診断のソースを表示
  },
})

-- 診断のキーマップ
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = '前の診断へ' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = '次の診断へ' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = '診断を表示' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = '診断一覧' })

-- gitsignsのハイライト定義
vim.api.nvim_set_hl(0, 'MyGitSignsAdd', { fg = '#50a14f' })
vim.api.nvim_set_hl(0, 'MyGitSignsChange', { fg = '#c18401' })
vim.api.nvim_set_hl(0, 'MyGitSignsDelete', { fg = '#e45649' })

-- gitsigns (git行ステータス表示)
local ok_gitsigns, gitsigns = pcall(require, 'gitsigns')
if ok_gitsigns then
  gitsigns.setup({
    signs = {
      add          = { text = '│', hl = 'MyGitSignsAdd' },
      change       = { text = '│', hl = 'MyGitSignsChange' },
      delete       = { text = '_', hl = 'MyGitSignsDelete' },
      topdelete    = { text = '‾', hl = 'MyGitSignsDelete' },
      changedelete = { text = '~', hl = 'MyGitSignsChange' },
    },
  })
end

-- gitlinker (GitHub パーマリンク)
local ok_gitlinker, gitlinker = pcall(require, 'gitlinker')
if ok_gitlinker then
  gitlinker.setup({
    mappings = "<leader>gy", -- ビジュアルモードで選択範囲のGitHubリンクをコピー
  })
end

