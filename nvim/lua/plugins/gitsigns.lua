return {
  "lewis6991/gitsigns.nvim",
  config = function()
    vim.api.nvim_set_hl(0, 'MyGitSignsAdd', { fg = '#50a14f' })
    vim.api.nvim_set_hl(0, 'MyGitSignsChange', { fg = '#c18401' })
    vim.api.nvim_set_hl(0, 'MyGitSignsDelete', { fg = '#e45649' })

    require('gitsigns').setup({
      signs = {
        add          = { text = '│', hl = 'MyGitSignsAdd' },
        change       = { text = '│', hl = 'MyGitSignsChange' },
        delete       = { text = '_', hl = 'MyGitSignsDelete' },
        topdelete    = { text = '‾', hl = 'MyGitSignsDelete' },
        changedelete = { text = '~', hl = 'MyGitSignsChange' },
      },
    })
  end,
}
