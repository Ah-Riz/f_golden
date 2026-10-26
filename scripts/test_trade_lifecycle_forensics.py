#!/usr/bin/env python3
"""Unit tests for frozen early-stop / classification defs."""

from __future__ import annotations

import unittest

from trade_lifecycle_forensics import (
    EARLY_BARS,
    EARLY_HOLD_SEC,
    EARLY_MAE_R,
    analyze_trade,
    classify_exit,
    failure_label,
)


class TestForensicsDefs(unittest.TestCase):
    def test_classify_sl_trail_vs_initial(self):
        self.assertEqual(classify_exit("sl", 10.0), "sl_trail")
        self.assertEqual(classify_exit("sl", -10.0), "sl_initial_loss")
        self.assertEqual(classify_exit("tp", 10.0), "tp")

    def test_early_by_hold(self):
        row = {
            "trade_id": "1",
            "set_name": "t",
            "side": "buy",
            "entry_time": "2026.01.05 01:00:00",
            "exit_time": "2026.01.05 01:05:00",
            "entry_price": "100",
            "exit_price": "99",
            "entry_sl": "98",
            "entry_tp": "105",
            "exit_reason": "sl",
            "net": "-1",
            "hold_seconds": str(EARLY_HOLD_SEC - 1),
            "hold_bars_m5": "10",
        }
        out = analyze_trade(row, [])
        self.assertEqual(out["early_stop"], "1")

    def test_early_by_mae_bars(self):
        # risk=2; exit 1.5 below entry ⇒ mae_r=0.75 >= 0.7; hold_bars=2
        row = {
            "trade_id": "2",
            "set_name": "t",
            "side": "buy",
            "entry_time": "2026.01.05 01:00:00",
            "exit_time": "2026.01.05 01:20:00",
            "entry_price": "100",
            "exit_price": "98.5",
            "entry_sl": "98",
            "entry_tp": "105",
            "exit_reason": "sl",
            "net": "-1",
            "hold_seconds": str(EARLY_HOLD_SEC + 100),
            "hold_bars_m5": str(EARLY_BARS - 1),
        }
        out = analyze_trade(row, [])
        self.assertGreaterEqual(float(out["mae_r"]), EARLY_MAE_R)
        self.assertEqual(out["early_stop"], "1")

    def test_failure_label_flat_near_sl(self):
        self.assertEqual(
            failure_label("other", False, None, True),
            "flat_near_sl_suspect",
        )


if __name__ == "__main__":
    unittest.main()
