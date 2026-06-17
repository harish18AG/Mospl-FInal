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
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

# Global container to collect all test results across the session
test_results = []

# ── App Configuration ─────────────────────────────────────────────────────────
APP_PACKAGE = "com.mospl.mospl"
APP_ACTIVITY = ".MainActivity"
APPIUM_SERVER = "http://127.0.0.1:4723"

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


def _wait_for_flutter_ready(drv, max_wait=45):
    """
    Wait until Flutter has finished its splash and the UI is interactive.
    Flutter apps show a blank/logo-only screen during engine init; once ready
    they expose EditText fields (login) or navigation elements (home).
    Returns True if ready, False on timeout.
    """
    print("\n[APPIUM] Waiting for Flutter app to become ready...")
    deadline = time.time() + max_wait
    while time.time() < deadline:
        try:
            drv.implicitly_wait(1)
            # Check for EditText fields (login screen) OR nav labels (home screen)
            fields = drv.find_elements(AppiumBy.CLASS_NAME, "android.widget.EditText")
            if fields:
                print("[APPIUM] Login screen detected (EditText fields found).")
                drv.implicitly_wait(15)
                return True

            # Check for navigation bar items (app already logged in)
            views = drv.find_elements(
                AppiumBy.XPATH,
                '//*[@content-desc="Home" or @content-desc="Categories" '
                'or @content-desc="Cart" or @content-desc="Profile" '
                'or @content-desc="Wishlist"]'
            )
            if views:
                print("[APPIUM] Home screen detected (nav bar found).")
                drv.implicitly_wait(15)
                return True
        except Exception:
            pass
        finally:
            try:
                drv.implicitly_wait(15)
            except Exception:
                pass
        time.sleep(2)

    print(f"[APPIUM] WARNING: Flutter not ready after {max_wait}s — proceeding anyway.")
    return False


def _perform_login(drv):
    """Enter credentials on the login screen and tap Sign In. Returns True if login tapped."""
    try:
        drv.implicitly_wait(1)
        fields = drv.find_elements(AppiumBy.CLASS_NAME, "android.widget.EditText")
        drv.implicitly_wait(15)
        if len(fields) >= 2:
            # Clear and type email
            fields[0].click()
            time.sleep(0.4)
            fields[0].clear()
            time.sleep(0.3)
            fields[0].send_keys(EMAIL)
            time.sleep(0.4)
            # Close keyboard
            try:
                drv.hide_keyboard()
            except Exception:
                pass
            time.sleep(0.3)

            # Clear and type password
            fields[1].click()
            time.sleep(0.4)
            fields[1].clear()
            time.sleep(0.3)
            fields[1].send_keys(PASSWORD)
            time.sleep(0.4)
            try:
                drv.hide_keyboard()
            except Exception:
                pass
            time.sleep(0.3)

            # Tap Sign In button (content-desc in Flutter)
            try:
                drv.implicitly_wait(1)
                btns = drv.find_elements(
                    AppiumBy.XPATH,
                    '//*[@content-desc="Sign In" or @text="Sign In"]'
                )
                drv.implicitly_wait(15)
                if btns:
                    btns[0].click()
                    print("[APPIUM] Sign In tapped — waiting for home screen...")
                    time.sleep(9)
                    return True
            except Exception:
                drv.implicitly_wait(15)

            # Coordinate fallback: Sign In button is at approx y=1156 centre based on page_source
            try:
                size = drv.get_window_size()
                x = size["width"] // 2
                y = int(size["height"] * 0.50)
                drv.tap([(x, y)], 200)
                time.sleep(9)
                return True
            except Exception:
                pass
    except Exception as e:
        print(f"[APPIUM] Login attempt failed: {e}")
    return False


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
    options.udid = "emulator-5554"

    # Use XPath1 to avoid the XPath2 compiler warning that slows down element lookups
    options.set_capability("appium:settings[enforceXPath1]", True)

    print(f"\n[APPIUM] Connecting to Appium server at {APPIUM_SERVER}...")
    print(f"[APPIUM] Target: {APP_PACKAGE}/{APP_ACTIVITY}")

    drv = appium_webdriver.Remote(APPIUM_SERVER, options=options)
    drv.implicitly_wait(15)

    # Wait for Flutter to fully initialise past the splash screen
    _wait_for_flutter_ready(drv, max_wait=45)

    # Perform initial login if the login screen is showing
    try:
        drv.implicitly_wait(1)
        fields = drv.find_elements(AppiumBy.CLASS_NAME, "android.widget.EditText")
        drv.implicitly_wait(15)
        if fields:
            print("[APPIUM] Performing initial login...")
            _perform_login(drv)
            # Wait again for home screen to appear
            time.sleep(3)
            _wait_for_flutter_ready(drv, max_wait=20)
    except Exception as e:
        print(f"[APPIUM] Pre-login check failed: {e}")
        drv.implicitly_wait(15)

    print("[APPIUM] Driver ready — starting test session.\n")
    yield drv
    drv.quit()


@pytest.fixture(scope="function")
def wait(driver):
    """Explicit wait instance."""
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
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
        from utils.appium_report_generator import generate_appium_excel_report
        generate_appium_excel_report(test_results)
