"""A day's stops on the demo Bangalore trip: add, check, edit, delete."""


def open_bangalore_day_1(app):
    app.tap_starting("NEXT TRIP")
    app.wait_for("DAY 1 · 2 STOPS")


def test_day_1_shows_its_stops_in_order(app):
    open_bangalore_day_1(app)

    assert app.is_showing("Vidhana Soudha\n16:00")
    assert app.is_showing("Vidyarthi Bhavan")


def test_a_stop_needs_a_name(app):
    open_bangalore_day_1(app)
    app.tap("Add a stop")
    app.tap("Save stop")

    app.wait_for("Give the stop a name.")


def test_a_new_stop_is_added_to_the_day(app):
    open_bangalore_day_1(app)
    app.tap("Add a stop")
    app.type_into("Stop name", "Coffee at Third Wave")
    app.type_into("Notes (optional)", "Try the cold brew")
    app.tap("Save stop")

    app.wait_for("DAY 1 · 3 STOPS")
    assert app.is_showing("Coffee at Third Wave")


def test_another_day_has_its_own_stops(app):
    open_bangalore_day_1(app)
    app.tap("Sat 21")

    app.wait_for("DAY 2")
    assert not app.is_showing("Vidhana Soudha")


def test_a_stop_can_be_deleted(app):
    open_bangalore_day_1(app)
    app.tap_starting("Vidyarthi Bhavan")
    app.wait_for("Edit stop")
    app.tap("Delete stop")
    app.tap("Delete")

    app.wait_for("DAY 1 · 1 STOP")
    assert not app.is_showing("Vidyarthi Bhavan")
