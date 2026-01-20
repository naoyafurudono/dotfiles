return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  opts = {
    formatters_by_ft = {
      markdown = { "dprint" },
    },
    formatters = {
      dprint = {
        args = { "fmt", "--config", vim.fn.expand("~/.config/dprint/config.json"), "--stdin", "$FILENAME" },
      },
    },
    format_on_save = {
      timeout_ms = 500,
    },
  },
}
