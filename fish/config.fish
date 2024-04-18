# ---- environment ----

set -gx XDG_CONFIG_PATH $HOME/.config
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local
set -gx VOLTA_HOME $HOME/.volta

set -gx PATH \
    /opt/homebrew/opt/ruby/bin \
    /opt/homebrew/opt/postgresql@15/bin \
    $HOME/.krew/bin \
    $HOME/go/bin \
    /usr/local/go/bin \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $HOME/.embulk/bin \
    $PATH

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/furudono/.local/google-cloud-sdk/path.fish.inc' ]; 
  source '/Users/furudono/.local/google-cloud-sdk/path.fish.inc'
end

if test (uname -s) = Darwin
    set -gx PATH /opt/homebrew/bin $PATH

    # The next line updates PATH for the Google Cloud SDK.
    if [ -f '/Users/naoya-furudono/google-cloud-sdk/path.fish.inc' ]
        source '/Users/naoya-furudono/google-cloud-sdk/path.fish.inc'
    end
     source /Users/furudono/.opam/opam-init/init.fish > /dev/null 2> /dev/null; or true
else
    # The next line updates PATH for the Google Cloud SDK.
    if [ -f '/home/furudono/dev/google-cloud-sdk/path.fish.inc' ]
        source '/home/furudono/dev/google-cloud-sdk/path.fish.inc'
    end
end

# --- interactive ---

if status --is-interactive
    set -gx fish_user_abbreviations

    abbr --add l eza
    abbr --add v nvim
    abbr --add g git
    abbr --add d 'git diff'
    abbr --add s 'git status'
    abbr --add w 'git switch'
    abbr --add a 'git add'
    abbr --add c 'git c'
    abbr --add p 'git pull'
    abbr --add gu 'git add -A && git commit -m update && git push && git diff HEAD^' # 必要悪 :(
    abbr --add gd 'git commit --allow-empty -m deploy && git push'
    abbr --add te 'textql -header -output-header -sql'
    abbr --add k kubectl
    abbr --add rg 'rg --smart-case'
    abbr --add rgc 'rg'
    abbr --add dr 'docker compose exec worker bundle exec'
    abbr --add xd 'git diff --name-only (git show-branch --merge-base master HEAD) | xargs '
    abbr --add ru 'git ls-files --others --exclude-standard | xargs rm'
    abbr --add cs 'gh copilot suggest'
    abbr --add ce 'gh copilot explain'

    set -gx EDITOR nvim
    set -gx _ZO_DATA_DIR $XDG_DATA_HOME/zoxide
    zoxide init fish --cmd j | source
    mise activate fish | source
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'

    switch (uname -s)
        case Darwin
            abbr --add less bat
            #rvm default
            set -gx VISUAL bat
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

source ~/.local/fish/init.fish.secret

