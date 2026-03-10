function ppp -d 'fzfでcwd配下の全ファイルを選択してエディタで開く（gitignore無視）'
    set pathname (fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --no-ignore | fzf --print0)
    and $IDE $pathname
end
