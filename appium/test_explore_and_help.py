"""Explore's suggestions, the Map tab, and the SOS help screen."""


def test_explore_lists_places_highest_rated_first(app):
    app.tap("Explore")

    app.wait_for("13 PLACES")
    assert app.is_showing("HIGHEST RATED FIRST")
    assert app.is_showing("Cubbon Park")


def test_a_category_filter_narrows_the_list(app):
    app.tap("Explore")
    app.wait_for("13 PLACES")
    app.tap("Museums")

    app.wait_until_gone("13 PLACES")
    assert app.is_showing("National Gallery of Modern Art")
    assert not app.is_showing("Cubbon Park")


def test_map_shows_the_first_stop_of_day_1(app):
    app.tap("Map")

    app.wait_for("STOP 1 OF 2 · DAY 1")
    assert app.is_showing("Vidhana Soudha")
    assert app.is_showing("Navigate")


def test_sos_lists_helplines_and_closes(app):
    app.tap("Emergency help")

    app.wait_for("Call emergency 112")
    assert app.is_showing("Call Police 100")
    assert app.is_showing("Call Ambulance 108")
    assert app.is_showing("Call Fire 101")

    app.tap("Close")
    app.wait_until_gone("Call emergency 112")
