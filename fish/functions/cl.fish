function cl
    set pathname (fzf --print0)
    set newname $argv[1]
    and easy-cp $pathname $newname
end
