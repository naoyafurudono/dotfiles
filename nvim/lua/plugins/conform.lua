return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  opts = {
    formatters_by_ft = {
      markdown = { "dprint" },
    },
    format_on_save = {
      timeout_ms = 500,
    },
  },
}
