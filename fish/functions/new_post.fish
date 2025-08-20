function new_post --description "Create a new post template"
    if test (count $argv) -eq 0
        echo "Usage: new_post <title>"
        return 1
    end
    
    set -l title (string join " " $argv)
    set -l slug (echo $title | string lower | string replace -a " " "-" | string replace -a "[^a-z0-9-]" "")
    set -l datetime (date +%Y-%m-%dT%H:%M:%S%z)
    
    set -l filename "$slug.md"
    
    echo "---
title: \"$title\"
date: $datetime
draft: false
---

"
    
    echo "Post template '$filename' generated with title: $title"
end