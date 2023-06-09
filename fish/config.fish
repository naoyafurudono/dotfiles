# ---- environment ----

set -x PATH ~/go/bin $PATH
set -x PATH /usr/local/go/bin $PATH
set -x PATH ~/.local/bin $PATH
set -x PATH ~/.cargo/bin $PATH
set -x PATH ~/.embulk/bin $PATH

set -x XDG_CONFIG_PATH ~/.config

if test (uname -s) = Darwin
    set -x PATH /opt/homebrew/bin $PATH
else
    set -x -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin /home/furudono/.ghcup/bin $PATH # ghcup-env

    pyenv init - | source

    # The next line updates PATH for the Google Cloud SDK.
    if [ -f '/home/furudono/dev/google-cloud-sdk/path.fish.inc' ]
        . '/home/furudono/dev/google-cloud-sdk/path.fish.inc'
    end

    # opam configuration
    source /home/furudono/.opam/opam-init/init.fish >/dev/null 2>/dev/null; or true
    set -x PATH ~/.local/swift-5.7.3-RELEASE-ubuntu22.04/usr/bin $PATH
end


# --- interactive ---

if status --is-interactive
    set -x -g fish_user_abbreviations

    abbr --add ls exa
    abbr --add v  nvim
    abbr --add gg git grep -n -1
    abbr --add cc 'fzf --print0 | xargs -0 -o code'

    set -x EDITOR nvim
    set -x VISUAL nvim
    source ~/.local/fish/init.fish


  if test (uname -s) = "Darwin"
    abbr --add less bat
  else
    abbr --add less batcat
    abbr --add xremap   xremap ~/.config/xremap/xremap.conf --device 'Topre REALFORCE 87 US' 
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

# rvm default

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/naoya-furudono/google-cloud-sdk/path.fish.inc' ]; . '/Users/naoya-furudono/google-cloud-sdk/path.fish.inc'; end
