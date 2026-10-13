# docs/

The subfolders here are gitignored — see `docs/.gitignore`. They hold
binary course deliverables: the SRS, WBS, Gantt chart, and diagrams. Kept
locally for reference and for submission, not pushed to GitHub, because Git
stores a whole new copy of a binary file on every edit and the diffs are
unreadable anyway. The folder structure itself stays tracked so a fresh
clone shows where things belong.

Two plain-text files live directly under `docs/` and, unlike the
subfolders above, **are** tracked in git: `OWNERSHIP.md` (canonical
feature ownership record) and `WORKFLOW.md`
(shared team workflow expectations versus individual contributor
tooling). Neither is a course deliverable — both are living project
documentation.

## ⚠ These documents describe a web application. The project is now Flutter.

The SRS, DFDs, ER diagram, and UML diagrams in these folders were all
written before the Flutter decision — they describe a React + Vite web
app. **The database design inside them survives the pivot unchanged** —
`db/schema.sql` matches what's in the SRS/ER diagram — but every reference
to browsers, web hosting, IndexedDB, or a frontend/backend split described
in web terms is wrong and needs revising before submission, or it will
contradict the app you actually demo. `PROJECT-UNDERSTANDING.md` at the
repo root is the current, authoritative description of what's being
built — it **supersedes the SRS** wherever the two disagree. Read that
file, not the SRS, if you want to know how the system actually works
today.

**A specific mismatch to watch for:** the SRS still numbers Emergency's
REQ-5.2 as directions/routing per the original design, with tap-to-call
folded elsewhere. In the current docs (`docs/OWNERSHIP.md`,
`lib/features/emergency/README.md`), REQ-5.2 is "directions inside
Emergency" and tap-to-call is grouped under REQ-5.3 with the default
helplines. If the SRS text you're revising uses a different split,
reconcile it against `docs/OWNERSHIP.md` and `lib/models/CONTRACT.md`, not
the other way around — those are what the code is actually built
against.

**The WBS and Gantt chart need updating** to the 14 Oct 2026 re-plan:
new owners in `docs/OWNERSHIP.md` and new phase dates in the main
`README.md` §9.

| Folder | Contents |
| --- | --- |
| `srs/` | The Software Requirements Specification. Source of truth for scope — every feature README and task brief points back to a `REQ-<feature>.<number>` label defined here. |
| `wbs/` | The Work Breakdown Structure. |
| `gantt/` | The Gantt chart (`.xlsx`). Still shows the original sprints; the current dates are in the main `README.md` §9. |
| `images/` | Diagrams — ER diagram, architecture diagram, and anything else generated for the report. |

## Setting up your local copy

These files live on the shared drive, not in Git. Download the current
versions from there into the matching folder above. If you're not sure
you have the latest version of something, ask in the group chat before
using it in a document.

## Notes worth keeping in mind

- The SRS is the source of truth for scope. Requirement labels follow
  `REQ-<feature>.<number>` (e.g. `REQ-3.2`) — check the actual number in
  `docs/srs/` before citing one in a PR or planner, don't guess.
- The ER diagram in `images/` must stay in sync with `db/schema.sql`. If
  the schema changes, the diagram needs updating too (and vice versa).
- **Do not run the Gantt `.xlsx` through a converter or an automated
  recalculation step.** It strips the conditional-formatting fill colours
  that draw the bars, and you'll end up with a spreadsheet of numbers and
  no chart.
- Diagrams were generated from Python scripts via `cairosvg`. If one needs
  to change, regenerate it from the script — don't hand-edit the PNG.
