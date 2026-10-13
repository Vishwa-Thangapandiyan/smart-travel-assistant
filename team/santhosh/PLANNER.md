# Santhosh's Planner

The answer when the instructor asks where the project stands. Tick items
in the same PR that finishes them. Spec: `lib/features/budget/README.md`.

Dates were re-planned on 14 Oct 2026. Team-wide phases are in
`README.md` §9.

## Before you start (any time before 20 Oct)

- [ ] Flutter, Git and an Android emulator or phone working
      (`START-HERE.md` §1)
- [ ] GitHub username sent to Vishwa for collaborator access
- [ ] Codex set up, with `commit_attribution = ""` in
      `~/.codex/config.toml` (see your README)
- [ ] Repo cloned; app runs in fake data mode once the app shell is merged
      (`RUN.md`)

## Phase B — from the app shell merge to 1 Nov: Budget

- [ ] Budget setup screen: amount per category for a trip
- [ ] Expense form: category, amount, date, description
- [ ] `BudgetProvider` with totals recalculated on read, never stored
- [ ] 90% alert per category, no divide-by-zero on an empty allocation
- [ ] `flex/budget` merged

## Phase C — 2 Nov – 8 Nov: integration and testing

- [ ] Works against a real trip from Vishwa's `trip_service`
- [ ] Tested: editing and deleting an expense updates the totals

## Phase D — 9 Nov – 20 Nov: release and viva

- [ ] User guide and final report section for Budget
- [ ] Viva prep: why totals are recalculated rather than stored, and why
      budget and itinerary are separate

## Blockers

| Date | Blocker | Status |
| --- | --- | --- |
| | | |
