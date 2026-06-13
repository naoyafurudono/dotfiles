return {
  "okm321/mo.nvim",
  ft = { "markdown" },
  -- 外部依存: mo (k1LoW/mo) >= 1.3.0 を PATH に置くこと
  -- `brew install k1LoW/tap/mo` でインストール済み (go install は埋め込み dist が無く失敗する)
  -- :MoPick の複数選択は telescope.nvim を利用
  dependencies = { "nvim-telescope/telescope.nvim" },
  opts = {
    port = 6275,
    no_open = false,
    auto_add = false,
    target = nil,
  },
  keys = {
    { "<leader>mo", "<cmd>MoAdd<cr>", desc = "mo: Add current file" },
    { "<leader>mp", "<cmd>MoPick<cr>", desc = "mo: Pick files" },
    { "<leader>ms", "<cmd>MoStatus<cr>", desc = "mo: Status" },
  },
}
