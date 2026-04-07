function cppath -d 'ファイルの絶対パスをクリップボードにコピーする'
    realpath $argv[1] | tr -d '\n' | pbcopy
    echo (pbpaste)
end
