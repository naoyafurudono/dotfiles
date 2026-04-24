return {
  "toppair/peek.nvim",
  event = { "VeryLazy" },
  build = "deno task --quiet build:fast",
  config = function()
    require("peek").setup({
      auto_load = true,
      close_on_bdelete = true,
      syntax = true,
      theme = "light",
      update_on_change = true,
      app = "browser", -- 'webview', 'browser', or command like 'firefox'
      filetype = { "markdown" },
      throttle_at = 200000,
      throttle_time = "auto",
    })
    vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
    vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
  end,
  keys = {
    -- Ghostty 側で Cmd+P を text:\x1bp にバインドしているので nvim には <M-p> として届く
    -- (kitty keyboard protocol の <D-p> は tmux が super 修飾を扱えず断念。2026-04-23)
    {
      "<M-p>",
      function()
        local peek = require("peek")
        if peek.is_open() then
          peek.close()
        else
          peek.open()
        end
      end,
      desc = "Peek (Markdown Preview)",
    },
  },
}
