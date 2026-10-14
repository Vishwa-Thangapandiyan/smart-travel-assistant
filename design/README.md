# design/

Reference material for the app's look. The rules are in
[`../DESIGN.md`](../DESIGN.md) — start there.

| Folder / file | What it is |
| --- | --- |
| `tokens.json` | Exact colours, type, spacing, radius and motion values. `lib/theme/` is built from these. |
| `screens/*.png` | A picture of every designed screen — what the finished screen should look like. |
| `artboards/*.html` | The same screens as plain HTML. Open one in a browser to inspect exact sizes and colours. Reference only — the app is Flutter. |
| `artboards/assets/` | The two map images the map screens use (OpenStreetMap data, © OpenStreetMap contributors). |

These are exports of the team's design canvas. Don't edit them by hand to
change the design — change the design first, then re-export, so the
picture and the rules never disagree.
