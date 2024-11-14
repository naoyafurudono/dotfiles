function notion
    set url (fzf-keyvalue-select ~/.local/fish/notion.yaml)
    and open $url
end
