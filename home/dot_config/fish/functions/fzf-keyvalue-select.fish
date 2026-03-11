# ヘルプメッセージ
function print_help
    echo "Usage: $argv[0] <yaml_file>"
    echo
    echo "This script allows you to select a key from a YAML file using fzf, and outputs the corresponding value."
    echo
    echo "Options:"
    echo "  -h    Show this help message and exit"
    echo
    echo "Sample YAML format:"
    echo "  key1: value1"
    echo "  key2: value2"
    echo "  key3: value3"
end

function fzf-keyvalue-select
    # -hオプションのチェック
    if test "$argv[1]" = "-h"
        print_help
        return
    end
    
    # 引数チェック
    if test -z "$argv[1]"
        echo "Error: No YAML file specified." >&2
        print_help
        return 1
    end
    
    # 引数からYAMLファイルのパスを取得
    set YAML_FILE "$argv[1]"
    
    # YAMLファイルの存在チェック
    if test ! -f "$YAML_FILE"
        echo "Error: File '$YAML_FILE' not found." >&2
        return 1
    end
    
    # キーをfzfで選択
    set selected_key (yq e 'keys | .[]' "$YAML_FILE" | fzf)
    
    # キーが選択されていない場合
    if test -z "$selected_key"
        echo "No key selected." >&2
        return 1
    end
    
    # 選択されたキーに対応する値を取得
    set selected_value (yq e ".$selected_key" "$YAML_FILE")
    
    # 値を標準出力に表示
    echo "$selected_value"
    return 0
end