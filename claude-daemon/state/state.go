// Package state provides persistent storage for claude-daemon.
// It manages two kinds of data:
//   - Observer state: per-observer checkpoint (last run time, last seen value)
//     so observers can detect incremental changes across daemon cycles.
//   - Run history: append-only JSONL log of every improvement cycle result,
//     used by safety checks (backoff, cooldown) and the status command.
//
// All data is stored as JSON files in a single directory.
package state

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"time"
)

// ObserverState is the checkpoint for a single observer, persisted between cycles.
type ObserverState struct {
	LastRun   time.Time `json:"last_run"`
	LastValue string    `json:"last_value"` // observer-specific (e.g. line count)
}

// RunRecord is a single entry in the improvement history log.
type RunRecord struct {
	Timestamp time.Time `json:"timestamp"`
	Target    string    `json:"target"`
	Reason    string    `json:"reason"`
	Result    string    `json:"result"` // "success", "failure", "skipped"
	Commit    string    `json:"commit,omitempty"`
	CostUSD   float64   `json:"cost_usd"`
	Error     string    `json:"error,omitempty"`
}

// Store manages reading and writing daemon state files.
type Store struct {
	dir string
}

// NewStore creates a Store backed by the given directory.
// The directory is created lazily on first write.
func NewStore(dir string) *Store {
	return &Store{dir: dir}
}

// Dir returns the directory path used by this store.
func (s *Store) Dir() string {
	return s.dir
}

func (s *Store) ensureDir() error {
	return os.MkdirAll(s.dir, 0o755)
}

// LoadObserver reads the checkpoint for the named observer.
// Returns a zero ObserverState if no checkpoint exists yet.
func (s *Store) LoadObserver(name string) (ObserverState, error) {
	var st ObserverState
	data, err := os.ReadFile(filepath.Join(s.dir, "observer-"+name+".json"))
	if err != nil {
		if os.IsNotExist(err) {
			return st, nil
		}
		return st, err
	}
	err = json.Unmarshal(data, &st)
	return st, err
}

// SaveObserver writes the checkpoint for the named observer.
func (s *Store) SaveObserver(name string, st ObserverState) error {
	if err := s.ensureDir(); err != nil {
		return err
	}
	data, err := json.Marshal(st)
	if err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(s.dir, "observer-"+name+".json"), data, 0o644)
}

// AppendHistory adds a record to the history log (history.jsonl).
func (s *Store) AppendHistory(rec RunRecord) error {
	if err := s.ensureDir(); err != nil {
		return err
	}
	f, err := os.OpenFile(filepath.Join(s.dir, "history.jsonl"), os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()
	return json.NewEncoder(f).Encode(rec)
}

// LoadHistory reads the last N records from the history log.
// If limit is 0, all records are returned.
func (s *Store) LoadHistory(limit int) ([]RunRecord, error) {
	data, err := os.ReadFile(filepath.Join(s.dir, "history.jsonl"))
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}
	var records []RunRecord
	dec := json.NewDecoder(bytes.NewReader(data))
	for dec.More() {
		var rec RunRecord
		if err := dec.Decode(&rec); err != nil {
			continue
		}
		records = append(records, rec)
	}
	if limit > 0 && len(records) > limit {
		records = records[len(records)-limit:]
	}
	return records, nil
}
