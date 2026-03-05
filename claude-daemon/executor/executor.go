// Package executor runs a Claude Code session to apply an improvement.
//
// The session is sandboxed with an explicit tool whitelist (Read, Glob, Grep,
// Edit, Write, Bash(git:*), Bash(shellcheck:*)) and a deny list that prevents
// self-modification of the daemon source and network access. The executor
// commits changes but never pushes — the human reviews and pushes.
package executor

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/naoyafurudono/dotfiles/claude-daemon/internal/claudecli"
	"github.com/naoyafurudono/dotfiles/claude-daemon/judge"
)

// Result is the outcome of an executor run.
type Result struct {
	Commit string
	Output string
	Error  string
}

// allowedTools is the whitelist of tools the executor can use.
// No network access, no arbitrary commands — only file operations and git.
var allowedTools = []string{
	"Read",
	"Glob",
	"Grep",
	"Edit",
	"Write",
	"Bash(git:*)",
	"Bash(shellcheck:*)",
}

// disallowedTools prevents self-modification and dangerous operations.
var disallowedTools = []string{
	"Edit(claude-daemon/*)",
	"Write(claude-daemon/*)",
	"Bash(rm:*)",
	"Bash(curl:*)",
	"Bash(wget:*)",
}

// Execute launches a sandboxed Claude session to apply the improvement
// described in decision. It returns the commit hash on success, or an error message.
func Execute(decision judge.Decision, repoDir string, budgetUSD float64) Result {
	prompt := buildPrompt(decision)

	args := []string{
		"-p",
		"--model", "sonnet",
		"--max-budget-usd", fmt.Sprintf("%.2f", budgetUSD),
		"--output-format", "text",
		"--allowed-tools", strings.Join(allowedTools, ","),
		"--disallowed-tools", strings.Join(disallowedTools, ","),
		"--permission-mode", "default",
		prompt,
	}
	cmd := claudecli.Command(args...)
	cmd.Dir = repoDir

	out, err := cmd.Output()
	if err != nil {
		errMsg := err.Error()
		if exitErr, ok := err.(*exec.ExitError); ok {
			errMsg = string(exitErr.Stderr)
		}
		return Result{Error: errMsg}
	}

	output := string(out)

	// Check if a commit was made
	commit := extractCommit(repoDir)

	return Result{
		Commit: commit,
		Output: truncateOutput(output, 2000),
	}
}

func buildPrompt(decision judge.Decision) string {
	return fmt.Sprintf(`You are the executor component of claude-daemon, an autonomous improvement agent for Claude Code.

## Task

Improve: %s
Reason: %s
Plan: %s

## Target files

This repository (dotfiles) contains Claude Code configuration.
~/.claude is a symlink to ~/.config/claude, which maps to the claude/ directory in this repo.

Key paths:
- claude/skills/*/SKILL.md - Skill definitions
- claude/skills/*/scripts/ - Skill scripts
- claude/skills/*/REQUIREMENTS.md - Skill requirements
- claude/settings.json - Claude Code settings (hooks, permissions, plugins)
- CLAUDE.md - Project instructions
- claude/cron/ - Existing automation scripts
- fish/ - Fish shell config
- nvim/ - Neovim config
- git/ - Git config

## Rules

1. Read the target files first to understand the current state
2. Make the minimal change that addresses the issue
3. Test your changes if possible (run scripts, check syntax)
4. If the change is good, git commit with prefix "[claude-daemon] "
5. Do NOT git push
6. If no improvement is actually needed after reading the code, do nothing
7. Keep changes focused - one improvement per execution

## FORBIDDEN — do NOT modify these

- claude-daemon/ — the daemon's own source code (self-modification is prohibited)
- .gitignore
- .git/`, decision.Target, decision.Reason, decision.Plan)
}

func extractCommit(repoDir string) string {
	cmd := exec.Command("git", "log", "-1", "--format=%H", "--since=1 minute ago")
	cmd.Dir = repoDir
	out, err := cmd.Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func truncateOutput(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "\n...(truncated)"
}
