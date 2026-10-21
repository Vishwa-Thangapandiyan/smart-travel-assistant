"""The Budget tab on the demo trip: ₹15,000 budget, ₹11,060 spent."""


def open_expense_form(app):
    app.tap("Budget")
    app.wait_for("TRIP BALANCE")
    app.scroll_to("Log an expense")
    app.tap("Log an expense")
    app.wait_for("Save expense")


def test_balance_shows_what_is_left_and_spent(app):
    app.tap("Budget")

    app.wait_for("₹3,940")
    assert app.is_showing("left of ₹15,000")
    assert app.is_showing("₹11,060 spent")


def test_an_expense_needs_a_positive_amount(app):
    open_expense_form(app)
    app.type_into("Amount", "-50")
    app.tap("Save expense")

    app.wait_for("Enter a positive amount")


def test_a_logged_expense_comes_off_the_balance(app):
    open_expense_form(app)
    app.type_into("Amount", "440")
    app.type_into("Description (optional)", "Auto to Lalbagh")
    app.tap("Save expense")

    # ₹3,940 left, less ₹440.
    app.wait_until_gone("Save expense")
    app.scroll_to("TRIP BALANCE")
    app.wait_for("₹3,500")
    assert app.is_showing("₹11,500 spent")
