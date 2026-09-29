#!/usr/bin/env python3
"""Report per-file line coverage from Flutter's lcov.info output.

Usage: python3 tool/coverage_report.py [threshold]
Exits non-zero if any file under lib/ falls below the threshold.
"""

import sys
from collections import OrderedDict

LCOV = "coverage/lcov.info"
THRESHOLD = float(sys.argv[1]) if len(sys.argv) > 1 else 80.0
# Files that must clear the gate (data source + view models + models).
GATED = ("lib/services/", "lib/viewmodels/", "lib/models/")


def parse(path):
    files = OrderedDict()
    current = None
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if line.startswith("SF:"):
                current = line[3:]
                files[current] = {"found": 0, "hit": 0}
            elif current and line.startswith("DA:"):
                # DA:<line number>,<hit count>
                _, _, count = line[3:].partition(",")
                files[current]["found"] += 1
                if int(count) > 0:
                    files[current]["hit"] += 1
    return files


def main():
    files = parse(LCOV)
    failures = []
    print(f"{'File':<58}{'Hit':>6}{'Found':>7}{'Coverage':>10}")
    print("-" * 81)
    for name, stats in files.items():
        rel = name.split("country_trivia/", 1)[-1]
        if not rel.startswith("lib/"):
            continue
        found, hit = stats["found"], stats["hit"]
        pct = (hit / found * 100) if found else 100.0
        gated = any(rel.startswith(g) for g in GATED)
        marker = " *" if gated else ""
        print(f"{rel + marker:<58}{hit:>6}{found:>7}{pct:>9.1f}%")
        if gated and pct < THRESHOLD:
            failures.append((rel, pct))

    print("-" * 81)
    print("  * = gated (must meet threshold)")
    print(f"\nThreshold: {THRESHOLD:.0f}%")
    if failures:
        print("\nFAIL — below threshold:")
        for rel, pct in failures:
            print(f"  {rel}: {pct:.1f}%")
        return 1
    print("\nPASS — all gated files meet the threshold.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
