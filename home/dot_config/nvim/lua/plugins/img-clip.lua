return {
  "HakonHarnes/img-clip.nvim",
  ft = { "markdown" },
  opts = {
    default = {
      dir_path = ".",
      relative_to_current_file = true,
      prompt_for_file_name = true,
      file_name = "%Y%m%d-%H%M%S",
    },
  },
  keys = {
    { "<C-v>", "<cmd>PasteImage<cr>", mode = "i", desc = "Paste image from clipboard" },
  },
}
