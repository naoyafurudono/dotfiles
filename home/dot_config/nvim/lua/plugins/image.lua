return {
  "3rd/image.nvim",
  enabled = false,
  ft = { "markdown" },
  opts = {
    backend = "kitty",
    processor = "magick_cli",
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        only_render_image_at_cursor = true,
        resolve_image_path = function(document_path, image_path, fallback)
          -- 相対パスを記事ディレクトリからの絶対パスに解決
          return fallback(document_path, image_path)
        end,
      },
    },
    max_width = 40,
    max_height = 15,
    max_height_window_percentage = 20,
    editor_only_render_when_focused = true,
    window_overlap_clear_enabled = true,
  },
}
