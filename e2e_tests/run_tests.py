#!/usr/bin/env python
"""
run_tests.py - Convenience runner script.
Runs the full Selenium test suite and generates the Excel report.
Usage: python run_tests.py
"""
import subprocess
import sys
import os

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    print("=" * 60)
    print("  [START] Starting Mospl E2E Selenium Test Suite")
    print("  [URL]   Target: https://harish18ag.github.io/Mospl-FInal/")
    print("=" * 60)

    result = subprocess.run(
        [sys.executable, "-m", "pytest", "web_selenium/", "-v", "--tb=short"],
        cwd=os.path.dirname(os.path.abspath(__file__))
    )

    sys.exit(result.returncode)
