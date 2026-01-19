function memo -d 'Create a new memo file (weekly by default, daily if MEMO_DAILY=1)'
  if not set -q MEMO_DIR
    set -l memo_dir_candidates \
        "$HOME/src/git.pepabo.com/donokun/memo" \
        "$HOME/src/github.com/naoyafurudono/memo" \
        "$HOME/Desktop"

    for dir in $memo_dir_candidates
      if test -d "$dir"
        set -gx MEMO_DIR "$dir"
        break
      end
    end
  end

  if set -q MEMO_DAILY; and test "$MEMO_DAILY" = "1"
    # Daily mode (legacy behavior)
    set -l filename $MEMO_DIR/(date -I).md
    if [ ! -e "$filename" ]
      set -l latest_memo (ls $MEMO_DIR/*.md 2>/dev/null | grep -E '/[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort -r | head -1)
      echo "Latest memo: $latest_memo"

      if [ -n "$latest_memo" ]
        cp "$latest_memo" "$filename"
        sed -i '' "s/^date: .*/date: $(date -I)/" "$filename"
      else
        echo -e "---\ndate: $(date -I)\n---" > "$filename"
      end
    end
    $IDE "$filename"
  else
    # Weekly mode (default)
    set -l week_number (date +%G-W%V)
    set -l week_start (date -v-mon -v0H -v0M -v0S +%Y-%m-%d)
    set -l filename $MEMO_DIR/$week_number.md

    if [ ! -e "$filename" ]
      set -l latest_memo (ls $MEMO_DIR/*.md 2>/dev/null | grep -E '/[0-9]{4}-W[0-9]{2}\.md$' | sort -r | head -1)
      echo "Latest memo: $latest_memo"

      if [ -n "$latest_memo" ]
        cp "$latest_memo" "$filename"
        sed -i '' "s/^date: .*/date: $week_start/" "$filename"
        sed -i '' "s/^week: .*/week: $week_number/" "$filename"
      else
        echo -e "---\ndate: $week_start\nweek: $week_number\n---" > "$filename"
      end
    end
    $IDE "$filename"
  end
end
