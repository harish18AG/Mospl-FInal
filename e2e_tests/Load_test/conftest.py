"""
conftest.py - Pytest configuration for Load_test directory.
Handles report generation hook and disables the parent conftest E2E report generator.
"""
import sys
import os
import pytest

@pytest.hookimpl(hookwrapper=True)
def pytest_sessionfinish(session, exitstatus):
    """Disable parent conftest report and generate load test report using hookwrapper."""
    # 1. Clear parent conftest test results in-place BEFORE any regular hooks run.
    pm = session.config.pluginmanager
    for plugin in pm.get_plugins():
        if hasattr(plugin, "test_results"):
            test_res = getattr(plugin, "test_results")
            if isinstance(test_res, list):
                test_res.clear()

    # 2. Yield control to let the regular hooks run (they will skip because test_results is empty)
    yield

    # 3. Generate our load test report
    try:
        from test_load import load_results
        if load_results:
            sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
            from load_report_generator import generate_load_test_report
            generate_load_test_report(load_results)
    except Exception as e:
        print(f"[LOAD CONFTEST] Error generating report: {e}")
