# ---- environment ----

set -gx XDG_CONFIG_PATH $HOME/.config
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local
set -gx VOLTA_HOME $HOME/.volta
set -gx GHE_USER donokun
set -gx GOBIN $HOME/go/bin

set -gx PATH \
    $HOME/.krew/bin \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $GOBIN \
    $PATH

if test (uname -s) = Darwin
    for prefix in /opt/homebrew /usr/local
        if test -d $prefix/bin
            fish_add_path $prefix/bin
        end
    end

    if test -d /opt/homebrew/opt/mysql-client@8.0/bin
        fish_add_path /opt/homebrew/opt/mysql-client@8.0/bin
    end

    # The next line updates PATH for the Google Cloud SDK.
    for sdk_path in $HOME/google-cloud-sdk/path.fish.inc $HOME/.local/google-cloud-sdk/path.fish.inc
        if test -f $sdk_path
            source $sdk_path
            break
        end
    end
else
    for sdk_path in $HOME/google-cloud-sdk/path.fish.inc $HOME/.local/google-cloud-sdk/path.fish.inc $HOME/dev/google-cloud-sdk/path.fish.inc
        if test -f $sdk_path
            source $sdk_path
            break
        end
    end
end

# --- interactive ---

if status --is-interactive
    set -gx fish_user_abbreviations

    if test "$TERM_PROGRAM" = zed
        set -gx EDITOR zed
        abbr --add v nvim
        abbr --add m zed
    else
        set -gx EDITOR nvim
        abbr --add v nvim
        abbr --add mm 'zed .'
        abbr --add m "cd $MEMO_DIR && claude"
    end
    abbr --add mm "cd $MEMO_DIR"
    abbr --add n "$EDITOR ."

    abbr --add - 'cd -'
    abbr --add .. 'cd ../'
    abbr --add ... 'cd ../../'
    abbr --add .... 'cd ../../../'
    abbr --add ..... 'cd ../../../../'
    abbr --add di 'diary --dir'
    abbr --add h hustle
    abbr --add k kubectl
    abbr --add ka 'kubectl get (kubectl api-resources --namespaced=true --verbs=list -o name | tr "\n" "," | sed -e "s/,\$//")'
    abbr --add kp killport
    abbr --add l eza
    abbr --add pk 'tmux kill-pane -t'
    abbr --add rg 'rg --no-heading --smart-case'
    abbr --add t 'tree --gitignore'
    abbr --add tar 'tar -xvf'

    abbr --add a 'git add'
    abbr --add c 'git commit -m'
    abbr --add d 'git diff'
    abbr --add s 'git status'
    abbr --add gu 'git add -A && git commit -m update && git push' # 必要悪 :(
    abbr --add p 'git pull'

    abbr --add eip 'curl https://checkip.amazonaws.com'


    set -gx LS_COLORS 1 # for fd

    set -gx _ZO_DATA_DIR $XDG_DATA_HOME/zoxide
    if command -q zoxide
        zoxide init fish --cmd j | source
    end
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'

    set -gx fish_tmux_config $HOME/.config/tmux/tmux.conf

    switch (uname -s)
        case Darwin
            abbr --add less bat
            if command -q direnv
                direnv hook fish | source
            end
        case Linux
            switch (uname --all)
            case '*raspi*'
              abbr --add less bat
            case '*WSL*'
              abbr --add less batcat
              abbr --add open 'powershell.exe /c start'
            case '*'
              abbr --add less batcat
            end
            abbr --add xremap xremap $XDG_CONFIG_HOME/xremap/xremap.conf --device \'Topre REALFORCE 87 US\'
        case '*'
            echo "unknown uname"
            exit 1
    end

    fish_vi_key_bindings

    # Do after `fish_vi_key_bindings`, which overwrites follows
    set -gx fish_cursor_default block
    set -gx fish_cursor_insert line
    set -gx fish_cursor_replace_one underscore
    set -gx fish_cursor_visual block

    # no greeting
    set -gx fish_greeting
end

# ---- load ----

if test -f ~/.local/fish/config.fish
    source ~/.local/fish/config.fish
end
