#!/usr/bin/env python
"""
run_appium_tests.py - Runs the Appium mobile test suite for MOSPL Android app.
Prerequisites:
  1. Appium server running: appium --port 4723
  2. Android device/emulator connected: adb devices
  3. MOSPL app installed on device: com.mospl.mospl
Usage: python run_appium_tests.py
"""
import subprocess
import sys
import os

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    print("=" * 65)
    print("  [START] MOSPL Appium Mobile E2E Test Suite")
    print("  [APP]   Package: com.mospl.mospl")
    print("  [SERVER] Appium: http://127.0.0.1:4723")
    print("=" * 65)
    print()
    print("  Prerequisites:")
    print("    1. Appium server running (appium --port 4723)")
    print("    2. Android device/emulator connected (adb devices)")
    print("    3. MOSPL app installed on device")
    print()

    result = subprocess.run(
        [sys.executable, "-m", "pytest", ".", "-v", "--tb=short"],
        cwd=os.path.dirname(os.path.abspath(__file__))
    )

    sys.exit(result.returncode)
