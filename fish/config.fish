# ---- environment ----

set -x XDG_CONFIG_PATH $HOME/.config
set -x XDG_CONFIG_HOME $HOME/.config
set -x VOLTA_HOME $HOME/.volta

set -x PATH \
  $HOME/go/bin \
  /usr/local/go/bin \
  $HOME/.local/bin \
  $HOME/.cargo/bin \
  $HOME/.embulk/bin \
  $PATH

if test (uname -s) = Darwin
    set -x PATH /opt/homebrew/bin $PATH

    # The next line updates PATH for the Google Cloud SDK.
    if [ -f '/Users/naoya-furudono/google-cloud-sdk/path.fish.inc' ]
      source '/Users/naoya-furudono/google-cloud-sdk/path.fish.inc'
    end
else

    # The next line updates PATH for the Google Cloud SDK.
    if [ -f '/home/furudono/dev/google-cloud-sdk/path.fish.inc' ]
        source '/home/furudono/dev/google-cloud-sdk/path.fish.inc'
    end

    # TODO: use asdf
    set -x -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin /home/furudono/.ghcup/bin $PATH # ghcup-env
    pyenv init - | source
    source /home/furudono/.opam/opam-init/init.fish >/dev/null 2>/dev/null; or true
    set -x PATH $HOME/.local/swift-5.7.3-RELEASE-ubuntu22.04/usr/bin $PATH
end

source $HOME/.asdf/asdf.fish

# --- interactive ---

if status --is-interactive
    set -x -g fish_user_abbreviations

    abbr --add ls exa
    abbr --add v  nvim
    abbr --add gg git grep -n -1

    set -x EDITOR nvim
    set -x VISUAL nvim
    zoxide init fish | source

  if test (uname -s) = "Darwin"
    abbr --add less bat
    abbr --add k kubectl
    #rvm default
  else
    abbr --add less batcat
    abbr --add xremap   xremap $HOME/.config/xremap/xremap.conf --device 'Topre REALFORCE 87 US' 
  end

  fish_vi_key_bindings

# Do after `fish_vi_key_bindings`, which overwrites follows
  set -x fish_cursor_default block blink
  set -x fish_cursor_insert line # blink
  set -x fish_cursor_replace_one underscore # blink
  set -x fish_cursor_visual block

# no greeting
  set -x fish_greeting
end

# ---- load ----

source ~/.local/fish/init.fish.secret
