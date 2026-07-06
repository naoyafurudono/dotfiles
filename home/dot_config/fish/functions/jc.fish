function jc -d 'colormeリポジトリをfzfで選択してcdする'
    set root $COLORME_REPO_ROOT
    set selected (ghq list | fzf)

    if test -n "$selected"
        cd "$root/$selected"
    end
end
