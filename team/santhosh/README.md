# Santhosh S — 24BCE5169

Builds: Budget & expenses (REQ-3.1–3.5). Canonical record:
[`docs/OWNERSHIP.md`](../../docs/OWNERSHIP.md).

GitHub: [@hehe876](https://github.com/hehe876)

## When to start

**After Vishwa's app shell is merged — issues #3 and #4.** That gives you
the theme (the design context Codex reads), a placeholder Budget screen
and Provider already in your folder, and a fake trip to attach budgets to
— so from then on you never wait for anyone.

## Your issues

| Issue | What | Phase |
| --- | --- | --- |
| #27 | Budget: per-category budget for a trip (REQ-3.1) | B |
| #28 | Budget: expense form (REQ-3.2, REQ-3.3) | B |
| #29 | Budget: live balances in `BudgetProvider` (REQ-3.4) | B |
| #30 | Budget: 90% alert without divide-by-zero (REQ-3.5) | B |
| #33 | Integration: Budget against real trips | C |
| #37 | Report, user guide and viva prep | D |

All open: [your issues on GitHub](https://github.com/Vishwa-Thangapandiyan/smart-travel-assistant/issues?q=is%3Aopen+label%3A%22owner%3A+santhosh%22).
Close each one by writing `Closes #N` in the PR that finishes it.

Your old personal copy at `hehe876/Software_eng_push` is an exact copy
of this repo from 30 Aug with nothing added — work here instead.

## One-time setup for Codex

Make sure Codex never adds itself as a co-author. In `~/.codex/config.toml`:

```toml
commit_attribution = ""
```

And set your own git identity once (see `START-HERE.md` §1), so commits
show as yours on GitHub.

## How to start a session

From the repository root, run `codex` and send:

```
Read AGENTS.md, then team/santhosh/README.md and
team/santhosh/PLANNER.md. Find my next unticked task, read its feature
README, show me the plan, then build it on the flex/budget branch,
verify it, and open the PR that closes its issue.
```

Codex reads `AGENTS.md` and the files it points to; there's nothing to
paste.

## Your feature

Spec and "done when" list:
[`lib/features/budget/README.md`](../../lib/features/budget/README.md) —
branch `flex/budget`. Everything you edit is inside `lib/features/budget/`.

Trips come from Vishwa's `trip_service.dart` (signature in
`lib/services/README.md`); use its fake trip until the real one merges.

## Merging

When CI is green, merge your own PR. No approval needed. Stuck for more
than a day? Post it in the group chat.

`AI-PROMPT-PACK.md` in this folder is an older copy-paste fallback for
times without Codex. Its Emergency prompts no longer apply — Emergency is
Sanjay's now.
