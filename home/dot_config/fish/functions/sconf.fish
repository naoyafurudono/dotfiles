function sconf --description "Re-add selected targets to the chezmoi source"
    if test (count $argv) -eq 0
        echo "usage: sconf <target> [...]" >&2
        return 2
    end

    for target in $argv
        chezmoi re-add "$target"; or return
    end

    chezmoi diff
end
