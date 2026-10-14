# bajet

A personal money app for one person on one phone. Log a spend in seconds, see
what is left for the week, and know whether the current savings goal is on
track.

bajet is offline-first: everything is stored on the device, there is no
account, and v1 never touches the network.

## Status

In development. v1 covers logging, the Today screen, the weekly ring, history,
a basic runway and a coach-ready text export. See
[release phases](docs/architecture.md#release-phases).

## Documentation

| Doc                                       | Covers                                         |
|-------------------------------------------|------------------------------------------------|
| [Architecture](docs/architecture.md)      | System design, layers, storage, backup, build  |
| [Conventions](docs/conventions.md)        | Formatting, money, naming, commits, privacy    |
| [Design system](docs/design-system.md)    | Colour, type, spacing, motion, interaction     |
| [Decisions](docs/decisions.md)            | Why the app is built the way it is             |

## Getting started

Requires Flutter 3.44 or later.

```bash
flutter pub get
flutter run
```

Before committing:

```bash
flutter analyze
flutter test
```

## Privacy

This repository is public and contains demo data only. Real financial data is
kept in git-ignored `*.private.*` files and never committed.
