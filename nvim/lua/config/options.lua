vim.g.mapleader = " "

-- 行番号の表示
vim.opt.number = true

-- True Color有効化
vim.opt.termguicolors = true

-- ripgrepを:grepで使用
vim.opt.grepprg = 'rg --vimgrep --smart-case'
vim.opt.grepformat = '%f:%l:%c:%m'
