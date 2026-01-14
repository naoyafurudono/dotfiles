vim.g.mapleader = " "

-- 行番号の表示
vim.opt.number = true

-- True Color有効化
vim.opt.termguicolors = true

-- winbarにファイル名とカーソル位置を表示
vim.opt.winbar = '%f  %l:%c'

-- クリップボードと同期
vim.opt.clipboard = 'unnamedplus'

-- ステータスラインを非表示
vim.opt.laststatus = 0

-- colorme 配下のPHPファイルはeuc-jpで開く
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*/colorme/*.php",
  callback = function()
    if vim.bo.fileencoding ~= "euc-jp" then
      vim.cmd("edit ++enc=euc-jp")
    end
  end,
})
