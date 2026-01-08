return {
  'kevinhwang91/nvim-bqf',
  ft = 'qf',
  config = function()
    require('bqf').setup({
      preview = {
        auto_preview = true,
        border = 'none',
        winblend = 0,
      },
    })
  end,
}
