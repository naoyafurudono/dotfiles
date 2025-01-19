-- 一般的な設定
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.clipboard = vim.o.clipboard .. 'unnamedplus'
vim.api.nvim_set_keymap('i', 'jj', '<ESC>', { silent = true })
vim.o.number = true

if vim.fn.has('unix') == 1 then
  vim.cmd [[
    autocmd InsertLeavePre * :call system('ibus engine xkb:us::eng')
  ]]
end
