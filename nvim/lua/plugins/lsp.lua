return {
  "neovim/nvim-lspconfig",
  config = function()
    vim.lsp.enable('gopls')
    vim.lsp.enable('intelephense')
    vim.lsp.enable('lua_ls')

    -- Format on save
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = { "*.go", "*.php", "*.lua" },
      callback = function()
        vim.lsp.buf.format({ async = false })
      end,
    })

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
