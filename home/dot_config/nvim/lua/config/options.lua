vim.g.mapleader = " "

-- Esc 始まりの key sequence (Alt-キー等) の待ち時間を短縮
vim.opt.ttimeoutlen = 10

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

-- ファイルを開いたとき前回のカーソル位置を復元
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- クリップボードと同期
vim.opt.clipboard = 'unnamedplus'

-- ステータスラインを非表示
vim.opt.laststatus = 0

-- auto-session 推奨のセッション保存項目
vim.opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- PHP/tpl ファイルは nkf で文字コードを判定して開き直す
local encoding = require("config.encoding")
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = { "*.php", "*.tpl" },
  callback = function()
    local enc = encoding.detect(vim.fn.expand("%:p"))
    if enc and vim.bo.fileencoding ~= enc then
      vim.cmd("edit ++enc=" .. enc)
    end
  end,
})

-- ファイル保存時に自動コミット＆プッシュ
local auto_push_repos = {
  ["naoyafurudono/dotfiles"] = true,
}
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*",
  callback = function()
    local file_dir = vim.fn.expand("%:p:h")
    local remote_url = vim.fn.trim(vim.fn.system("cd " .. vim.fn.shellescape(file_dir) .. " && git remote get-url origin 2>/dev/null"))
    if vim.v.shell_error ~= 0 or remote_url == "" then
      return
    end
    -- git@github.com:owner/repo.git or https://github.com/owner/repo.git -> owner/repo
    local repo = remote_url:gsub("^git@[^:]+:", ""):gsub("^https?://[^/]+/", ""):gsub("%.git$", "")
    if auto_push_repos[repo] then
      vim.fn.jobstart(
        "cd " .. vim.fn.shellescape(file_dir) .. " && git add -A && git commit -m update && git push",
        { detach = true }
      )
    end
  end,
})
