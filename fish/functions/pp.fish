function pp
    set pathname (fzf --print0)
    and $EDITOR $pathname
end
