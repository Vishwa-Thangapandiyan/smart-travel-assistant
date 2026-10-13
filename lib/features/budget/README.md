# Budget & expenses — REQ-3.1–3.5

Owner: Santhosh · Branch: `flex/budget` · SRS 4.3 · Record:
[`docs/OWNERSHIP.md`](../../../docs/OWNERSHIP.md)

**Start after** Vishwa's app shell and theme are merged (`flex/app-shell`).

Set a per-category budget for a trip, log expenses, see what's left, and
get a warning at 90% of a category. Budget and itinerary are entirely
separate: a stop has no price, and nothing here reads or writes itinerary
items. Trips come from `lib/services/trip_service.dart` — use its fake
trip until the real one merges.

## Tasks

1. Budget setup screen: allocate an amount per category for a trip,
   writing `Budget` rows.
2. Expense form: category, amount, date, description, writing `Expense`
   rows.
3. A `BudgetProvider` (`ChangeNotifier`) that fetches a trip's expenses
   and exposes totals per category. **Never store a running "spent" total**
   in a field or column — it goes wrong the moment an expense is edited or
   deleted. Recalculate on read:
   ```sql
   select category, sum(amount) as spent
   from expenses
   where trip_id = $1
   group by category;
   ```
4. The 90% alert: two `if` statements on data you already fetched — a
   banner on the open screen, not a notification service.
5. Guard the percentage against divide-by-zero when a category's
   allocation is zero.

## Done when

- [ ] A budget can be set per category for a trip — REQ-3.1
- [ ] Expenses can be logged with category, amount, date, description —
      REQ-3.2, REQ-3.3
- [ ] Balances are computed live from `expenses`, never a stored total —
      REQ-3.4
- [ ] A 90% alert shows per category, with no divide-by-zero on an empty
      allocation — REQ-3.5
