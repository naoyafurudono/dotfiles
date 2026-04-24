function po -d 'fzfでファイルまたはディレクトリを選択してopenで開く'
    set pathname (fzf --print0 --walker=file,dir,follow,hidden --walker-skip=.git)
    or return 1
    set -l cmd open $pathname
    builtin history merge
    builtin history append -- "$cmd"
    $cmd
end
