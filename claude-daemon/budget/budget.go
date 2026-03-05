// Package budget tracks API spend against daily and monthly limits.
// It prevents the daemon from exceeding cost thresholds by checking
// remaining budget before each executor run. Spend is recorded after
// each successful execution.
package budget

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"
)

// Config defines the spending limits.
type Config struct {
	DailyUSD   float64
	MonthlyUSD float64
	PerRunUSD  float64
}

// Record is the persisted budget state, reset automatically on date/month rollover.
type Record struct {
	Date     string  `json:"date"`  // YYYY-MM-DD
	Month    string  `json:"month"` // YYYY-MM
	DayUSD   float64 `json:"day_usd"`
	MonthUSD float64 `json:"month_usd"`
}

// Manager tracks spend against limits, persisting state to a JSON file.
type Manager struct {
	config Config
	path   string
}

// NewManager creates a Manager that persists budget state in stateDir/budget.json.
func NewManager(config Config, stateDir string) *Manager {
	return &Manager{
		config: config,
		path:   filepath.Join(stateDir, "budget.json"),
	}
}

// Config returns the spending limits.
func (m *Manager) Config() Config {
	return m.config
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

// CanSpend returns true if there is budget remaining for a run.
func (m *Manager) CanSpend() (bool, string) {
	rec, err := m.current()
	if err != nil {
		return false, "budget state error: " + err.Error()
	}

	if rec.DayUSD >= m.config.DailyUSD {
		return false, "daily budget exhausted"
	}
	if rec.MonthUSD >= m.config.MonthlyUSD {
		return false, "monthly budget exhausted"
	}
	return true, ""
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
func (m *Manager) Status() (dayUsed, dayLimit, monthUsed, monthLimit float64, err error) {
	rec, err := m.current()
	if err != nil {
		return 0, 0, 0, 0, err
	}
	return rec.DayUSD, m.config.DailyUSD, rec.MonthUSD, m.config.MonthlyUSD, nil
}
