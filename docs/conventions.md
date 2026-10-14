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

## Language

English only, as plain strings. There is no localisation layer.

## Dart

- `snake_case.dart` files, `UpperCamelCase` types, `lowerCamelCase` members.
- Riverpod providers end in `Provider`; notifiers end in `Controller`.
- One state-management approach app-wide: Riverpod.
- Comments explain why, not what.

## Data and privacy

- The repository is public. Real financial data never enters it, in code,
  tests, fixtures or screenshots.
- Real data lives in files matching `*.private.*`, which git ignores.
- Committed seeds, fixtures and screenshots use demo figures only.

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

## Documentation

Docs change in the same commit as the code they describe. A feature that
changes behaviour, a token, a table or a convention updates the matching file
in `docs/` before it is committed.
