function fish_prompt
    set -l last_status $status

    set -l normal (set_color normal)
    set -l usercolor (set_color $fish_color_user)
    set -l cwd_color (set_color $fish_color_cwd)

    set -l delim "🐧"
    # If we don't have unicode use a simpler delimiter
    # string match -qi "*.utf-8" -- $LANG $LC_CTYPE $LC_ALL; or set delim ">"

    # fish_is_root_user; and set delim "#"
    test (id -u) = 0; and set delim "#"

    # Prompt status only if it's not 0
    set -l prompt_status
    test $last_status -ne 0; and set prompt_status (set_color $fish_color_error)"[$last_status]$normal"

    # Make SSH sessions visually distinct from local sessions.
    set -l is_remote 0
    if set -q SSH_TTY
        or set -q SSH_CONNECTION
        or set -q SSH_CLIENT
        set is_remote 1
        set cwd_color (set_color brcyan)
        set delim (set_color --bold brmagenta)"◆"$normal
    end

    # Only show host if in SSH or container.
    # Store this in a global variable because it's slow and unchanging
    if not set -q prompt_host
        set -g prompt_host ""
        set -l host (hostname)
        if test $is_remote -eq 1
            set -l remote_color (set_color --bold brmagenta)
            set prompt_host $remote_color$USER"@"$host$normal":"
        else if command -sq systemd-detect-virt
            and systemd-detect-virt -q
            set prompt_host $usercolor$USER$normal@(set_color $fish_color_host)$host$normal":"
        end
    end

    set -l pwd (pwd)
    echo -e -n -s $prompt_host $cwd_color $pwd $normal $prompt_status '\n' "$delim "
end
