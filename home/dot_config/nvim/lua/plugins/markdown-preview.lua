-- markdown-preview.nvim: mermaid / PlantUML 等をネイティブにレンダリングできる Markdown プレビュー。
-- peek.nvim は markdown-it ベースで mermaid 非対応だったため差し替えた (2026-06-02)。
return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = function()
    vim.fn["mkdp#util#install"]()
  end,
  init = function()
    -- ブラウザで開く (peek の app="browser" 相当)
    vim.g.mkdp_auto_close = 1
    vim.g.mkdp_theme = "light"
    -- mermaid はデフォルトで有効。念のため明示
    vim.g.mkdp_preview_options = {
      mermaid = {},
    }
  end,
  keys = {
    -- Ghostty 側で Cmd+P を text:\x1bp にバインドしているので nvim には <M-p> として届く
    -- (kitty keyboard protocol の <D-p> は tmux が super 修飾を扱えず断念。2026-04-23)
    {
      "<M-p>",
      "<cmd>MarkdownPreviewToggle<cr>",
      ft = "markdown",
      desc = "Markdown Preview (mermaid 対応)",
    },
  },
}
