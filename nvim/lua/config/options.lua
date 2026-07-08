vim.g.mapleader = " "

-- インデント設定（デフォルト）
vim.opt.tabstop = 2
vim.opt.shiftwidth = 0  -- tabstopの値を使う
vim.opt.expandtab = true

-- 行番号の表示
vim.opt.number = true

-- True Color有効化
vim.opt.termguicolors = true

-- winbarにファイル名とカーソル位置を表示
vim.opt.winbar = '%f  %l:%c'

-- 外部でファイルが変更されたらバッファに自動反映
vim.opt.autoread = true
vim.api.nvim_create_autocmd({"FocusGained", "BufEnter", "CursorHold"}, {
  command = "checktime",
})

-- クリップボードと同期
vim.opt.clipboard = 'unnamedplus'

-- ステータスラインを非表示
vim.opt.laststatus = 0
