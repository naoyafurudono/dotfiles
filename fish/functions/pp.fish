function pp -d 'fzfでファイルを選択してエディタで開く'
    set pathname (fzf --print0)
    and $IDE $pathname
end
