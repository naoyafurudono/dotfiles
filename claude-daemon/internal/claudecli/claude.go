// Package claudecli wraps exec.Command for invoking the claude CLI.
// It strips environment variables that would trigger Claude Code's
// nested-session detection, allowing the daemon to call claude -p
// from within a Claude Code session (or from a launchd job that
// inherits those vars).
package claudecli

import (
	"os"
	"os/exec"
	"strings"
)

// nestBlockingEnvVars are environment variables that prevent nested Claude sessions.
var nestBlockingEnvVars = []string{
	"CLAUDECODE",
	"CLAUDE_CODE_ENTRYPOINT",
	"CLAUDE_CODE_SESSION_ACCESS_TOKEN",
}

// Command creates an exec.Cmd for the claude CLI with nesting prevention disabled.
func Command(args ...string) *exec.Cmd {
	cmd := exec.Command("claude", args...)
	cmd.Env = cleanEnv()
	return cmd
}

func cleanEnv() []string {
	blocked := make(map[string]bool)
	for _, v := range nestBlockingEnvVars {
		blocked[v] = true
	}

	var env []string
	for _, e := range os.Environ() {
		key, _, _ := strings.Cut(e, "=")
		if !blocked[key] {
			env = append(env, e)
		}
	}
	return env
}
