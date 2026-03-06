// Package judge decides whether and what to improve.
//
// It sends observer reports and recent history to Claude (haiku model)
// and receives a structured JSON decision. The LLM session is sandboxed:
// all tools are disallowed so it can only produce text output.
package judge

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"

	"github.com/naoyafurudono/claude-daemon/internal/claudecli"
	"github.com/naoyafurudono/claude-daemon/observer"
	"github.com/naoyafurudono/claude-daemon/state"
)

// Decision is the structured output of the judge LLM call.
type Decision struct {
	ShouldImprove bool   `json:"should_improve"`
	Target        string `json:"target"`
	Reason        string `json:"reason"`
	Plan          string `json:"plan"`
}

// Judge sends observer reports to an LLM and returns a Decision.
// It truncates each report to 2000 chars to limit prompt size.
// Returns a zero Decision (ShouldImprove=false) when reports is empty.
func Judge(reports []observer.Report, history []state.RunRecord) (Decision, error) {
	if len(reports) == 0 {
		return Decision{}, nil
	}

	var sb strings.Builder
	sb.WriteString("# Observer Reports\n\n")
	for _, r := range reports {
		output := r.Output
		if len(output) > 2000 {
			output = output[:2000] + "\n...(truncated)"
		}
		sb.WriteString(output)
		sb.WriteString("\n\n")
	}

	if len(history) > 0 {
		sb.WriteString("# Recent Improvement History\n\n")
		limit := min(len(history), 10)
		for _, h := range history[len(history)-limit:] {
			sb.WriteString(fmt.Sprintf("- %s: target=%s result=%s reason=%s\n",
				h.Timestamp.Format("2006-01-02"), h.Target, h.Result, h.Reason))
		}
	}

	prompt := fmt.Sprintf(`You are the judge component of claude-daemon, an autonomous improvement system for Claude Code configuration, skills, and tools.

Given the following observer reports and recent history, decide whether an improvement should be made.

%s

Respond ONLY with a JSON object (no markdown fences):
{
  "should_improve": true/false,
  "target": "what to improve (e.g. session-recall, settings.json, CLAUDE.md, hooks, fish config)",
  "reason": "why this improvement is needed",
  "plan": "brief description of what to change"
}

Rules:
- Only suggest improvements with clear evidence from the reports
- Don't suggest the same improvement that was recently done (check history)
- Prefer high-impact, low-risk changes
- If no clear improvement is needed, set should_improve to false`, sb.String())

	cmd := claudecli.Command("-p",
		"--model", "haiku",
		"--output-format", "text",
		"--max-budget-usd", "0.50",
		"--disallowed-tools", "Bash,Read,Write,Edit,Glob,Grep,WebFetch,WebSearch,NotebookEdit",
		prompt)

	out, err := cmd.Output()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			return Decision{}, fmt.Errorf("claude judge failed: %s", string(exitErr.Stderr))
		}
		return Decision{}, fmt.Errorf("claude judge failed: %w", err)
	}

	// Parse JSON from output (may have surrounding text)
	output := strings.TrimSpace(string(out))
	jsonStart := strings.Index(output, "{")
	jsonEnd := strings.LastIndex(output, "}")
	if jsonStart < 0 || jsonEnd < 0 {
		return Decision{}, fmt.Errorf("no JSON in judge output: %s", output)
	}

	var dec Decision
	if err := json.Unmarshal([]byte(output[jsonStart:jsonEnd+1]), &dec); err != nil {
		return Decision{}, fmt.Errorf("invalid judge JSON: %w\nraw: %s", err, output)
	}

	return dec, nil
}
