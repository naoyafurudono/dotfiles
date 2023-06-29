-- カーソル位置記憶
vim.cmd [[
  autocmd BufReadPost *
        \ if line("'\"") > 0 and line("'\"") <= line("$") |
        \   execute "normal! g'\"" |
        \ endif
]]

vim.o.autoindent = true
vim.o.smartindent = true
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.clipboard = vim.o.clipboard .. 'unnamedplus'
vim.api.nvim_set_keymap('i', 'jj', '<ESC>', { silent = true })
vim.o.nowrap = true

if vim.fn.has('mac') == 1 then
  vim.cmd [[
    autocmd InsertLeavePre * :call system('im-select com.apple.inputmethod.Kotoeri.RomajiTyping.Roman')
    " TODO  settup for copilot
    " use :Copilot help for document
  ]]
end

if vim.fn.has('unix') == 1 then
  vim.cmd [[
    autocmd InsertLeavePre * :call system('ibus engine xkb:us::eng')
  ]]
end

-- g:copilot_filetypes = {
--       'secret' = false
--       }
