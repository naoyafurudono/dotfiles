return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  event = "VeryLazy",
  keys = {
    { "<Esc>[1;5I", "<cmd>BufferLineCycleNext<cr>", mode = { "n", "i", "v" }, desc = "Next buffer" },
    { "<Esc>[1;6I", "<cmd>BufferLineCyclePrev<cr>", mode = { "n", "i", "v" }, desc = "Prev buffer" },
    { "<C-Tab>", "<cmd>BufferLineCycleNext<cr>", mode = { "n", "i", "v" }, desc = "Next buffer" },
    { "<C-S-Tab>", "<cmd>BufferLineCyclePrev<cr>", mode = { "n", "i", "v" }, desc = "Prev buffer" },
    { "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick buffer" },
    { "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete buffer" },
    { "<M-w>", "<cmd>bdelete<cr>", mode = { "n", "i", "v" }, desc = "Close buffer (Cmd+W)" },
  },
  opts = {
    options = {
      mode = "buffers",
      diagnostics = "nvim_lsp",
      show_buffer_close_icons = true,
      show_close_icon = false,
    },
  },
}
