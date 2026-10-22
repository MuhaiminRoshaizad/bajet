# bajet

A personal money app for one person on one phone. Log a spend in seconds, see
what is left for the week, and know whether the current savings goal is on
track.

bajet is offline-first: everything is stored on the device and there is no
account. The only network use is the optional coach, which sends a question,
and only the figures it looks up to answer it, to Anthropic with the user's
own API key; without a key, nothing leaves the phone.

## What it does

- **Log** spending or income from the + beside the tabs in the floating bottom bar, with a
  fill-from-right amount on the phone's number pad, favourites that fill the form in, an optional receipt
  photo or screenshot, and undo. Days you forgot can be logged up to a year back.
- **Accounts** keep bank, cash and e-wallet money apart as cards you design,
  with transfers between them that are neither spending nor income.
- **Today** shows the balance, today's planned spend, bills due for
  confirmation, a dial of the week's spending against the allowance that says what is left a day,
  the current goal, and recent entries. History lists everything, to edit or delete.
- **Runway** charts the projected balance up to a goal's buy day and says what
  will be left after buying it, against a buffer you choose. What-if sliders
  try a change to weekly spending or a new monthly cost without saving it.
- **Insights** shows money in and out, fixed against flexible spending, a ring
  of where the money went, the last fourteen days against the plan, and
  habits, for any week, any month or all time.
- **Reports** share any of those periods as text, a PDF or a CSV file, broken
  down by account and category, and PDFs, CSVs and backups save straight to
  the phone.
- **Sunday check-in** compares the balance with the bank, logs any gap, and saves next week's target; the week is shared as text, a PDF or an image card.
- **Launcher shortcuts**: long-press the app icon to open the logger, empty
  or filled in from a favourite.
- **Coach** answers questions about your money by looking up the figures it
  needs, any week, month, entry, account or the plan, using your own
  Anthropic key, up to ten a day. It can suggest logging a spend, moving money
  or marking a bill paid, which happens only when you tap to confirm. Pick
  who coaches you, bajety the titanium orb or one of three finance people,
  and how they talk, from friendly to roasting; their face reacts as you
  chat, scroll and type. Chats are kept apart in a list you can search, pin,
  rename and delete, each with its own coach and personality, and remembered
  on the phone only. Messages that are not about your money are turned away
  on the phone, costing nothing. The week's summary can also be copied to
  paste anywhere.
- **Settings** holds every amount and rule: allowance and buffer, goals, bills
  and income, one-off events, the weekly rhythm, favourites, backups, and a
  light or dark appearance that otherwise follows the phone.
- **App lock**, if you turn it on, asks for your fingerprint or phone PIN
  when bajet opens and after you have been away a while, then opens on
  Today.

## Status

Version 1.12 is in daily use on Android, with a demo mode for screenshots and
CI on every push; see
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

To try bajet, or take screenshots, without touching your own data, start it
on made-up data held in memory:

```bash
flutter run --dart-define=BAJET_DEMO=true
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

GitHub Actions runs the same two checks on every push to `main` and every pull
request (`.github/workflows/ci.yml`), on the pinned Flutter version.

## Privacy

This repository is public and contains demo data only. Real financial data is
kept in git-ignored `*.private.*` files and never committed.
