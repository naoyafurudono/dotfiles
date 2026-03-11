function rpl --description "ファイル内の文字列を再帰的に置換する"
  # 引数の数をチェックします
  if test (count $argv) -ne 2
    echo "Arity mismatch. want: 2, actual: (count $argv)" >&2
    return 1
  end

  # ripgrep (rg) で検索パターンを含むファイルをリストアップし、
  # xargs を経由して sed で文字列を置換します
  rg -l -- "$argv[1]" | xargs sed -i -E "s/$argv[1]/$argv[2]/g"
end
