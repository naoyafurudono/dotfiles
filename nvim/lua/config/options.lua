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

-- クリップボードと同期
vim.opt.clipboard = 'unnamedplus'

-- ステータスラインを非表示
vim.opt.laststatus = 0

-- colorme 配下のPHPファイルはeuc-jpで開く（mail/は除外）
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*/colorme/*.php",
  callback = function()
    local filepath = vim.fn.expand("%:p")
    if filepath:match("/mail/") then
      return
    end
    if vim.bo.fileencoding ~= "euc-jp" then
      vim.cmd("edit ++enc=euc-jp")
    end
  end,
})

-- ファイル保存時に自動コミット＆プッシュ
local auto_push_repos = {
  ["donokun/memo"] = true,
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
