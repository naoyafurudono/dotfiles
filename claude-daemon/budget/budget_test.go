package budget

import (
	"testing"
)

func TestSpendAndStatus(t *testing.T) {
	mgr := NewManager(t.TempDir())

	mgr.Spend(1.5)

	dayUsed, monthUsed, err := mgr.Status()
	if err != nil {
		t.Fatal(err)
	}
	if dayUsed != 1.5 || monthUsed != 1.5 {
		t.Errorf("unexpected status: day=%.2f month=%.2f", dayUsed, monthUsed)
	}
}
