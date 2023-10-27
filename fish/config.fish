# ---- environment ----

set -x XDG_CONFIG_PATH $HOME/.config
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_DATA_HOME $HOME/.local
set -x VOLTA_HOME $HOME/.volta

set -x PATH \
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

# if npm installed
if type -q npm
    set -x PATH $(npm prefix --location=global)/bin $PATH
end

if test (uname -s) = Darwin
    set -x PATH /opt/homebrew/bin $PATH

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

    # TODO: use asdf
    set -x -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME
    set -gx PATH $HOME/.cabal/bin /home/furudono/.ghcup/bin $PATH # ghcup-env
    if type -q pyenv
      pyenv init - | source
    end
    source /home/furudono/.opam/opam-init/init.fish >/dev/null 2>/dev/null; or true
    set -x PATH $HOME/.local/swift-5.7.3-RELEASE-ubuntu22.04/usr/bin $PATH
end

source $HOME/.asdf/asdf.fish

# --- interactive ---

if status --is-interactive
    set -x -g fish_user_abbreviations

    abbr --add ls exa
    abbr --add v nvim
    abbr --add g git
    abbr --add d 'git diff'
    abbr --add s 'git status'
    abbr --add a 'git add'
    abbr --add c 'git c'
    abbr --add p 'git push'
    abbr --add gu 'git add -A && git commit -am update && git push && git diff HEAD^' # 必要悪 :(
    abbr --add te 'textql -header -output-header -sql'
    abbr --add k kubectl
    abbr --add rg 'rg --ignore-case'
    abbr --add rgc 'rg'

    set -x EDITOR nvim
    set -x _ZO_DATA_DIR $XDG_DATA_HOME/zoxide
    zoxide init fish --cmd j | source

    switch (uname -s)
        case Darwin
            abbr --add less bat
            #rvm default
            set -x VISUAL bat
        case Linux
            abbr --add less batcat
            set -x VISUAL batcat
            abbr --add xremap xremap $XDG_CONFIG_HOME/xremap/xremap.conf --device \'Topre REALFORCE 87 US\'
        case '*'
            echo "unknown uname"
            exit 1
    end

    fish_vi_key_bindings

    # Do after `fish_vi_key_bindings`, which overwrites follows
    set -x fish_cursor_default block
    set -x fish_cursor_insert line
    set -x fish_cursor_replace_one underscore
    set -x fish_cursor_visual block

    # no greeting
    set -x fish_greeting
end

# ---- load ----

source ~/.local/fish/init.fish.secret

