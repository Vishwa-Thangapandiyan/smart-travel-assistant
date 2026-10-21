"""Opening the app and moving between its tabs."""


def test_app_opens_on_trips_with_the_demo_trip(app):
    app.wait_for("NEXT TRIP")
    assert app.is_showing("Bangalore")
    assert app.is_showing("FRI 20 – MON 23 NOV · 4 DAYS")


def test_every_tab_opens_its_screen_and_sos_is_always_there(app):
    # What each tab shows that no other tab does.
    marks = {
        "Map": "© OpenStreetMap contributors",
        "Budget": "TRIP BALANCE",
        "Explore": "Worth a look in",
        "Trips": "NEXT TRIP",
    }
    for tab, mark in marks.items():
        app.tap(tab)
        app.wait_for(mark)
        assert app.is_showing("Emergency help"), f"SOS missing on the {tab} tab"


def test_account_sheet_says_it_is_demo_mode(app):
    app.tap("Account")
    app.wait_for("Signed in as")
    app.scroll_to("Demo mode")
    assert app.is_showing("Demo mode: no account")
