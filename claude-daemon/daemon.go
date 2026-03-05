// Package daemon is the core of claude-daemon, an autonomous improvement
// agent for Claude Code configuration, skills, and tools.
//
// Each cycle runs three phases:
//  1. OBSERVE — detect changes via observers (cost: $0, pure file I/O)
//  2. JUDGE — ask an LLM whether improvement is needed (cost: ~$0.01–0.50)
//  3. EXECUTE — apply the improvement via a sandboxed Claude session (cost: ~$1)
//
// Safety mechanisms prevent runaway spending and unintended changes:
//   - Daily/monthly budget limits
//   - Exponential backoff after consecutive failures
//   - Cooldown per improvement target
//   - Executor tool whitelist (no network, no self-modification)
//   - Observer reports contain only aggregated stats, never raw content
package daemon

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/naoyafurudono/dotfiles/claude-daemon/budget"
	"github.com/naoyafurudono/dotfiles/claude-daemon/executor"
	"github.com/naoyafurudono/dotfiles/claude-daemon/judge"
	"github.com/naoyafurudono/dotfiles/claude-daemon/observer"
	"github.com/naoyafurudono/dotfiles/claude-daemon/state"
)

// Config holds paths and budget settings for the daemon.
type Config struct {
	RepoDir  string
	StateDir string
	LogDir   string
	Budget   budget.Config
}

// DefaultConfig returns the standard configuration for naoyafurudono's dotfiles setup.
func DefaultConfig() Config {
	home, _ := os.UserHomeDir()
	return Config{
		RepoDir:  filepath.Join(home, "src/github.com/naoyafurudono/dotfiles"),
		StateDir: filepath.Join(home, ".claude/daemon/state"),
		LogDir:   filepath.Join(home, ".claude/daemon/logs"),
		Budget: budget.Config{
			DailyUSD:   3.0,
			MonthlyUSD: 30.0,
			PerRunUSD:  1.0,
		},
	}
}

// Daemon orchestrates the observe → judge → execute cycle.
type Daemon struct {
	config    Config
	store     *state.Store
	budget    *budget.Manager
	observers []observer.Observer
	logger    *log.Logger
}

// New creates a Daemon with the standard set of observers.
func New(cfg Config) (*Daemon, error) {
	if err := os.MkdirAll(cfg.LogDir, 0o755); err != nil {
		return nil, err
	}

	logFile, err := os.OpenFile(
		filepath.Join(cfg.LogDir, "daemon.log"),
		os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return nil, err
	}
	logger := log.New(logFile, "", log.LstdFlags)

	home, _ := os.UserHomeDir()
	store := state.NewStore(cfg.StateDir)
	budgetMgr := budget.NewManager(cfg.Budget, cfg.StateDir)

	observers := []observer.Observer{
		&observer.UsageLogObserver{
			ObserverName: "session-recall",
			LogPath:      filepath.Join(home, ".claude/usage/session-recall.tsv"),
			Threshold:    5,
		},
		&observer.SessionScanObserver{
			SessionsDir: filepath.Join(home, ".claude/projects"),
			MinInterval: 6 * time.Hour,
		},
		&observer.ErrorRateObserver{
			LogDir:      filepath.Join(home, ".claude/daemon/logs"),
			MinInterval: 6 * time.Hour,
		},
	}

	return &Daemon{
		config:    cfg,
		store:     store,
		budget:    budgetMgr,
		observers: observers,
		logger:    logger,
	}, nil
}

// maxConsecutiveFailures is the number of consecutive failures before backing off.
const maxConsecutiveFailures = 3

// sameTargetCooldown prevents executing the same target within this duration.
const sameTargetCooldown = 3 * time.Hour

