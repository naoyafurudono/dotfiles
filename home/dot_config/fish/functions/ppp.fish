function ppp -d 'fzfでcwd配下の全ファイルを選択してエディタで開く（gitignore無視）'
    set pathname (fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --no-ignore | fzf --print0)
    or return 1
    set -l cmd $IDE $pathname
    builtin history merge
    builtin history append -- "$cmd"
    $cmd
end
