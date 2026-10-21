"""Small helpers the tests use to find and tap things in Meridian.

Flutter hands every label to Android as the element's accessibility text
(content-desc), so the tests find things by what the screen says, the same
way a person reading it would: "New trip", "Log an expense", "Save stop".
Text fields are the exception: they are found by their hint, the grey label
inside the empty field.
"""

import time

from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support import expected_conditions as wait_until
from selenium.webdriver.support.ui import WebDriverWait

INTRO = "Meridian, smart travel assistant. Tap to skip."


def _quote(text):
    return text.replace("\\", "\\\\").replace('"', '\\"')


def _containing(part):
    return f'new UiSelector().descriptionContains("{_quote(part)}")'


class App:
    def __init__(self, driver, timeout=10):
        self.driver = driver
        self.timeout = timeout

    # ---- finding ----

    def find(self, label):
        """The element whose whole label is exactly `label`, once it shows."""
        return self._wait((AppiumBy.ACCESSIBILITY_ID, label))

    def find_starting(self, start):
        """The element whose label starts with `start`. Cards and rows join
        several lines into one label, e.g. "Vidhana Soudha\\n16:00"."""
        selector = f'new UiSelector().descriptionStartsWith("{_quote(start)}")'
        return self._wait((AppiumBy.ANDROID_UIAUTOMATOR, selector))

    def field(self, hint):
        """The text field showing `hint` while it is empty."""
        return self._wait((AppiumBy.XPATH, f'//android.widget.EditText[@hint="{hint}"]'))

    def wait_for(self, part):
        """Waits until something on screen has `part` anywhere in its label."""
        return self._wait((AppiumBy.ANDROID_UIAUTOMATOR, _containing(part)))

    def is_showing(self, part):
        """True if something on screen has `part` anywhere in its label. Doesn't wait."""
        return len(self.driver.find_elements(AppiumBy.ANDROID_UIAUTOMATOR, _containing(part))) > 0

    def wait_until_gone(self, part):
        WebDriverWait(self.driver, self.timeout).until(
            wait_until.invisibility_of_element_located((AppiumBy.ANDROID_UIAUTOMATOR, _containing(part))),
            message=f"{part!r} is still on screen",
        )

    def scroll_to(self, part):
        """Scrolls the screen's list until something with `part` in its label is on screen."""
        selector = (
            "new UiScrollable(new UiSelector().scrollable(true))"
            f'.scrollIntoView(new UiSelector().descriptionContains("{_quote(part)}"))'
        )
        self.driver.find_element(AppiumBy.ANDROID_UIAUTOMATOR, selector)
        # Flutter's list keeps gliding for a moment after the scroll; a tap
        # sent before it stops lands on the wrong spot. Wait until it is still.
        element = self.wait_for(part)
        WebDriverWait(self.driver, self.timeout, poll_frequency=0.3).until(
            lambda _: self._stays_put(part), message=f"{part!r} kept moving"
        )
        return element

    # ---- doing ----

    def tap(self, label):
        self.find(label).click()

    def tap_starting(self, start):
        self.find_starting(start).click()

    def type_into(self, hint, text):
        # The keyboard is left open: hiding it presses Back on some phones,
        # which closes a dialog such as the expense form.
        box = self.field(hint)
        box.click()
        box.send_keys(text)

    def skip_intro(self):
        """Taps the intro away if it is still playing when the test starts."""
        try:
            self.driver.find_element(AppiumBy.ACCESSIBILITY_ID, INTRO).click()
        except NoSuchElementException:
            pass

    def pick_date(self, field, day):
        """Opens the date field and picks `day` of the month showing, e.g. 25."""
        self.tap_starting(field)
        self.tap_starting(f"{day}, ")
        self.tap("OK")

    def _stays_put(self, part):
        before = self.wait_for(part).rect
        time.sleep(0.3)
        return self.wait_for(part).rect == before

    def _wait(self, locator):
        return WebDriverWait(self.driver, self.timeout).until(
            wait_until.presence_of_element_located(locator),
            message=f"Nothing on screen matched {locator[1]!r}",
        )
