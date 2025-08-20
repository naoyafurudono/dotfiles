function i --description "Create a new article template (daily or post)"
    set -l type "daily"
    set -l date (date +%Y-%m-%d)
    set -l datetime (date +%Y-%m-%dT%H:%M:%S%z)
    set -l title ""
    set -l template_dir (dirname (status -f))/../sample
    
    # Parse arguments
    if test (count $argv) -gt 0
        if test "$argv[1]" = "post"
            set type "post"
            if test (count $argv) -lt 2
                echo "Usage: i post <title>"
                return 1
            end
            set title (string join " " $argv[2..-1])
        else
            # Assume it's a date for daily
            set date $argv[1]
            set datetime (date -j -f "%Y-%m-%d" "$date" +%Y-%m-%dT%H:%M:%S%z 2>/dev/null)
            if test $status -ne 0
                echo "Error: Invalid date format. Use YYYY-MM-DD"
                echo "Usage: i [date] or i post <title>"
                return 1
            end
        end
    end
    
    # Generate template based on type
    if test "$type" = "daily"
        # Read the daily template
        if test -f "$template_dir/daily.md"
            set -l template (cat "$template_dir/daily.md")
            # Replace placeholders
            set template (string replace -a "{{ .Name | title }}" "$date" -- $template)
            set template (string replace -a "{{ .Date }}" "$datetime" -- $template)
            echo $template
        else
            # Fallback to default if template not found
            echo "---
title: \"$date\"
date: $datetime
author: \"Naoya Furudono\"
draft: true
tags:
    - daily
---

"
        end
        echo "Daily template for $date generated"
    else
        # Read the default template for posts
        if test -f "$template_dir/default.md"
            set -l template (cat "$template_dir/default.md")
            # Replace placeholders
            set template (string replace -a "TODO" "$title" -- $template)
            set template (string replace -a "{{ .Date }}" "$datetime" -- $template)
            echo $template
        else
            # Fallback to default if template not found
            echo "---
title: \"$title\"
date: $datetime
author: \"Naoya Furudono\"
draft: true
---

"
        end
        set -l slug (echo $title | string lower | string replace -a " " "-" | string replace -a "[^a-z0-9-]" "")
        echo "Post template '$slug.md' generated with title: $title"
    end
end