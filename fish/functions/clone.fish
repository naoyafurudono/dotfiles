function clone
  gh repo list | fzf | awk '{print $1}' | xargs gh repo clone
end
