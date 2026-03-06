// Package budget tracks API spend.
// It records daily and monthly costs without enforcing limits.
package budget

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"
)

// Record is the persisted budget state, reset automatically on date/month rollover.
type Record struct {
	Date     string  `json:"date"`  // YYYY-MM-DD
	Month    string  `json:"month"` // YYYY-MM
	DayUSD   float64 `json:"day_usd"`
	MonthUSD float64 `json:"month_usd"`
}

// Manager tracks spend, persisting state to a JSON file.
type Manager struct {
	path string
}

// NewManager creates a Manager that persists budget state in stateDir/budget.json.
func NewManager(stateDir string) *Manager {
	return &Manager{
		path: filepath.Join(stateDir, "budget.json"),
	}
}

func (m *Manager) load() (Record, error) {
	var rec Record
	data, err := os.ReadFile(m.path)
	if err != nil {
		if os.IsNotExist(err) {
			return rec, nil
		}
		return rec, err
	}
	err = json.Unmarshal(data, &rec)
	return rec, err
}

func (m *Manager) save(rec Record) error {
	data, err := json.Marshal(rec)
	if err != nil {
		return err
	}
	return os.WriteFile(m.path, data, 0o644)
}

func (m *Manager) current() (Record, error) {
	rec, err := m.load()
	if err != nil {
		return rec, err
	}
	today := time.Now().Format("2006-01-02")
	month := time.Now().Format("2006-01")

	if rec.Date != today {
		rec.DayUSD = 0
		rec.Date = today
	}
	if rec.Month != month {
		rec.MonthUSD = 0
		rec.Month = month
	}
	return rec, nil
}

// Spend records a cost.
func (m *Manager) Spend(usd float64) error {
	rec, err := m.current()
	if err != nil {
		return err
	}
	rec.DayUSD += usd
	rec.MonthUSD += usd
	return m.save(rec)
}

// Status returns the current budget usage.
func (m *Manager) Status() (dayUsed, monthUsed float64, err error) {
	rec, err := m.current()
	if err != nil {
		return 0, 0, err
	}
	return rec.DayUSD, rec.MonthUSD, nil
}
