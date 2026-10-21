"""Shared setup for the Appium UI tests.

One Appium session drives the phone for the whole run. Before each test the
app is closed and opened again: the fake-data build keeps trips, stops and
expenses in memory, so a restart puts the demo Bangalore trip back exactly
as it was, and no test can see what the one before it changed.

The app's stored data is never cleared, so running the tests doesn't wipe
anything on the phone (and some phones, Oppo's for one, refuse to let Appium
clear it anyway).
"""

import os

import pytest
from appium import webdriver
from appium.options.android import UiAutomator2Options

from screens import App

PACKAGE = "dev.meridian.smart_travel_assistant"
SERVER = os.environ.get("APPIUM_SERVER", "http://127.0.0.1:4723")


@pytest.fixture(scope="session")
def driver():
    options = UiAutomator2Options()
    options.app_package = PACKAGE
    options.app_activity = ".MainActivity"
    options.no_reset = True
    options.auto_grant_permissions = True
    options.new_command_timeout = 300
    # Slow phones and on-screen install checks need more than the default.
    options.set_capability("appium:uiautomator2ServerInstallTimeout", 180000)
    options.set_capability("appium:adbExecTimeout", 180000)
    session = webdriver.Remote(SERVER, options=options)
    yield session
    session.quit()


@pytest.fixture
def app(driver):
    driver.terminate_app(PACKAGE)
    driver.activate_app(PACKAGE)
    screen = App(driver)
    screen.skip_intro()
    screen.find("New trip")  # the Trips tab is showing
    return screen


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Saves a screenshot of the phone when a test fails, into appium/failures/."""
    outcome = yield
    report = outcome.get_result()
    driver = item.funcargs.get("driver")
    if report.when == "call" and report.failed and driver is not None:
        folder = os.path.join(os.path.dirname(__file__), "failures")
        os.makedirs(folder, exist_ok=True)
        driver.get_screenshot_as_file(os.path.join(folder, f"{item.name}.png"))
