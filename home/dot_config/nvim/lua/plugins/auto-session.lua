return {
  "rmagatti/auto-session",
  lazy = false,
  opts = {
    auto_save = true,
    auto_restore = true,
    auto_create = true,
    -- nvim をファイル引数付きで開いた場合でも保存・復元する
    args_allow_single_directory = true,
    args_allow_files_auto_save = true,
    suppressed_dirs = { "~/", "~/Downloads", "~/Desktop", "/" },
    session_lens = {
      load_on_setup = false,
    },
  },
}
