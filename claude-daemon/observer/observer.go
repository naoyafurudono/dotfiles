// Package observer implements change detectors for claude-daemon.
//
// Each observer watches a specific data source (usage logs, session files, error logs)
// and produces an aggregated [Report] when meaningful changes are detected.
// Reports contain only statistical summaries — never raw file contents —
// to prevent prompt injection when passed to the judge/executor LLM calls.
//
// Observers are stateful: they persist a checkpoint via [state.Store] so that
// each cycle only processes new data since the last run.
package observer

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/naoyafurudono/claude-daemon/state"
)

// Report is the output of a single observer run.
// An empty Output means no noteworthy change was detected.
type Report struct {
	Name   string
	Output string
}

// Observer detects changes in a data source and produces an aggregated report.
type Observer interface {
	Name() string
	Observe(store *state.Store) (Report, error)
}

// UsageLogObserver watches a TSV usage log file (e.g. session-recall.tsv)
// and reports aggregated stats (zero-hit rate, latency) when enough new
// entries accumulate past Threshold.
type UsageLogObserver struct {
	ObserverName string
	LogPath      string
	Threshold    int // minimum new lines to trigger
}

func (o *UsageLogObserver) Name() string { return o.ObserverName }

func (o *UsageLogObserver) Observe(store *state.Store) (Report, error) {
	st, err := store.LoadObserver(o.Name())
	if err != nil {
		return Report{Name: o.Name()}, err
	}

	data, err := os.ReadFile(o.LogPath)
	if err != nil {
		if os.IsNotExist(err) {
			return Report{Name: o.Name()}, nil
		}
		return Report{Name: o.Name()}, err
	}

	lines := strings.Split(strings.TrimSpace(string(data)), "\n")
	totalLines := len(lines)

	lastLine, _ := strconv.Atoi(st.LastValue)
	if lastLine == 0 {
		lastLine = 1 // skip header
	}

	newLines := totalLines - lastLine
	if newLines < o.Threshold {
		return Report{Name: o.Name()}, nil
	}

	// Compute aggregated stats only — no raw log content in reports.
	var total, zeroHits, totalMs, maxMs int
	modeCounts := make(map[string]int)
	modeZeroHits := make(map[string]int)
	for _, line := range lines[1:] {
		fields := strings.Split(line, "\t")
		if len(fields) < 5 {
			continue
		}
		total++
		mode := fields[1]
		modeCounts[mode]++
		if fields[3] == "0" {
			zeroHits++
			modeZeroHits[mode]++
		}
		if ms, err := strconv.Atoi(fields[4]); err == nil {
			totalMs += ms
			if ms > maxMs {
				maxMs = ms
			}
		}
	}

	var avgMs int
	if total > 0 {
		avgMs = totalMs / total
	}
	zeroHitPct := 0
	if total > 0 {
		zeroHitPct = zeroHits * 100 / total
	}

	var modeLines []string
	for mode, count := range modeCounts {
		zeros := modeZeroHits[mode]
		modeLines = append(modeLines, fmt.Sprintf("  - %s: %d queries, %d zero-hits", mode, count, zeros))
	}

	report := fmt.Sprintf(`## %s usage-log report
New entries since last check: %d
Total queries: %d | Zero-hit rate: %d%% | Avg latency: %dms | Max latency: %dms

By mode:
%s`,
		o.ObserverName, newLines, total, zeroHitPct, avgMs, maxMs,
		strings.Join(modeLines, "\n"))

	// Update state
	st.LastRun = time.Now()
	st.LastValue = strconv.Itoa(totalLines)
	if err := store.SaveObserver(o.Name(), st); err != nil {
		return Report{Name: o.Name(), Output: report}, err
	}

	return Report{Name: o.Name(), Output: report}, nil
}

// SessionScanObserver scans Claude Code session JSONL files for user frustration
// signals (e.g. "うまくいかない", "やり直し"). It reports counts by pattern and
// project — never the raw session content — to avoid prompt injection.
type SessionScanObserver struct {
	SessionsDir string
	MinInterval time.Duration
}

func (o *SessionScanObserver) Name() string { return "session-scan" }

