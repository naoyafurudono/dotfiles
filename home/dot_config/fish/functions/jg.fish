function jg -d 'ghqで管理するリポジトリをfzfで選択してcdする'
    set root (ghq root)
    set selected (ghq list | fzf)

    if test -n "$selected"
        cd "$root/$selected"
    end
end
