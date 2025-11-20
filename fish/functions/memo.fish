function memo -d 'Create a new memo file with today date'
  if not set -q MEMO_DIR
    set -l memo_dir_candidates \
        "$HOME/src/git.pepabo.com/donokun/memo" \
        "$HOME/src/github.com/naoyafurudono/memo" \
        "$HOME/Desktop" \

    for dir in $memo_dir_candidates
      if test -d "$dir"
        set -gx MEMO_DIR "$dir"
        break
      end
    end
  end

  set -l filename $MEMO_DIR/(date -I).md
  if [ ! -e "$filename" ]
    # Find the latest memo file based on filename date (YYYY-MM-DD.md format)
    set -l latest_memo (ls $MEMO_DIR/*.md 2>/dev/null | grep -E '/[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort -r | head -1)
    echo "Latest memo: $latest_memo"

    if [ -n "$latest_memo" ]
      # Copy content from the latest memo
      cp "$latest_memo" "$filename"
      # Update the date in the frontmatter
      sed -i '' "s/^date: .*/date: $(date -I)/" "$filename"
    else
      # Create new memo with frontmatter if no existing memo found
      echo -e "---\ndate: $(date -I)\n---" > "$filename"
    end
  end
  $IDE "$filename"
end
