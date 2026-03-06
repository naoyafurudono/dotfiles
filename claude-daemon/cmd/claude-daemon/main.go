package main

import (
	"fmt"
	"os"
	"strconv"
	"time"

	daemon "github.com/naoyafurudono/claude-daemon"
)

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}

	cfg := daemon.DefaultConfig()
	d, err := daemon.New(cfg)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error initializing daemon: %v\n", err)
		os.Exit(1)
	}

	switch os.Args[1] {
	case "run":
		fmt.Println(d.RunCycle())

	case "loop":
		interval := 30 * time.Minute
		if len(os.Args) > 2 {
			if dur, err := time.ParseDuration(os.Args[2]); err == nil {
				interval = dur
			}
		}
		fmt.Printf("Starting daemon loop (interval: %s)\n", interval)
		for {
			result := d.RunCycle()
			fmt.Printf("[%s] %s\n", time.Now().Format("15:04:05"), firstLine(result))
			time.Sleep(interval)
		}

	case "observe":
		reports := d.Observe()
		if len(reports) == 0 {
			fmt.Println("No changes detected.")
			return
		}
		for _, r := range reports {
			fmt.Printf("=== %s ===\n%s\n\n", r.Name, r.Output)
		}

	case "judge":
		decision, reports, err := d.Judge()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Judge error: %v\n", err)
			os.Exit(1)
		}
		if len(reports) == 0 {
			fmt.Println("No changes detected by observers.")
			return
		}
		fmt.Printf("Observer reports: %d\n", len(reports))
		for _, r := range reports {
			fmt.Printf("  - %s\n", r.Name)
		}
		fmt.Printf("\nDecision:\n")
		fmt.Printf("  Should improve: %v\n", decision.ShouldImprove)
		fmt.Printf("  Target: %s\n", decision.Target)
		fmt.Printf("  Reason: %s\n", decision.Reason)
		fmt.Printf("  Plan: %s\n", decision.Plan)

	case "status":
		fmt.Println(d.Status())

	case "history":
		n := 10
		if len(os.Args) > 2 {
			if v, err := strconv.Atoi(os.Args[2]); err == nil {
				n = v
			}
		}
		records, err := d.History(n)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		if len(records) == 0 {
			fmt.Println("No history.")
			return
		}
		for _, r := range records {
			commit := r.Commit
			if len(commit) > 7 {
				commit = commit[:7]
			}
			fmt.Printf("%s  %-20s  [%s]  %s  %s\n",
				r.Timestamp.Format("2006-01-02 15:04"),
				r.Target, r.Result, r.Reason, commit)
		}

	default:
		usage()
		os.Exit(1)
	}
}

func usage() {
	fmt.Fprintf(os.Stderr, `claude-daemon - Autonomous improvement agent for Claude Code

Usage:
  claude-daemon run               Run one observe → judge → execute cycle
  claude-daemon loop [interval]   Run continuously (default: 30m)
  claude-daemon observe           Run observers only (dry run)
  claude-daemon judge             Run observe + judge (dry run, no execution)
  claude-daemon status            Show current status and budget
  claude-daemon history [N]       Show last N improvements (default: 10)
`)
}

func firstLine(s string) string {
	for i, c := range s {
		if c == '\n' {
			return s[:i]
		}
	}
	return s
}
