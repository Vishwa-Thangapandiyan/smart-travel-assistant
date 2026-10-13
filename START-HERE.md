# Start Here

This is the setup and Git guide. Read it before touching any code. It assumes
you have never used Git — if that's not you, skim section 3 and move on.

---

## 1. One-time setup

Do this once, on your own machine.

| Tool | Install from | How to verify it worked |
| --- | --- | --- |
| Flutter SDK | [flutter.dev](https://flutter.dev) (install guide for your OS) | `flutter --version` prints a version number |
| Git | [git-scm.com](https://git-scm.com) | `git --version` prints a version number |
| Android Studio, or VS Code + the Flutter extension | [developer.android.com/studio](https://developer.android.com/studio) or [code.visualstudio.com](https://code.visualstudio.com) | it opens, and `flutter doctor` doesn't list it as missing |
| An Android emulator, or a physical Android phone with USB debugging on | set up inside Android Studio (Device Manager), or on the phone: Settings → About phone → tap "Build number" 7 times → Developer options → USB debugging | `flutter devices` lists at least one device |

After installing, run:

```bash
flutter doctor
```

Fix anything it flags as a blocking issue before moving on. A warning about
something you don't need yet (like an iOS toolchain — see the note at the
bottom of this section) is fine to ignore.

**Windows users:** use **Git Bash** for every Git command in this guide,
not Command Prompt or PowerShell. Git Bash installs alongside Git and
understands the commands below directly.

Set your identity in Git (once, ever):

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

Make a GitHub account if you don't have one, then send your GitHub username
to the group chat so you can be added as a collaborator on the repo. You
cannot push anything until that happens.

**iOS note:** building for iOS needs a Mac with Xcode installed. The team is
Android-first until someone on the team has access to one — don't worry
about `flutter doctor` complaining about iOS toolchain items.

---

## 2. Cloning the project

Once you have collaborator access:

```bash
git clone <repo-url>
cd smart-travel-assistant
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Fill in the two `--dart-define` values with the real Supabase keys from
the group chat — see [`RUN.md`](RUN.md) for the exact command and why this
project doesn't use a `.env` file. If you see "Setup is working" on your
emulator or device, you're done with setup.

---

## 3. The everyday workflow

This is the section you'll come back to. Every change follows the same
shape:

```
main ──► your branch ──► commit(s) ──► push ──► Pull Request ──► merge ──► back to main
```

You never work directly on `main`. You branch off it, do your work, and
bring it back through a Pull Request (PR).

### 3.1 Start from an up-to-date `main`

```bash
git checkout main
git pull
```

**Why this matters:** `main` on your laptop is a snapshot from whenever you
last pulled. If a teammate merged something since then, your copy is stale.
Branching off a stale `main` means your work and theirs diverge more than
they need to, and you get a messier merge conflict later. Pulling first is
the single biggest thing that prevents conflicts.

### 3.2 Make your branch

```bash
git checkout -b flex/x
```

Use your actual branch name from the ownership table in the main
`README.md` (e.g. `flex/accounts`, `flex/maps`) — branches are named by
feature, not by contributor.

### 3.3 Do the work, then check what changed

```bash
git status
```

Shows which files you've touched. Read it before staging anything.

### 3.4 Stage and commit

```bash
git add <folder-or-file>
git commit -m "describe what changed"
```

Add specific files or folders — not `git add .`. A bare `git add .` stages
everything in the working directory, including files you didn't mean to
touch (stray config, half-finished experiments, someone else's uncommitted
edit sitting in the tree). Naming what you add is how you catch that before
it becomes part of the commit.

Commit messages should say what changed, not restate the filename —
`"add email validation to signup form"`, not `"update form"`.

### 3.5 Push your branch

```bash
git push -u origin flex/x
```

The `-u` only matters the first time you push a given branch — after that,
plain `git push` remembers where it goes.

### 3.6 Open a Pull Request

Go to the repo on GitHub in your browser. You'll see a yellow banner
("`flex/x` had recent pushes") with a **Compare & pull request** button — click
it. If you don't see the banner, go to the **Pull requests** tab and click
**New pull request**, then pick your branch. Fill in the PR template that
appears (it's already in the repo — see `.github/pull_request_template.md`),
and open the PR.

### 3.7 Merge

GitHub runs a CI check on every PR (`flutter analyze`, and `flutter test`
once tests exist). When it shows green, click **Merge pull request**
yourself, then **Delete branch** — no one else's approval is needed, so
you never wait on a teammate. If it's red, open the check's log, fix what
it reports, and push again. Back on your machine:

```bash
git checkout main
git pull
```

Now your local `main` has your merged work, and you're ready to branch again
from step 3.1.

---

## 4. Things that will go wrong

**I started coding on the wrong branch.**

```bash
git stash
git checkout correct-branch
git stash pop
```

`git stash` sets your uncommitted changes aside so you can switch branches
cleanly, then `stash pop` brings them back on the branch you actually meant
to be on.

**Merge conflict.** Git couldn't automatically combine two changes to the
same lines and needs you to decide. The affected file will contain markers
like this:

```
<<<<<<< HEAD
your version of the line
=======
their version of the line
>>>>>>> flex/their-branch
```

Edit the file to keep the version you want (or a combination), then delete
the `<<<<<<<`, `=======`, and `>>>>>>>` marker lines entirely. **Don't guess
which version is correct on your own** — ask in the group chat. Conflicts
usually mean two people touched something without coordinating, and the
person who wrote the other side knows why their version looks the way it
does.

**Push rejected** (someone else pushed to the same branch, or you're behind):

```bash
git pull --rebase
git push
```

**I want to throw away all my local changes and start over:**

```bash
git checkout -- .
```

This is destructive — it discards uncommitted work in the current directory
with no undo. Only run it when you're sure you want to lose those changes.

**`flutter pub get` fails.** Delete the `.dart_tool/` folder and
`pubspec.lock`, then run `flutter pub get` again. If it still fails, run
`flutter doctor` to check your setup, and if that's clean too, paste the
exact error into the group chat — don't guess at fixes.

---

## 5. Cheat sheet

| Task | Command |
| --- | --- |
| Get latest `main` | `git checkout main && git pull` |
| New branch | `git checkout -b flex/x` |
| See what changed | `git status` |
| Stage a folder | `git add lib/features/x` |
| Commit | `git commit -m "message"` |
| Push a new branch | `git push -u origin flex/x` |
| Push again later | `git push` |
| Switch branches | `git checkout branch-name` |
| Set aside uncommitted work | `git stash` |
| Bring it back | `git stash pop` |
| Discard uncommitted changes | `git checkout -- .` |
| Fix a rejected push | `git pull --rebase` |
| Install/update packages | `flutter pub get` |
| Run the app | `flutter run --dart-define=... --dart-define=...` (see `RUN.md`) |
| List connected devices/emulators | `flutter devices` |
| Check your Flutter setup | `flutter doctor` |

---

## 6. Where do I go now

| Person | Folder |
| --- | --- |
| Vishwa Thangapandiyan | [`team/vishwa/`](team/vishwa/) |
| Sanjay Sivakumar | [`team/sanjay/`](team/sanjay/) |
| Santhosh S | [`team/santhosh/`](team/santhosh/) |

Open your folder's `README.md`. It has your tasks. Its `PLANNER.md` has your
dated checklist.

---

## 7. Loading project context before you work

Everyone uses a repository-aware AI tool — Claude Code (Vishwa, Sanjay)
or Codex (Santhosh). Start it from the repository root and send the
prompt in your own `team/<name>/README.md`. It reads `AGENTS.md`, your
brief, your planner and the feature README, so the requirements come
along with every task — nothing to paste.

Make sure your tool never adds itself as a co-author: Claude Code is
handled by the repo's `.claude/settings.json`; for Codex, put
`commit_attribution = ""` in `~/.codex/config.toml`.
