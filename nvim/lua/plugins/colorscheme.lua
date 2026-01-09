return {
  "navarasu/onedark.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require('onedark').setup({
      style = 'light',
      highlights = {
        GitSignsAdd = { fg = '#50a14f' },
        GitSignsChange = { fg = '#c18401' },
        GitSignsDelete = { fg = '#e45649' },
      },
    })
    require('onedark').load()
  end,
}
