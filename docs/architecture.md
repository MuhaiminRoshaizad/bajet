# Architecture

bajet is a single-user, offline-first Flutter app. All data lives in a SQLite
database on the phone. There is no backend, no account and no login.

## System overview

```mermaid
flowchart LR
  UI[Widgets] --> C[Riverpod controllers]
  C --> R[Repository interfaces]
  R --> D[Drift / SQLite on device]
  D -. daily .-> AB[Android Auto Backup<br/>to Google Drive]
  D -. on demand .-> J[JSON export file]
```

### Why there is no backend

A login protects data that sits on a server or is shared between people. bajet
has one user, one device and nothing shared, so the phone's lock screen already
does that job. Removing the server also removes hosting, auth and sync code.
See [decisions](decisions.md#001-local-first-no-login).

### Network

Release builds declare no `INTERNET` permission. Fonts are bundled. The only
planned network feature is the coach (v1.3), which will use the owner's own API
key held in secure storage.

## Layers

Data flows one way:

```
widget → controller (Riverpod) → repository interface → data source (drift)
```

| Layer          | Holds                                               | May depend on      |
|----------------|-----------------------------------------------------|--------------------|
| `presentation` | Screens, widgets, Riverpod controllers              | `domain`           |
| `domain`       | Models, repository interfaces, pure logic           | nothing            |
| `data`         | Repository implementations, drift tables and DAOs   | `domain`, `core`   |

Repository interfaces are the seam for any future cloud sync: a second
implementation can replace the drift one without touching screens.

## Folder structure

```
lib/
  main.dart
  app/                  router, shell, bootstrap
  core/
    database/           drift tables, the database class and its defaults
    dates/              dd/mm/yyyy formatting, the only place dates become text
    money/              sen ↔ RM formatting, the only place money becomes text
    theme/              colour, spacing, radii and motion tokens
    validation/         input formatters and validators
    widgets/            widgets shared by two or more features
  features/
    <feature>/
      data/
      domain/
      presentation/
```

A folder under `core/` appears only once two features need it.

## Features

| Feature  | Owns                                                                  |
|----------|-----------------------------------------------------------------------|
| `ledger` | Entries, categories and favourites, the log sheet, history, balance and flexible-spend maths |
| `plan`   | Settings, weekly rhythm, recurring items, planned events, goals, the projection and the Runway screen |
| `today`  | The Today screen: balance, today's rule, bills due, weekly ring, goal, recent entries |
| `settings` | The Settings hub behind Today's gear: allowance and buffer, goals, bills and income, planned events, the weekly rhythm and favourites |
| `backup` | JSON export through the share sheet and restore from a picked file |
| `coach`  | The Coach tab: a plain-text week summary to copy into a chat; an in-app coach is planned for v1.3 |
| `setup`  | First-run setup: balance, weekly allowance, buffer, optional first goal, or a backup restore instead |

Shared providers live beside what they provide: `databaseProvider` and
`todayProvider` in `core/database/database_provider.dart`. Tests override both,
the first with an in-memory database and the second to pin the date.

## Navigation

`go_router` with a `StatefulShellRoute`: four top-level destinations behind
one bottom bar, each keeping its own stack and scroll position. Routes are
declared once in `lib/app/router.dart`; their paths live in
`lib/core/navigation/routes.dart` so a feature can link to another without
importing the router. History (`Routes.history`) and Settings (`Routes.settings`) sit under
Today's branch. Screens planned for a later release show
an honest placeholder that names the release, never a dead control.

Until setup has stored an opening balance, every route redirects to
`/setup`; once settings exist, `/setup` redirects to Today. The router listens
to `settingsProvider`, so finishing setup moves on without the setup screen
navigating itself. Restoring a backup from setup works the same way: the
restored settings row is what moves the router on.

## Storage and backup

- **Database:** drift over SQLite, opened with `drift_flutter`. Money is stored
  as integer sen.
- **Android Auto Backup:** on. Android copies app data to the owner's Google
  Drive about once a day, while the phone is idle, charging and on Wi-Fi.
- **JSON export and import:** Settings → Backup exports every table as one
  JSON file through the share sheet and restores one picked with the system
  file picker, after confirming. It is the backup the owner controls, and the
  way a set-up plan is loaded onto a new phone. See the
  [backup format](data-model.md#backup-format).

## Platforms

Android now; iOS later, since iOS builds need macOS tooling. Dart code must
not use Android-only APIs, so iOS is an addition rather than a rewrite.

## Build and run

```bash
flutter pub get
dart run build_runner build   # only after changing a table
flutter run
flutter analyze
flutter test
```

Build tooling note: `sqlite3` 3.x compiles or downloads SQLite through a Dart
build hook at build time. The app itself never downloads anything.

## Release phases

| Phase | Scope                                                                 |
|-------|-----------------------------------------------------------------------|
| v1    | Log, Today, weekly ring, history, basic runway, coach-ready export    |
| v1.1  | Insights, PDF and CSV export                                          |
| v1.2  | What-if sliders, home-screen widget, launcher shortcuts               |
| v1.3  | Coach                                                                 |
| later | Demo mode, CI                                                         |
