return {
  "ruifm/gitlinker.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require('gitlinker').setup({
      mappings = "<D-S-l>",
      callbacks = {
        ["git.pepabo.com"] = require('gitlinker.hosts').get_github_type_url,
      },
    })
  end,
}
