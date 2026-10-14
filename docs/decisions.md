# Decisions

Short records of choices that shaped the app, newest last. Each says what was
decided, why, and what it costs.

## 001: Local-first, no login

**Decided:** no backend and no account. Data lives in SQLite on the phone.

**Why:** one user, one device, nothing shared. A login would protect nothing
the phone's lock screen does not already protect, and a server adds hosting,
auth and sync code for no benefit.

**Costs:** losing the phone loses the data unless it is backed up, so Android
Auto Backup is on and JSON export exists. A chat assistant cannot query the data
directly, so the app exports a short text summary to paste instead.

## 002: drift for storage

**Decided:** drift over SQLite.

**Why:** money questions are sums over date ranges, which SQL answers in one
query. drift adds typed queries, managed migrations and live streams that
redraw a screen when data changes. Key-value stores (Hive, Isar) make those
aggregates awkward.

## 003: Android first

**Decided:** ship on Android first; add iOS later.

**Why:** iOS builds need macOS tooling. Dart code avoids Android-only APIs, so
the iOS port is configuration, not a rewrite.

## 004: English only

**Decided:** plain English strings, no localisation layer.

**Why:** one language is all the app needs today. Adding a localisation layer
later is mechanical; carrying an unused one now is not free.

## 005: Favourites fill the logger, never log on their own

**Decided:** tapping a favourite fills in amount, category and label. Nothing
saves until Log is pressed. Widget and launcher shortcuts behave the same way.

**Why:** everyday amounts vary from one purchase to the next. A one-tap or
hold-to-log shortcut records the wrong figure silently, and a wrong log is worse
than a slow one.

## 006: The Ocean palette

**Decided:** blue 245° as the base, apricot as its complement for money kept,
sage and rose for status. See [design system](design-system.md).

**Why:** pure black and white was harsh on the eyes; tinted teal, receipt-paper
and purple directions were rejected. Blue and apricot are true complements,
which gives contrast without clashing.

## 007: Fonts bundled, not fetched

**Decided:** Figtree ships as asset files.

**Why:** fetching fonts at runtime needs the internet permission, which v1 does
not otherwise use.
