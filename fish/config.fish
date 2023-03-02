
# ---- environment ----

set PATH ~/go/bin $PATH
set PATH /usr/local/go/bin $PATH
set PATH ~/.local/bin $PATH
set PATH ~/.cargo/bin $PATH
set PATH ~/.local/swift-5.7.3-RELEASE-ubuntu22.04/usr/bin $PATH

set XDG_CONFIG_PATH ~/.config
set EDITOR nvim
set VISUAL nvim
# set PAGER bat

set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin /home/furudono/.ghcup/bin $PATH # ghcup-env

pyenv init - | source

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/furudono/dev/google-cloud-sdk/path.fish.inc' ]; . '/home/furudono/dev/google-cloud-sdk/path.fish.inc'; end

# opam configuration
source /home/furudono/.opam/opam-init/init.fish > /dev/null 2> /dev/null; or true

# --- interactive ---

if status --is-interactive
  set -g fish_user_abbreviations

  abbr --add ls       exa
  abbr --add v        nvim
  abbr --add gg       git grep -n -1

  if test (uname -s) = "Darwin"
    abbr --add less bat
  else
    abbr --add less batcat
    abbr --add xremap   xremap ~/.config/xremap/xremap.conf --device 'Topre REALFORCE 87 US' 
  end

end

fish_vi_key_bindings

# Do after `fish_vi_key_bindings`, which overwrites follows
set fish_cursor_default     block      blink
set fish_cursor_insert      line       # blink
set fish_cursor_replace_one underscore # blink
set fish_cursor_visual      block

# no greeting
set -U fish_config
