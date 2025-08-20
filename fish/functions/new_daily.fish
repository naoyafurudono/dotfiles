function new_daily --description "Create a new daily note template"
    set -l date (date +%Y-%m-%d)
    set -l datetime (date +%Y-%m-%dT%H:%M:%S%z)
    
    if test (count $argv) -gt 0
        set date $argv[1]
        set datetime (date -j -f "%Y-%m-%d" "$date" +%Y-%m-%dT%H:%M:%S%z 2>/dev/null)
        if test $status -ne 0
            echo "Error: Invalid date format. Use YYYY-MM-DD"
            return 1
        end
    end
    
    set -l filename "$date.md"
    
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
end