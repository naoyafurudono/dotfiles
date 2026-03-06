package daemon

import (
	"testing"
	"time"

	"github.com/naoyafurudono/claude-daemon/state"
)

func TestCheckBackoff_NoHistory(t *testing.T) {
	d := &Daemon{store: state.NewStore(t.TempDir())}
	msg, skip := d.checkBackoff()
	if skip {
		t.Errorf("should not skip with no history, got: %s", msg)
	}
}

func TestCheckBackoff_BelowThreshold(t *testing.T) {
	store := state.NewStore(t.TempDir())
	store.AppendHistory(state.RunRecord{Timestamp: time.Now(), Result: "failure"})
	store.AppendHistory(state.RunRecord{Timestamp: time.Now(), Result: "failure"})
	store.AppendHistory(state.RunRecord{Timestamp: time.Now(), Result: "success"})

	d := &Daemon{store: store}
	_, skip := d.checkBackoff()
	if skip {
		t.Error("should not skip when last result is success")
	}
}

func TestCheckBackoff_Triggers(t *testing.T) {
	store := state.NewStore(t.TempDir())
	for range maxConsecutiveFailures {
		store.AppendHistory(state.RunRecord{Timestamp: time.Now(), Result: "failure"})
	}

	d := &Daemon{store: store}
	msg, skip := d.checkBackoff()
	if !skip {
		t.Error("should skip after consecutive failures")
	}
	if msg == "" {
		t.Error("expected non-empty backoff message")
	}
}

func TestCheckBackoff_Expired(t *testing.T) {
	store := state.NewStore(t.TempDir())
	oldTime := time.Now().Add(-2 * time.Hour)
	for range maxConsecutiveFailures {
		store.AppendHistory(state.RunRecord{Timestamp: oldTime, Result: "failure"})
	}

	d := &Daemon{store: store}
	_, skip := d.checkBackoff()
	if skip {
		t.Error("should not skip after backoff duration has expired")
	}
}

func TestCheckTargetCooldown_NoMatch(t *testing.T) {
	d := &Daemon{}
	history := []state.RunRecord{
		{Timestamp: time.Now(), Target: "other", Result: "success"},
	}
	_, skip := d.checkTargetCooldown("session-recall", history)
	if skip {
		t.Error("should not skip for different target")
	}
}

func TestCheckTargetCooldown_Triggers(t *testing.T) {
	d := &Daemon{}
	history := []state.RunRecord{
		{Timestamp: time.Now(), Target: "session-recall", Result: "success"},
	}
	msg, skip := d.checkTargetCooldown("session-recall", history)
	if !skip {
		t.Error("should skip for recently executed target")
	}
	if msg == "" {
		t.Error("expected non-empty cooldown message")
	}
}

func TestCheckTargetCooldown_Expired(t *testing.T) {
	d := &Daemon{}
	history := []state.RunRecord{
		{Timestamp: time.Now().Add(-4 * time.Hour), Target: "session-recall", Result: "success"},
	}
	_, skip := d.checkTargetCooldown("session-recall", history)
	if skip {
		t.Error("should not skip after cooldown expired")
	}
}

func TestCheckTargetCooldown_SkippedDoesNotBlock(t *testing.T) {
	d := &Daemon{}
	history := []state.RunRecord{
		{Timestamp: time.Now(), Target: "session-recall", Result: "skipped"},
	}
	_, skip := d.checkTargetCooldown("session-recall", history)
	if skip {
		t.Error("skipped results should not trigger cooldown")
	}
}
