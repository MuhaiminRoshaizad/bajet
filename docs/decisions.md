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
directly, so the Coach tab builds a short text summary of the week to copy and
paste instead (`weekSummary` in `features/coach/domain`).

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

## 008: Recurring items track their next due date

**Decided:** each recurring item stores `nextDue`, the date of its next unpaid
occurrence. The projection charges it from that date onward, and confirming a
payment moves it forward a month.

**Why:** "skip it if it was confirmed this month" breaks when a bill is paid
early. A bill due on the 15th but paid on the 11th, before the opening balance
was taken, would otherwise be charged twice. `nextDue` states exactly which
occurrences are still to come.

## 009: A soft, neumorphic surface

**Decided:** cards and controls share the background colour and stand out
only through two soft shadows, lit from the top left; inputs, tracks and
notices are wells pressed into it. The Ocean hues stay, on a blue-grey base.
See [design system](design-system.md#surfaces).

**Why:** a calmer, more physical look than flat white cards, suited to an app
opened many times a day for a few seconds.

**Costs:** neumorphism's known weakness is contrast. A shadow derived from the
background cannot reach the 3:1 that WCAG 1.4.11 asks of state indicators, so
depth never carries meaning alone: selected controls also get an accent fill or
outline, focus gets a 3 px accent ring, and the main action of each screen
stays a solid accent button. WCAG does not require a boundary around a button
identified by its text, so plain soft buttons are allowed. Every text colour
was rechecked against both the surface and the darker well.

## 010: Untracked money is its own fixed category

**Decided:** when the bank shows less than bajet at a check-in, the gap is
logged under a built-in `untracked` category, which is fixed.

**Why:** the gap is real money gone, so it must leave the balance, but it was
spent on unknown days. Counting it against the weekly allowance would mark
whichever day the check-in happens as over plan. Keeping it separate also lets
Insights show how much went untracked, which is the habit worth watching.

**Costs:** untracked spending never shows in the weekly ring. Insights
surfaces it instead.
