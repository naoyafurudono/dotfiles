function cs
    # 引数（ブランチ名のプレフィックス）を取得
    set branch_prefix $argv[1]

    # 現在時刻をJSTで指定されたフォーマットで取得
    set current_time_jst (env TZ=Asia/Tokyo date +%Y-%m-%d_%H%M%S)

    # 新しいブランチ名を生成
    set new_branch_name "$branch_prefix-$current_time_jst"

    # git switch -c コマンドを実行
    git switch -c $new_branch_name
end

