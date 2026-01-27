return {
  "lewis6991/gitsigns.nvim",
  config = function()
    vim.api.nvim_set_hl(0, 'GitSignsAdd', { fg = '#50a14f' })
    vim.api.nvim_set_hl(0, 'GitSignsChange', { fg = '#c18401' })
    vim.api.nvim_set_hl(0, 'GitSignsDelete', { fg = '#e45649' })
    vim.api.nvim_set_hl(0, 'GitSignsTopdelete', { link = 'GitSignsDelete' })
    vim.api.nvim_set_hl(0, 'GitSignsChangedelete', { link = 'GitSignsChange' })

    require('gitsigns').setup({
      signs = {
        add          = { text = '│' },
        change       = { text = '│' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
      },
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 300,
        virt_text_pos = 'eol',
      },
    })
  end,
}
