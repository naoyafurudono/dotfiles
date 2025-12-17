function spinner -d 'コマンドをスピナー付きで実行' -a message command
    set result_file (mktemp)
    fish -c "$command" > "$result_file" 2>/dev/null &
    set pid $last_pid

    set frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
    set i 1
    while kill -0 $pid 2>/dev/null
        printf "\r%s %s" $frames[$i] "$message"
        set i (math $i % 10 + 1)
        sleep 0.1
    end
    printf "\r\033[K"

    cat "$result_file"
    rm "$result_file"
end
