function new_article --description "Create a new article template (daily or post)"
    set -l type "daily"
    set -l date (date +%Y-%m-%d)
    set -l datetime (date +%Y-%m-%dT%H:%M:%S%z)
    set -l title ""
    
    # Parse arguments
    if test (count $argv) -gt 0
        if test "$argv[1]" = "post"
            set type "post"
            if test (count $argv) -lt 2
                echo "Usage: new_article post <title>"
                return 1
            end
            set title (string join " " $argv[2..-1])
        else
            # Assume it's a date for daily
            set date $argv[1]
            set datetime (date -j -f "%Y-%m-%d" "$date" +%Y-%m-%dT%H:%M:%S%z 2>/dev/null)
            if test $status -ne 0
                echo "Error: Invalid date format. Use YYYY-MM-DD"
                echo "Usage: new_article [date] or new_article post <title>"
                return 1
            end
        end
    end
    
    # Generate template based on type
    if test "$type" = "daily"
        echo "---
title: \"$date\"
date: $datetime
author: \"Naoya Furudono\"
draft: false
tags:
    - daily
---

"
        echo "Daily template for $date generated"
    else
        set -l slug (echo $title | string lower | string replace -a " " "-" | string replace -a "[^a-z0-9-]" "")
        echo "---
title: \"$title\"
date: $datetime
draft: false
---

"
        echo "Post template '$slug.md' generated with title: $title"
    end
end