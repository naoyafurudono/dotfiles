function nv
    set pathname (fzf --print0)
    and nvim $pathname
end
