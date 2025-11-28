function killport --description '指定したポートを使用しているプロセスをkillする'
    # 引数がない場合はヘルプを表示
    if test (count $argv) -eq 0
        echo "使用法: killport <port1> [port2] ..."
        return 1
    end

    # 引数(ポートリスト)をカンマ区切り文字列に結合 (例: 3000 8080 -> 3000,8080)
    set ports (string join ',' $argv)

    # 指定ポートのPIDを取得
    # 2> /dev/null は、見つからなかった場合のlsofのエラーメッセージを隠すため
    set pids (lsof -ti :$ports 2> /dev/null)

    # PIDが見つかった場合のみ実行
    if test -n "$pids"
        echo "ポート $argv を使用しているプロセス (PID: $pids) を終了します..."
        # Fishはリスト変数を自動展開して引数に渡してくれるため、xargsは不要
        kill -9 $pids
    else
        echo "指定されたポート ($argv) を使用しているプロセスは見つかりませんでした。"
    end
end
