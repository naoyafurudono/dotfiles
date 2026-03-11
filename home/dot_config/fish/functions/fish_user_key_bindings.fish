function fish_user_key_bindings
  fzf_key_bindings
  # fzf_key_bindingsの設定を上書きする
  bind -e \cr
  bind -M insert \cr fzf-sync-select-history
end

function fzf-sync-select-history
    history merge
    fzf-history-widget
end

