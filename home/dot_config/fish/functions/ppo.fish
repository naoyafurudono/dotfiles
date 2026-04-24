function ppo -d 'fzfでcwd配下の全ファイル・ディレクトリを選択してopenで開く（gitignore無視）'
    set pathname (fd --type f --type d --strip-cwd-prefix --hidden --follow --exclude .git --no-ignore | fzf --print0)
    or return 1
    set -l cmd open $pathname
    builtin history merge
    builtin history append -- "$cmd"
    $cmd
end
