function memo -d 'Create a new memo file with today date'
  set -l filename (date -I).md
  if [ ! -e "$filename" ]
    echo -e "---\ndate: $(date -I)\n---" > "$filename"
  end
  $EDITOR "$filename"
end
