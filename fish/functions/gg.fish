function gg
    set repo (ghq list | fzf --preview "bat --color=always --style=header,grid --line-range :80 $(ghq root)/{}/README.*")
    and cd "$(ghq root)/$repo"
end
