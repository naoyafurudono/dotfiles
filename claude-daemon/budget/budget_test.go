package budget

import (
	"testing"
)

func TestCanSpend(t *testing.T) {
	mgr := NewManager(Config{DailyUSD: 3.0, MonthlyUSD: 30.0, PerRunUSD: 1.0}, t.TempDir())

	ok, _ := mgr.CanSpend()
	if !ok {
		t.Error("should be able to spend initially")
	}

	mgr.Spend(3.0)

	ok, reason := mgr.CanSpend()
	if ok {
		t.Error("should not be able to spend after daily limit")
	}
	if reason != "daily budget exhausted" {
		t.Errorf("unexpected reason: %s", reason)
	}
}

func TestStatus(t *testing.T) {
	mgr := NewManager(Config{DailyUSD: 3.0, MonthlyUSD: 30.0, PerRunUSD: 1.0}, t.TempDir())

	mgr.Spend(1.5)

	dayUsed, dayLimit, monthUsed, monthLimit, err := mgr.Status()
	if err != nil {
		t.Fatal(err)
	}
	if dayUsed != 1.5 || dayLimit != 3.0 || monthUsed != 1.5 || monthLimit != 30.0 {
		t.Errorf("unexpected status: day=%.2f/%.2f month=%.2f/%.2f",
			dayUsed, dayLimit, monthUsed, monthLimit)
	}
}
