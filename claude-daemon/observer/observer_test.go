package observer

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/naoyafurudono/claude-daemon/state"
)

func TestUsageLogObserver_NoFile(t *testing.T) {
	store := state.NewStore(t.TempDir())
	obs := &UsageLogObserver{
		ObserverName: "test",
		LogPath:      "/nonexistent/file.tsv",
		Threshold:    5,
	}
	r, err := obs.Observe(store)
	if err != nil {
		t.Fatal(err)
	}
	if r.Output != "" {
		t.Error("expected empty output for missing file")
	}
}

func TestUsageLogObserver_BelowThreshold(t *testing.T) {
	dir := t.TempDir()
	logPath := filepath.Join(dir, "usage.tsv")
	os.WriteFile(logPath, []byte("header\nline1\nline2\n"), 0o644)

	store := state.NewStore(t.TempDir())
	obs := &UsageLogObserver{
		ObserverName: "test",
		LogPath:      logPath,
		Threshold:    5,
	}
	r, err := obs.Observe(store)
	if err != nil {
		t.Fatal(err)
	}
	if r.Output != "" {
		t.Error("expected empty output below threshold")
	}
}

func TestUsageLogObserver_AboveThreshold(t *testing.T) {
	dir := t.TempDir()
	logPath := filepath.Join(dir, "usage.tsv")

	var content string
	content = "timestamp\tmode\targs\thit_count\telapsed_ms\tquery\n"
	for i := range 10 {
		_ = i
		content += "2026-01-01T00:00:00Z\tlist\ttoday\t5\t200\ttest\n"
	}
	os.WriteFile(logPath, []byte(content), 0o644)

	store := state.NewStore(t.TempDir())
	obs := &UsageLogObserver{
		ObserverName: "test",
		LogPath:      logPath,
		Threshold:    5,
	}
	r, err := obs.Observe(store)
	if err != nil {
		t.Fatal(err)
	}
	if r.Output == "" {
		t.Error("expected non-empty output above threshold")
	}
}

func TestSessionScanObserver_NoSessions(t *testing.T) {
	store := state.NewStore(t.TempDir())
	obs := &SessionScanObserver{
		SessionsDir: t.TempDir(),
	}
	r, err := obs.Observe(store)
	if err != nil {
		t.Fatal(err)
	}
	if r.Output != "" {
		t.Error("expected empty output with no sessions")
	}
}

func TestRunAll(t *testing.T) {
	store := state.NewStore(t.TempDir())
	observers := []Observer{
		&UsageLogObserver{
			ObserverName: "test",
			LogPath:      "/nonexistent",
			Threshold:    1,
		},
	}
	reports := RunAll(observers, store)
	if len(reports) != 0 {
		t.Errorf("expected 0 reports, got %d", len(reports))
	}
}
