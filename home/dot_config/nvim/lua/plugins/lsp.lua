return {
  "neovim/nvim-lspconfig",
  config = function()
    vim.lsp.enable('gopls')
    vim.lsp.enable('intelephense')
    vim.lsp.enable('lua_ls')

    -- LSP keymaps (LspAttach時に設定)
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('UserLspConfig', {}),
      callback = function(ev)
        local opts = function(desc)
          return { buffer = ev.buf, desc = desc }
        end

        -- 定義・宣言・参照
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts('定義へジャンプ'))
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts('宣言へジャンプ'))
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts('参照一覧'))
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts('実装へジャンプ'))
        vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts('型定義へジャンプ'))
        vim.keymap.set('n', 'gh', vim.lsp.buf.hover, opts('ホバードキュメント'))
        vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, opts('シグネチャヘルプ'))

        -- リファクタリング
        vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, opts('リネーム'))
        vim.keymap.set('n', '<D-r>', vim.lsp.buf.rename, opts('リネーム'))
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts('コードアクション'))

        -- フォーマット
        vim.keymap.set('n', '<leader>f', function()
          vim.lsp.buf.format({ async = true })
        end, opts('フォーマット'))
      end,
    })

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