// RunCycle executes one observe → judge → execute cycle.
// Returns a summary of what happened.
func (d *Daemon) RunCycle() string {
	d.logger.Println("Starting cycle")

	// Safety: check for consecutive failures — exponential backoff
	if msg, shouldSkip := d.checkBackoff(); shouldSkip {
		d.logger.Println(msg)
		return msg
	}

	// Phase 1: OBSERVE
	reports := observer.RunAll(d.observers, d.store)
	if len(reports) == 0 {
		d.logger.Println("No changes detected")
		return "No changes detected by observers."
	}

	d.logger.Printf("Observers produced %d reports", len(reports))

	var reportSummary []string
	for _, r := range reports {
		reportSummary = append(reportSummary, fmt.Sprintf("  - %s", r.Name))
	}

	// Phase 2: JUDGE
	canSpend, reason := d.budget.CanSpend()
	if !canSpend {
		msg := fmt.Sprintf("Budget limit reached: %s. Reports collected but not acted on.", reason)
		d.logger.Println(msg)
		return fmt.Sprintf("Observer reports:\n%s\n\n%s", strings.Join(reportSummary, "\n"), msg)
	}

	history, _ := d.store.LoadHistory(10)
	decision, err := judge.Judge(reports, history)
	if err != nil {
		d.logger.Printf("Judge error: %v", err)
		return fmt.Sprintf("Observer reports:\n%s\n\nJudge error: %v", strings.Join(reportSummary, "\n"), err)
	}

	if !decision.ShouldImprove {
		d.logger.Printf("Judge decided no improvement needed")
		d.store.AppendHistory(state.RunRecord{
			Timestamp: time.Now(),
			Target:    decision.Target,
			Reason:    decision.Reason,
			Result:    "skipped",
		})
		return fmt.Sprintf("Observer reports:\n%s\n\nJudge: no improvement needed (%s)",
			strings.Join(reportSummary, "\n"), decision.Reason)
	}

	// Safety: prevent same target from being executed too frequently
	if msg, shouldSkip := d.checkTargetCooldown(decision.Target, history); shouldSkip {
		d.logger.Println(msg)
		return fmt.Sprintf("Observer reports:\n%s\n\n%s", strings.Join(reportSummary, "\n"), msg)
	}

	d.logger.Printf("Judge decided to improve: target=%s reason=%s", decision.Target, decision.Reason)

	// Phase 3: EXECUTE
	result := executor.Execute(decision, d.config.RepoDir, d.budget.Config().PerRunUSD)

	rec := state.RunRecord{
		Timestamp: time.Now(),
		Target:    decision.Target,
		Reason:    decision.Reason,
	}

	if result.Error != "" {
		rec.Result = "failure"
		rec.Error = result.Error
		d.logger.Printf("Execution failed: %s", result.Error)
	} else {
		rec.Result = "success"
		rec.Commit = result.Commit
		rec.CostUSD = d.budget.Config().PerRunUSD // approximate
		d.budget.Spend(d.budget.Config().PerRunUSD)
		d.logger.Printf("Execution succeeded: commit=%s", result.Commit)
	}

	d.store.AppendHistory(rec)

	return fmt.Sprintf(`Cycle complete:
  Observers: %s
  Decision: improve %s (%s)
  Plan: %s
  Result: %s
  Commit: %s`,
		strings.Join(reportSummary, ", "),
		decision.Target, decision.Reason,
		decision.Plan,
		rec.Result, rec.Commit)
}

// Observe runs only the observe phase and returns reports (dry-run mode).
func (d *Daemon) Observe() []observer.Report {
	return observer.RunAll(d.observers, d.store)
}

// Status returns a human-readable summary of budget usage and recent history.
func (d *Daemon) Status() string {
	dayUsed, dayLimit, monthUsed, monthLimit, err := d.budget.Status()
	if err != nil {
		return fmt.Sprintf("Budget error: %v", err)
	}

	history, _ := d.store.LoadHistory(5)

	var sb strings.Builder
	sb.WriteString("# claude-daemon status\n\n")
	sb.WriteString(fmt.Sprintf("Budget: $%.2f/$%.2f daily | $%.2f/$%.2f monthly\n",
		dayUsed, dayLimit, monthUsed, monthLimit))
	sb.WriteString(fmt.Sprintf("State dir: %s\n", d.store.Dir()))
	sb.WriteString(fmt.Sprintf("Repo: %s\n\n", d.config.RepoDir))

	if len(history) > 0 {
		sb.WriteString("## Recent history\n\n")
		for _, h := range history {
			sb.WriteString(fmt.Sprintf("- %s: %s [%s] %s\n",
				h.Timestamp.Format("2006-01-02 15:04"),
				h.Target, h.Result, h.Reason))
		}
	} else {
		sb.WriteString("No history yet.\n")
	}

	return sb.String()
}

// Judge runs observe + judge phases without executing (dry-run mode).
func (d *Daemon) Judge() (judge.Decision, []observer.Report, error) {
	reports := observer.RunAll(d.observers, d.store)
	if len(reports) == 0 {
		return judge.Decision{}, nil, nil
	}
	history, _ := d.store.LoadHistory(10)
	decision, err := judge.Judge(reports, history)
	return decision, reports, err
}

// History returns the last N run records.
func (d *Daemon) History(n int) ([]state.RunRecord, error) {
	return d.store.LoadHistory(n)
}

// checkBackoff returns a skip message if too many consecutive failures occurred.
func (d *Daemon) checkBackoff() (string, bool) {
	history, _ := d.store.LoadHistory(maxConsecutiveFailures)
	if len(history) < maxConsecutiveFailures {
		return "", false
	}

	consecutiveFails := 0
	for i := len(history) - 1; i >= 0; i-- {
		if history[i].Result == "failure" {
			consecutiveFails++
		} else {
			break
		}
	}

	if consecutiveFails < maxConsecutiveFailures {
		return "", false
	}

	lastFail := history[len(history)-1]
	backoffDuration := time.Duration(1<<uint(consecutiveFails-maxConsecutiveFailures)) * time.Hour
	if time.Since(lastFail.Timestamp) < backoffDuration {
		return fmt.Sprintf("Backing off: %d consecutive failures (next retry after %s)",
			consecutiveFails, lastFail.Timestamp.Add(backoffDuration).Format("15:04")), true
	}
	return "", false
}

// checkTargetCooldown returns a skip message if the same target was recently executed.
func (d *Daemon) checkTargetCooldown(target string, history []state.RunRecord) (string, bool) {
	for i := len(history) - 1; i >= 0; i-- {
		h := history[i]
		if h.Target == target && (h.Result == "success" || h.Result == "failure") {
			if time.Since(h.Timestamp) < sameTargetCooldown {
				return fmt.Sprintf("Target '%s' was executed %s ago (cooldown: %s)",
					target, time.Since(h.Timestamp).Round(time.Minute), sameTargetCooldown), true
			}
			break
		}
	}
	return "", false
}
