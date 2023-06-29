function memo
  set -l filename (date -I).md
  if [ ! -e "$filename" ]
    echo -e "---\ndate: $(date -I)\n---" > "$filename"
  end
  nvim "$filename"
end

