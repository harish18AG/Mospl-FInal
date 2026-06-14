"""
conftest.py - Pytest configuration for Mospl Appium Mobile E2E Tests
Manages Appium driver lifecycle and collects results for Excel reporting.
"""
import pytest
import datetime
import time
import os
import sys

from appium import webdriver as appium_webdriver
from appium.options.android import UiAutomator2Options

# Global container to collect all test results across the session
test_results = []

# ── App Configuration ─────────────────────────────────────────────────────────
# App package and activity from AndroidManifest.xml
APP_PACKAGE = "com.mospl.mospl"
APP_ACTIVITY = ".MainActivity"
APPIUM_SERVER = "http://127.0.0.1:4723"

# Login credentials
EMAIL = "harishanbazhagan2005@gmail.com"
PASSWORD = "harbha@123"


def pytest_configure(config):
    """Register custom markers."""
    config.addinivalue_line("markers", "ui: mark test as UI/UX test")
    config.addinivalue_line("markers", "functional: mark test as functional test")
    config.addinivalue_line("markers", "validation: mark test as validation test")
    config.addinivalue_line("markers", "unit: mark test as unit test")
    config.addinivalue_line("markers", "deployment: mark test as deployment/status test")
    config.addinivalue_line("markers", "navigation: mark test as navigation test")
    config.addinivalue_line("markers", "performance: mark test as performance test")


@pytest.fixture(scope="session")
def driver():
    """Session-scoped Appium driver fixture - connects to the running Appium server."""
    options = UiAutomator2Options()
    options.platform_name = "Android"
    options.automation_name = "UiAutomator2"
    options.app_package = APP_PACKAGE
    options.app_activity = APP_ACTIVITY
    options.no_reset = True
    options.full_reset = False
    options.new_command_timeout = 300
    options.auto_grant_permissions = True

    # If you have a specific device, set it here:
    # options.udid = "emulator-5554"
    # If you want to use an APK file directly:
    # options.app = r"C:\path\to\mospl.apk"

    print(f"\n[APPIUM] Connecting to Appium server at {APPIUM_SERVER}...")
    print(f"[APPIUM] Target: {APP_PACKAGE}/{APP_ACTIVITY}")

    drv = appium_webdriver.Remote(APPIUM_SERVER, options=options)
    drv.implicitly_wait(15)
    time.sleep(5)  # Let Flutter app fully load
    yield drv
    drv.quit()


@pytest.fixture(scope="function")
def wait(driver):
    """Explicit wait instance."""
    from selenium.webdriver.support.ui import WebDriverWait
    return WebDriverWait(driver, 20)


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Hook to capture test result after each test runs."""
    outcome = yield
    report = outcome.get_result()

    if report.when == "call":
        duration = round(report.duration, 3)
        status = "PASS" if report.passed else ("FAIL" if report.failed else "SKIP")
        error_details = ""
        if report.failed and report.longreprtext:
            error_details = str(report.longreprtext)[-300:]

        # Determine category from markers
        markers = [m.name for m in item.iter_markers()]
        if "ui" in markers:
            category = "UI/UX"
        elif "functional" in markers:
            category = "Functional"
        elif "validation" in markers:
            category = "Validation"
        elif "unit" in markers:
            category = "Unit"
        elif "deployment" in markers:
            category = "Deployment"
        elif "navigation" in markers:
            category = "Navigation"
        elif "performance" in markers:
            category = "Performance"
        else:
            category = "General"

        test_results.append({
            "Test ID": f"MA-{len(test_results) + 1:03d}",
            "Category": category,
            "Test Name": item.name,
            "Description": item.function.__doc__ or item.name,
            "Status": status,
            "Duration (s)": duration,
            "Error Details": error_details,
            "Timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        })


def pytest_sessionfinish(session, exitstatus):
    """Called after the entire test session is done - generate Excel report."""
    if test_results:
        # Add parent utils directory to path
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
        from utils.appium_report_generator import generate_appium_excel_report
        generate_appium_excel_report(test_results)
