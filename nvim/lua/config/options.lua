vim.g.mapleader = " "

-- 行番号の表示
vim.opt.number = true

-- True Color有効化
vim.opt.termguicolors = true

-- ripgrepを:grepで使用
vim.opt.grepprg = 'rg --vimgrep --smart-case'
vim.opt.grepformat = '%f:%l:%c:%m'

-- :Rg コマンド（最初のファイルにジャンプしない）
vim.api.nvim_create_user_command('Rg', function(opts)
  vim.cmd('silent grep! ' .. opts.args)
end, { nargs = '+' })

-- grep後に自動でquickfixを開いてフォーカス
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  pattern = 'grep',
  callback = function()
    vim.schedule(function()
      vim.cmd('copen')
      -- quickfixウィンドウを探してフォーカス
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == 'quickfix' then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
    end)
  end,
})

-- quickfixウィンドウの設定
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function()
    -- タイトルを表示
    local title = vim.fn.getqflist({ title = 0 }).title
    if title and title ~= '' then
      vim.wo.winbar = title
    end
    -- バッファに名前を付ける
    local bufnr = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_buf_set_name, bufnr, '[Quickfix List]')
  end,
})
