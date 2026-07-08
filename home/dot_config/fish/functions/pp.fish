function pp -d 'fzfでファイルを選択してエディタで開く'
    set pathname (fzf --print0)
    or return 1
    set -l cmd $EDITOR $pathname
    builtin history merge
    builtin history append -- "$cmd"
    $cmd
end