func (o *SessionScanObserver) Observe(store *state.Store) (Report, error) {
	st, err := store.LoadObserver(o.Name())
	if err != nil {
		return Report{Name: o.Name()}, err
	}

	if !st.LastRun.IsZero() && time.Since(st.LastRun) < o.MinInterval {
		return Report{Name: o.Name()}, nil
	}

	// Find session files modified since last run
	cutoff := st.LastRun
	if cutoff.IsZero() {
		cutoff = time.Now().Add(-24 * time.Hour)
	}

	var recentFiles []string
	err = filepath.Walk(o.SessionsDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // skip errors
		}
		if info.IsDir() {
			if strings.Contains(path, "subagents") {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(path, ".jsonl") {
			return nil
		}
		if info.ModTime().After(cutoff) {
			recentFiles = append(recentFiles, path)
		}
		return nil
	})
	if err != nil {
		return Report{Name: o.Name()}, err
	}

	if len(recentFiles) == 0 {
		return Report{Name: o.Name()}, nil
	}

	// Scan for frustration signals in recent sessions
	frustrationPatterns := []string{
		"うまくいかない", "違う", "もう一回", "やり直し",
		"間違", "ダメ", "使いにくい", "おかしい",
	}

	// Count frustration signals per pattern and per project.
	// Only pass aggregated stats to avoid injecting raw session content into prompts.
	patternCounts := make(map[string]int)
	projectCounts := make(map[string]int)
	totalFindings := 0

	for _, f := range recentFiles {
		data, err := os.ReadFile(f)
		if err != nil {
			continue
		}
		content := string(data)
		for _, pat := range frustrationPatterns {
			if strings.Contains(content, pat) {
				patternCounts[pat]++
				relPath, _ := filepath.Rel(o.SessionsDir, f)
				project := strings.SplitN(relPath, "/", 2)[0]
				projectCounts[project]++
				totalFindings++
				break // one finding per file
			}
		}
	}

	if totalFindings == 0 {
		st.LastRun = time.Now()
		store.SaveObserver(o.Name(), st)
		return Report{Name: o.Name()}, nil
	}

	var patternLines []string
	for pat, count := range patternCounts {
		patternLines = append(patternLines, fmt.Sprintf("  - '%s': %d sessions", pat, count))
	}
	var projectLines []string
	for proj, count := range projectCounts {
		projectLines = append(projectLines, fmt.Sprintf("  - %s: %d signals", proj, count))
	}

	report := fmt.Sprintf(`## session-scan report
Scanned %d recent sessions since %s
Found %d frustration signals (aggregated, no raw content):

By pattern:
%s

By project:
%s`,
		len(recentFiles), cutoff.Format("2006-01-02 15:04"),
		totalFindings,
		strings.Join(patternLines, "\n"),
		strings.Join(projectLines, "\n"))

	st.LastRun = time.Now()
	store.SaveObserver(o.Name(), st)

	return Report{Name: o.Name(), Output: report}, nil
}

// ErrorRateObserver scans *.log files in a directory for error keywords
// and reports per-file error counts. Only files modified within the last 48h
// are checked.
type ErrorRateObserver struct {
	LogDir      string
	MinInterval time.Duration
}

func (o *ErrorRateObserver) Name() string { return "error-rate" }

func (o *ErrorRateObserver) Observe(store *state.Store) (Report, error) {
	st, err := store.LoadObserver(o.Name())
	if err != nil {
		return Report{Name: o.Name()}, err
	}

	if !st.LastRun.IsZero() && time.Since(st.LastRun) < o.MinInterval {
		return Report{Name: o.Name()}, nil
	}

	// Scan log files for error patterns
	entries, err := os.ReadDir(o.LogDir)
	if err != nil {
		if os.IsNotExist(err) {
			return Report{Name: o.Name()}, nil
		}
		return Report{Name: o.Name()}, err
	}

	errorPatterns := []string{"error", "Error", "ERROR", "failed", "Failed", "FAILED", "panic"}
	var findings []string

	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".log") {
			continue
		}
		info, err := entry.Info()
		if err != nil {
			continue
		}
		// Only check recent logs
		if time.Since(info.ModTime()) > 48*time.Hour {
			continue
		}

		data, err := os.ReadFile(filepath.Join(o.LogDir, entry.Name()))
		if err != nil {
			continue
		}
		lines := strings.Split(string(data), "\n")
		errorCount := 0
		for _, line := range lines {
			for _, pat := range errorPatterns {
				if strings.Contains(line, pat) {
					errorCount++
					break
				}
			}
		}
		if errorCount > 0 {
			findings = append(findings, fmt.Sprintf("- %s: %d errors in %d lines",
				entry.Name(), errorCount, len(lines)))
		}
	}

	st.LastRun = time.Now()
	store.SaveObserver(o.Name(), st)

	if len(findings) == 0 {
		return Report{Name: o.Name()}, nil
	}

	report := fmt.Sprintf(`## error-rate report
Found errors in log files:

%s`, strings.Join(findings, "\n"))

	return Report{Name: o.Name(), Output: report}, nil
}

// RunAll executes all observers and returns reports with non-empty output.
// Observer errors are included as reports rather than silently dropped.
func RunAll(observers []Observer, store *state.Store) []Report {
	var reports []Report
	for _, obs := range observers {
		r, err := obs.Observe(store)
		if err != nil {
			// Include error as a report
			reports = append(reports, Report{
				Name:   obs.Name(),
				Output: fmt.Sprintf("Observer error: %v", err),
			})
			continue
		}
		if r.Output != "" {
			reports = append(reports, r)
		}
	}
	return reports
}
