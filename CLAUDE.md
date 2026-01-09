# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository managing configuration files for various development tools. It uses a whitelist approach in `.gitignore` - files must be explicitly un-ignored to be tracked.

## Adding New Configurations

To track new files, add negation patterns to `.gitignore`:
- For single files: `!path/to/file`
- For directories: `!dirname/**/*`

## Testing

Test setup.sh on Ubuntu (arm64):
```sh
cd test && docker build . -t test && docker run --rm test
```

## Key Configuration Paths

- **nvim/**: Neovim config using lazy.nvim plugin manager
  - `init.lua` loads `config/options`, `config/lazy`, `config/keymaps`
  - Plugins defined in `lua/plugins/`
- **fish/**: Fish shell config
  - `config.fish` main config, loads `~/.local/fish/config.fish` for machine-specific settings
- **git/**: Git configuration with global hooks in `hooks/`
- **zed/**: Zed editor settings
- **ghostty/**: Terminal emulator config

## Git Workflow Notes

- git hooks are stored in `git/hooks/` and configured via `core.hooksPath`
- Abbreviations for common git commands defined in fish config (a=add, c=commit, d=diff, s=status, p=pull)

## Working Preferences

- Review and update the task list after completing each task
- When the user's goal is achieved, improve the repository's CLAUDE.md based on the conversation if there are meaningful improvements
