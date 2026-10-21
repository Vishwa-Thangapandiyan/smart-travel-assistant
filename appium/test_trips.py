"""Creating a trip: the form's checks, then a trip that saves."""


def test_empty_new_trip_form_says_what_is_missing(app):
    app.tap("New trip")
    app.tap("Create trip")

    app.wait_for("Enter where you are going.")
    assert app.is_showing("Pick the day you leave.")
    assert app.is_showing("Pick the day you come back.")


def test_coming_back_before_leaving_is_caught(app):
    app.tap("New trip")
    app.type_into("Where are you going?", "Goa")
    app.pick_date("Leave on", 12)
    app.pick_date("Come back on", 10)
    app.tap("Create trip")

    app.wait_for("The trip can't end before it starts.")


def test_a_new_trip_saves_and_opens_on_day_1(app):
    app.tap("New trip")
    app.type_into("Where are you going?", "Goa")
    app.pick_date("Leave on", 10)
    app.pick_date("Come back on", 12)
    app.tap("Create trip")

    # The new trip opens straight away, on its first day, with nothing in it.
    app.wait_for("DAY 1 · 0 STOPS")
    assert app.is_showing("Goa")
    assert app.is_showing("Add a stop")

    # Back on Trips, the new trip is listed.
    app.tap("Back")
    app.find("New trip")
    assert app.is_showing("Goa")
