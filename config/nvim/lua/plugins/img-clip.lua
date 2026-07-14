return {
  "HakonHarnes/img-clip.nvim",
  ft = { "markdown" },
  opts = {
    default = {
      dir_path = ".",
      relative_to_current_file = true,
      prompt_for_file_name = true,
      file_name = "%Y%m%d-%H%M%S",
    },
  },
  keys = {
    {
      "<C-v>",
      function()
        -- Finder でコピーしたファイルのパスを取得（osascript直接呼び出し）
        local obj = vim.system(
          { "/usr/bin/osascript", "-e", "the clipboard as «class furl»" },
          { text = true }
        ):wait()
        if obj.code == 0 and obj.stdout and obj.stdout:match("^file ") then
          local hfs_path = obj.stdout:match("^file (.-)%s*$")
          if hfs_path then
            local obj2 = vim.system(
              { "/usr/bin/osascript", "-e", 'POSIX path of "' .. hfs_path .. '"' },
              { text = true }
            ):wait()
            local posix_path = vim.fn.trim(obj2.stdout or "")
            local ext = posix_path:match("%.(%w+)$")
            if ext and vim.tbl_contains({ "png", "jpg", "jpeg", "gif", "svg", "webp" }, ext:lower()) then
              local article_dir = vim.fn.expand("%:p:h")
              local filename = vim.fn.fnamemodify(posix_path, ":t")
              local dest = article_dir .. "/" .. filename
              local ok, err = vim.uv.fs_copyfile(posix_path, dest)
              if not ok then
                vim.notify("copy failed: " .. (err or "unknown"), vim.log.levels.ERROR)
                return
              end
              vim.api.nvim_put({ "![](" .. filename .. ")" }, "c", true, true)
              return
            end
          end
        end
        -- 画像ファイルでなければ img-clip.nvim でスクリーンショット貼り付け
        vim.cmd("PasteImage")
      end,
      mode = "i",
      desc = "Paste image from clipboard",
    },
  },
}
