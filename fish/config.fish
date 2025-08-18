# ---- environment ----

set -gx XDG_CONFIG_PATH $HOME/.config
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local
set -gx VOLTA_HOME $HOME/.volta
set -gx GHE_USER donokun
set -gx GOBIN $HOME/go/bin

set -gx PATH \
    /opt/homebrew/opt/ruby/bin \
    /opt/homebrew/lib/ruby/gems/3.4.0/bin \
    $HOME/.krew/bin \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $GOBIN \
    $PATH


if test (uname -s) = Darwin
    set -gx PATH $PATH \
        /opt/homebrew/bin \
        /opt/homebrew/opt/mysql-client@8.0/bin
    # The next line updates PATH for the Google Cloud SDK.
    if [ -f '/Users/naoya-furudono/google-cloud-sdk/path.fish.inc' ]
        source '/Users/naoya-furudono/google-cloud-sdk/path.fish.inc'
    end
    if [ -f '/Users/furudono/.local/google-cloud-sdk/path.fish.inc' ];
      source '/Users/furudono/.local/google-cloud-sdk/path.fish.inc'
    end
else
    if [ -f '/home/furudono/dev/google-cloud-sdk/path.fish.inc' ]
        source '/home/furudono/dev/google-cloud-sdk/path.fish.inc'
    end
end

# --- interactive ---

if status --is-interactive
    # Zellij auto-launch
    if not set -q ZELLIJ
        and command -v zellij >/dev/null
        exec zellij
    end

    # 遅め。耐えられなくなったらキャッシュしよう
    gh completion -s fish > ~/.config/fish/completions/gh.fish
    set -gx fish_user_abbreviations

    set -gx EDITOR nvim
    set -gx IDE zed

    abbr --add v nvim
    abbr --add m $IDE
    abbr --add n "$IDE ."
    abbr --add mod-cursor 'abbr --add m cursor; abbr --add n "cursor ."; set -x IDE cursor; set -x EDITOR cursor'
    abbr --add mod-zed 'abbr --add m zed; abbr --add n "zed ."; set -x IDE zed; set -x EDITOR zed'

    abbr --add rg 'rg --no-heading --smart-case'
    abbr --add l eza
    abbr --add k kubectl
    abbr --add ka 'kubectl get (kubectl api-resources --namespaced=true --verbs=list -o name | tr "\n" "," | sed -e "s/,\$//")'

    abbr --add a 'git add'
    abbr --add c 'git c'
    abbr --add d 'git diff'
    abbr --add s 'git status'
    abbr --add w 'git worktree add worktree/'
    abbr --add gu 'git add -A && git commit -m update && git push && git diff HEAD^' # 必要悪 :(
    abbr --add p 'git pull'

    abbr --add eip 'curl http://checkip.amazonaws.com'


    set -gx LS_COLORS 1 # for fd

    set -gx _ZO_DATA_DIR $XDG_DATA_HOME/zoxide
    zoxide init fish --cmd j | source
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'

    set -gx fish_tmux_config $HOME/.config/tmux/tmux.conf

    switch (uname -s)
        case Darwin
            abbr --add less bat
            set -gx VISUAL bat
            direnv hook fish | source
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
            set -gx VISUAL batcat
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

source ~/.local/fish/config.fish
