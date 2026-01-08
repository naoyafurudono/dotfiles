return {
  "neovim/nvim-lspconfig",
  config = function()
    vim.lsp.enable('gopls')

    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = {
        border = "rounded",
        source = true,
      },
    })
  end,
}
