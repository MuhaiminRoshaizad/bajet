# Conventions

Where a choice could reasonably go two ways, it is settled here.

## Formatting

| What      | Rule                     | Example        |
|-----------|--------------------------|----------------|
| Dates     | `dd/mm/yyyy` in the UI   | `01/07/2026`   |
| Storage   | ISO `yyyy-mm-dd`         | `2026-07-01`   |
| Time      | 24-hour                  | `14:15`        |
| Currency  | `RM`, no space, 2 dp, thousands separator | `RM1,250.00` |

Currency uses `intl`'s Malay pattern `¤#,##0.00`, which produces this format
without a custom pattern.

## Money

- Stored and computed as integer **sen** (`int`). Never `double`.
- Converted to ringgit only when formatting for display.
- Typed amounts fill from the right like a cashier's till: typing `1`, `5`, `0`
  gives `RM1.50`. A field can never hold a malformed amount.
  `RinggitCentsFormatter` in `core/validation/` does this for text fields, and
  `RinggitCentsFormatter.parse` reads the sen back.

## Text fields

- Every name and note starts with a capital: `TextCapitalization.sentences`
  asks the keyboard for a shift, and `CapitaliseFirstFormatter` makes sure,
  since some keyboards ignore the hint.

## Generated code

drift output (`*.g.dart`) is committed, and regenerated with
`dart run build_runner build` in the same commit as the table change that
caused it, so every commit builds from a fresh clone.

## Language

English only, as plain strings. There is no localisation layer.

## Dart

- `snake_case.dart` files, `UpperCamelCase` types, `lowerCamelCase` members.
- Riverpod providers end in `Provider`; notifiers end in `Controller`.
- One state-management approach app-wide: Riverpod.
- Comments explain why, not what.
- Docs and comments call the person using bajet "the user", the voice of
  product docs; never "the owner" or the first person of whoever wrote them.

## Data and privacy

- The repository is public. Real financial data never enters it, in code,
  tests, fixtures or screenshots.
- Real data lives in files matching `*.private.*`, which git ignores.
- Committed seeds, fixtures and screenshots use demo figures only.

## Versioning

bajet carries three version numbers. They follow different rules on purpose,
because they answer different questions.

### App version: `pubspec.yaml`, `version: MAJOR.MINOR.PATCH+BUILD`

[Semantic Versioning 2.0.0](https://semver.org/) for the part before `+`:

| Bump  | When                                                        | Example         |
|-------|-------------------------------------------------------------|-----------------|
| MAJOR | A change that breaks what came before, such as a backup file older versions can no longer read | `1.4.2` → `2.0.0` |
| MINOR | A new feature that keeps everything working                 | `1.0.3` → `1.1.0` |
| PATCH | A bug fix only                                              | `1.1.0` → `1.1.1` |

Bumping a number resets the ones to its right to 0. Each number counts up by
one with no limit: `1.9.0` is followed by `1.10.0`, not `2.0.0`.

The number after `+` is the build number. Flutter passes the name to Android's
`versionName`, which users see, and the build number to `versionCode`, a
positive integer Android uses to tell newer builds from older ones and to
refuse downgrades. It must go up by at least one on every build that is
installed or released, whatever the name does, and it never resets.

Release phases map onto the app version: v1 is `1.0.0`, v1.1 is `1.1.0`, and
so on. A fix inside a phase is a patch, such as `1.1.1`.

The same version lives in `lib/app/app_version.dart`, which Settings → About
bajet shows; `test/app/app_version_test.dart` fails if it ever differs from
`pubspec.yaml`, so a release bumps both in the same commit.

### Database schema: `AppDatabase.schemaVersion`

A plain integer, as drift requires. Any table change adds one and comes with a
migration step from the previous number.

### Backup format: `"format"` in the backup file

A plain integer too, not SemVer, because a file format has one question to
answer: can this reader understand this file? Rules:

- Add one whenever the shape of the file changes, even by one field.
- Never reuse or skip a number.
- Each release keeps restoring every older format by upgrading it step by step
  (1 → 2 → 3) before reading it, so an old backup always restores.
- A file with a newer format than the app knows is refused with a message,
  never half-read.

The format and the schema often change together, but they are counted
separately: a schema change that does not alter the file leaves `format` alone.

## Commits

[Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):
`type(scope): subject`.

- Imperative, lowercase subject, no trailing period, about 72 characters.
- One task per commit. If a title needs "and", it is two commits.
- A body, when needed, is one short paragraph: what was wrong, what changed,
  what is deliberately left alone.
- Allowed types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`,
  `ci`, `chore`, `style`, `revert`.
- Scopes name an area, not a file (`theme`, `log`, `today`, `runway`, `db`).
  Check `git log` for an existing scope before inventing one.
- Every commit leaves `flutter analyze` and `flutter test` green.

## Testing

| Kind               | What it covers                          | Runs against                 |
|--------------------|-----------------------------------------|------------------------------|
| Unit               | Pure logic: projection, formatters      | Plain Dart                   |
| Repository         | drift queries, constraints, migrations  | `NativeDatabase.memory()`    |
| Provider           | How providers combine repository data   | In-memory drift database     |
| Widget             | Screens and flows                       | Fakes in `test/helpers/`     |

Widget tests use `pumpApp` from `test/helpers/app_harness.dart`, which swaps
the repositories for in-memory fakes and pins today's date. They do not use
drift directly: drift's stream-cleanup timers do not run on the widget
tester's fake clock, so a drift database cannot be closed inside a widget test.
Expected values in tests are worked out independently, never copied from the
code's own output.

## Documentation

Docs change in the same commit as the code they describe. A feature that
changes behaviour, a token, a table or a convention updates the matching file
in `docs/` before it is committed.
