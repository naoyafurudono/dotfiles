function conf  --description 'この関数にハードコードした設定ファイルをfzfで一覧してEDITORで開く'
    set -q EDITOR; or set EDITOR vim

    # 設定ファイルを「名前:パス」で一元定義
    # パスはfishの組み込みによって解釈される
    # 相対パスに解釈される場合はXDG_CONFIG_HOMEを常に基点として扱う
    set -l configs \
        'fish:fish/config.fish' \
        'fish-func-conf:fish/functions/conf.fish' \
        'fish-local:~/.local/fish/init.fish.secret' \
        'ghostty:ghostty/config' \
        'git:git/config' \
        'nvim:nvim/init.lua'

    # 名前一覧をfzfで表示
    set -l selected_name (
        printf '%s\n' $configs | string replace -r ':.*' '' | fzf --prompt="Edit config> "
    )

    test -n "$selected_name"; or return

    # 名前からパス取得
    set -l selected_path (
        printf '%s\n' $configs | string match "$selected_name:*" | string replace -r '^[^:]+:' ''
    )

    # パス展開（~など対応）
    # https://fishshell.com/docs/current/cmds/path.html#normalize-subcommand
    set selected_path (path normalize "$selected_path")

    echo "selected: $selected_path"

    # 絶対パスでないならXDG_CONFIG_HOMEを前置
    if not string match -q --regex '^/' $selected_path
        set selected_path "$XDG_CONFIG_HOME/$selected_path"
    end

    # ファイルの存在確認をしてエディターを起動
    if test -f "$selected_path"
        $EDITOR "$selected_path"
    else
        echo "Config file not found: $selected_path"
        return 1
    end
end