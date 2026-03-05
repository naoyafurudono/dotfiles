package state

import (
	"testing"
	"time"
)

func TestObserverStateRoundTrip(t *testing.T) {
	dir := t.TempDir()
	store := NewStore(dir)

	want := ObserverState{
		LastRun:   time.Now().Truncate(time.Second),
		LastValue: "42",
	}

	if err := store.SaveObserver("test", want); err != nil {
		t.Fatal(err)
	}

	got, err := store.LoadObserver("test")
	if err != nil {
		t.Fatal(err)
	}

	if !got.LastRun.Equal(want.LastRun) || got.LastValue != want.LastValue {
		t.Errorf("got %+v, want %+v", got, want)
	}
}

func TestLoadObserverMissing(t *testing.T) {
	store := NewStore(t.TempDir())
	st, err := store.LoadObserver("nonexistent")
	if err != nil {
		t.Fatal(err)
	}
	if !st.LastRun.IsZero() || st.LastValue != "" {
		t.Errorf("expected zero state, got %+v", st)
	}
}

func TestHistoryAppendAndLoad(t *testing.T) {
	store := NewStore(t.TempDir())

	for i := range 5 {
		rec := RunRecord{
			Timestamp: time.Now(),
			Target:    "test",
			Result:    "success",
			Reason:    "reason",
			CostUSD:   float64(i) * 0.1,
		}
		if err := store.AppendHistory(rec); err != nil {
			t.Fatal(err)
		}
	}

	records, err := store.LoadHistory(0)
	if err != nil {
		t.Fatal(err)
	}
	if len(records) != 5 {
		t.Errorf("got %d records, want 5", len(records))
	}

	records, err = store.LoadHistory(3)
	if err != nil {
		t.Fatal(err)
	}
	if len(records) != 3 {
		t.Errorf("got %d records, want 3 (last 3)", len(records))
	}
}
