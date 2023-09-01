function fish_prompt
    set -l last_status $status

    set -l normal (set_color normal)
    set -l usercolor (set_color $fish_color_user)

    set -l delim "🐧"
    # If we don't have unicode use a simpler delimiter
    # string match -qi "*.utf-8" -- $LANG $LC_CTYPE $LC_ALL; or set delim ">"

    # fish_is_root_user; and set delim "#"
    test (id -u) = 0; and set delim "#"

    set -l cwd (set_color $fish_color_cwd)

    # Prompt status only if it's not 0
    set -l prompt_status
    test $last_status -ne 0; and set prompt_status (set_color $fish_color_error)"[$last_status]$normal"

    # Only show host if in SSH or container
    # Store this in a global variable because it's slow and unchanging
    if not set -q prompt_host
        set -g prompt_host ""
        if set -q SSH_TTY
            or begin
                command -sq systemd-detect-virt
                and systemd-detect-virt -q
            end
            set -l host (hostname)
            set prompt_host $usercolor$USER$normal@(set_color $fish_color_host)$host$normal":"
        end
    end

    set -l pwd (pwd)

    set kube_prompt ""
    if type -q __kube_prompt >/dev/null
        set kube_prompt (__kube_prompt)
    end
    echo -e -n -s $prompt_host $cwd $pwd $normal $prompt_status $kube_prompt '\n' "$delim "
end
