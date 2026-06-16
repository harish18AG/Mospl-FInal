"""
conftest.py - Pytest configuration for Mospl Selenium E2E Tests
Manages WebDriver lifecycle and collects results for Excel reporting.
"""
import os
import pytest
import datetime
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait

# Global container to collect all test results across the session
test_results = []

BASE_URL = "https://harish18ag.github.io/Mospl-FInal/#/signin"
EMAIL = "harishanbazhagan2005@gmail.com"
PASSWORD = "harbha@123"


def pytest_configure(config):
    """Register custom markers."""
    config.addinivalue_line("markers", "ui: mark test as UI/UX test")
    config.addinivalue_line("markers", "functional: mark test as functional test")
    config.addinivalue_line("markers", "validation: mark test as validation test")
    config.addinivalue_line("markers", "unit: mark test as unit test")
    config.addinivalue_line("markers", "deployment: mark test as deployment/status test")


@pytest.fixture(scope="session")
def driver():
    """Session-scoped WebDriver fixture - starts Chrome once for the whole test session."""
    options = ChromeOptions()
    options.add_argument("--start-maximized")
    options.add_argument("--disable-notifications")
    options.add_argument("--disable-popup-blocking")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-infobars")
    options.add_argument("--enable-accessibility")
    # Auto-enable headless when running in CI (GitHub Actions sets CI=true)
    if os.environ.get("CI"):
        options.add_argument("--headless=new")
        options.add_argument("--window-size=1920,1080")

    drv = webdriver.Chrome(options=options)
    drv.implicitly_wait(10)

    # Set window to 1920x1080 before any page load so Flutter renders at the
    # correct desktop width. Fixes TC014 (window.innerWidth >= 1024 assertion).
    # Using set_window_size() instead of --window-size Chrome arg avoids
    # Chrome stability issues on Windows.
    drv.set_window_size(1920, 1080)

    # Flutter Web cold-start fix: load the root URL first so the Flutter engine
    # bootstraps and caches all JS assets. Then load the signin deep-link.
    # Using driver.get() (not JS hash nav) ensures Flutter fully re-initialises
    # its render tree (flt-glass-pane, canvas, semantics) on each navigation.
    drv.get("https://harish18ag.github.io/Mospl-FInal/")
    time.sleep(5)   # Allow Flutter JS bundle to download and bootstrap

    drv.get("https://harish18ag.github.io/Mospl-FInal/#/signin")
    time.sleep(3)   # Let Flutter router render the signin page

    yield drv
    drv.quit()






@pytest.fixture(scope="function")
def wait(driver):
    """WebDriverWait instance for explicit waits."""
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
        else:
            category = "General"

        test_results.append({
            "Test ID": f"TC-{len(test_results) + 1:03d}",
            "Category": category,
            "Test Name": item.name,
            "Description": item.function.__doc__ or item.name,
            "Status": status,
            "Duration (s)": duration,
            "Error Details": error_details,
            "Timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        })


def pytest_sessionfinish(session, exitstatus):
    """Called after the entire test session is done — generate Excel report."""
    if test_results:
        from utils.report_generator import generate_excel_report
        generate_excel_report(test_results)
