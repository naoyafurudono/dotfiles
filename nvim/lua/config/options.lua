vim.g.mapleader = " "

-- 行番号の表示
vim.opt.number = true

-- True Color有効化
vim.opt.termguicolors = true

-- ripgrepを:grepで使用
vim.opt.grepprg = 'rg --vimgrep --smart-case'
vim.opt.grepformat = '%f:%l:%c:%m'

-- grep後に自動でquickfixを開く
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  pattern = 'grep',
  callback = function()
    vim.cmd('copen')
  end,
})
