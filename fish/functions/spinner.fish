function spinner -d 'コマンドをスピナー付きで実行' -a message command
    set result_file (mktemp)
    fish -c "$command" > "$result_file" 2>/dev/null &
    set pid $last_pid

    set frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
    set colors 8b4513 a0522d c48b5e a0522d
    set i 1
    set wave 0
    set msg_chars (string split '' "$message")
    set msg_len (count $msg_chars)
    while kill -0 $pid 2>/dev/null
        set output ""
        for j in (seq 1 $msg_len)
            set c (math "($wave - $j) % 4 + 1")
            test $c -le 0; and set c (math "$c + 4")
            set output "$output"(set_color $colors[$c])"$msg_chars[$j]"
        end
        printf "\r%s %s%s" (set_color 8b4513)$frames[$i] "$output" (set_color normal) >&2
        set i (math $i % 10 + 1)
        if test (math "$wave % 2") -eq 0
            set wave (math "$wave + 1")
        end
        set wave (math "$wave + 1")
        sleep 0.1
    end
    printf "\r\033[K" >&2

    cat "$result_file"
    rm "$result_file"
end
