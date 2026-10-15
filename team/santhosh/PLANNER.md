# Santhosh's Planner

The answer when the instructor asks where the project stands. Each line is
a GitHub issue: close it with `Closes #N` in your PR and tick it here in
the same PR. Spec: `lib/features/budget/README.md`.

Dates were re-planned on 14 Oct 2026. Team-wide phases are in
`README.md` §9; each phase is a GitHub milestone.

## Before you start (any time before 20 Oct)

- [ ] Accept the GitHub collaborator invite
- [ ] Flutter, Git and an Android emulator or phone working
      (`START-HERE.md` §1)
- [ ] Codex set up, with `commit_attribution = ""` in
      `~/.codex/config.toml` (see your README)
- [x] Repo cloned; app runs in fake data mode once #3 and #4 are merged
      (`RUN.md`)

## Phase B — from the app shell merge (#3, #4) to 1 Nov

Budget — branch `flex/budget`
- [x] #27 Per-category budget for a trip (REQ-3.1)
- [x] #28 Expense form (REQ-3.2, REQ-3.3)
- [x] #29 Live balances in `BudgetProvider` (REQ-3.4)
- [x] #30 90% alert without divide-by-zero (REQ-3.5)

## Phase C — 2 Nov – 8 Nov: integration and testing

- Moved to Vishwa: #33 Budget against real trips

## Phase D — 9 Nov – 20 Nov: release and viva

- [ ] #37 Report, user guide and viva prep: why totals are recalculated
      rather than stored, and why budget and itinerary are separate

## Blockers

| Date | Blocker | Status |
| --- | --- | --- |
| | | |
