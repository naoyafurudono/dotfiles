function conf  --description '設定ファイルをこの関数にハードコードした覧からfzfで選択してnvimで開き、編集が完了したらリモートに同期する'
    # パスはfishの組み込みによって解釈される
    # 相対パスに解釈される場合はXDG_CONFIG_HOMEを常に基点として扱う
    set -l configs \
        'fish/config.fish' \
        'fish/functions/conf.fish' \
        '~/.local/fish/init.fish.secret' \
        'ghostty/config' \
        'git/config' \
        'git/hooks/whitelist.txt' \
        'nvim/init.lua'

    # 名前一覧をfzfで表示
    set -l selected_path (
        printf '%s\n' $configs | fzf
    )

    test -n "$selected_path"; or return

    # パス展開（~など対応）
    # https://fishshell.com/docs/current/cmds/path.html#normalize-subcommand
    set selected_path (path normalize "$selected_path")

    # 絶対パスでないならXDG_CONFIG_HOMEを前置
    if not string match -q --regex '^/' $selected_path
        set selected_path "$XDG_CONFIG_HOME/$selected_path"
    end

    # ファイルの存在確認をしてエディターを起動
    if test -f "$selected_path"
        nvim "$selected_path" && sconf
    else
        echo "config file not found: $selected_path" >&2
        return 1
    end
end

