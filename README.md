# bajet

A personal money app for one person on one phone. Log a spend in seconds, see
what is left for the week, and know whether the current savings goal is on
track.

bajet is offline-first: everything is stored on the device, there is no
account, and v1 never touches the network.

## What it does

- **Log** spending or income from the + in the middle of the bottom bar, with a
  fill-from-right keypad, favourites that fill the form in, an optional receipt
  photo or screenshot, and undo.
- **Today** shows the balance, today's planned spend, bills due for
  confirmation, a week strip of spending against the allowance and each day's plan, the current
  goal, and recent entries. History lists everything, to edit or delete.
- **Runway** charts the projected balance up to a goal's buy day and says what
  will be left after buying it, against a buffer you choose. What-if sliders
  try a change to weekly spending or a new monthly cost without saving it.
- **Insights** shows money in and out, fixed against flexible spending, where
  the flexible money went, the last fourteen days against the plan, and
  habits, for this week, this month or all time.
- **Reports** share any of those periods as text, a PDF or a CSV file.
- **Sunday check-in** compares the balance with the bank and logs any gap.
- **Home screen**: a widget with what is left of the week, and long-press
  shortcuts, both opening the logger filled in from a favourite.
- **Coach** builds a plain-text summary of the week to paste into a chat.
- **Settings** holds every amount and rule: allowance and buffer, goals, bills
  and income, one-off events, the weekly rhythm, favourites, and backups.

## Status

Version 1.2 is in daily use on Android. An in-app coach follows; see
[release phases](docs/architecture.md#release-phases).

## Documentation

| Doc                                       | Covers                                         |
|-------------------------------------------|------------------------------------------------|
| [Architecture](docs/architecture.md)      | System design, layers, storage, backup, build  |
| [Conventions](docs/conventions.md)        | Formatting, money, naming, commits, privacy    |
| [Design system](docs/design-system.md)    | Colour, type, spacing, motion, interaction     |
| [Decisions](docs/decisions.md)            | Why the app is built the way it is             |
| [Data model](docs/data-model.md)          | Tables, columns and defaults                   |
| [Projection](docs/projection.md)          | How the buy-day forecast is calculated         |

## Getting started

Requires Flutter 3.44 or later.

```bash
flutter pub get
flutter run
```

A release build for one phone architecture keeps the APK small:

```bash
flutter build apk --release --split-per-abi
```

To move an existing plan onto a phone, export a backup from Settings → Backup
on one install and restore it on the other, either from the same screen or
straight from first-run setup.

Before committing:

```bash
flutter analyze
flutter test
```

## Privacy

This repository is public and contains demo data only. Real financial data is
kept in git-ignored `*.private.*` files and never committed.
