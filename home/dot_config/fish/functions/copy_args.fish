function copy_args -d '引数をクリップボードにコピーする'
    echo -n $argv | pbcopy
end
