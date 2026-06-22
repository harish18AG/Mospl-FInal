#!/usr/bin/env python
"""
run_load_test.py - Runs the full Load/Performance test suite.
Generates the customized Excel performance report.
Usage: python run_load_test.py
"""
import subprocess
import sys
import os

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(current_dir)
    print("=" * 65)
    print("  [START] Starting MOSPL Selenium & Appium E2E Load Test Suite")
    print("  [COUNT] Target: 600+ Performance Test Cases")
    print("  [URL]   Web Endpoint: https://harish18ag.github.io/Mospl-FInal/")
    print("=" * 65)
    print()

    # Invoke pytest on test_load.py
    result = subprocess.run(
        [sys.executable, "-m", "pytest", "test_load.py", "-v", "--tb=short"],
        cwd=current_dir
    )

    sys.exit(result.returncode)
