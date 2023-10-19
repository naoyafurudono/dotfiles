function pp
    set pathname (find . -type f | fzf --print0)
    and code $pathname
end
