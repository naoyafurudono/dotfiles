function cl -d 'fzfで選択したファイルと同じディレクトリ階層に第一引数で指定した名前のファイルを作成してコピーする'
    set pathname (fzf --print0)
    and set newname $argv[1]
    and easy-cp $pathname $newname
end
