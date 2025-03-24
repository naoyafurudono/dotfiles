function kk
    set pathname (find . -name "*"  -type d | fzf --print0)
    and cd $pathname
end
