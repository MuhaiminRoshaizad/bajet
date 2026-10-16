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

**Costs:** untracked spending never shows in the week strip. Insights
surfaces it instead.

## 011: Receipts are files beside the database, not in it

**Decided:** a receipt image is saved as a file in the app's private storage,
and the entry stores its file name. Picking uses `image_picker`, which on
Android goes through the system photo picker and camera, so bajet asks for no
storage or camera permission.

**Why:** images would bloat the database and every query that reads entries.
As files, they are compressed once, read only when shown, and copied by
Android Auto Backup alongside the database.

**Costs:** the JSON backup carries the file name but not the image, so a
backup restored on another phone keeps the entries and loses the pictures;
the entry then shows a placeholder. If Android closes bajet while the camera
is open, the half-written log is lost along with the photo, so there is
nothing to recover the image into; the owner logs it again.

## 012: The week as bars, not a ring

**Decided:** Today and the check-in show the week as one allowance bar and
seven day columns, each filled to its spend with a mark at its plan. This
replaces a ring of seven equal segments.

**Why:** the ring's segments were the same size whatever was spent, so only
their colour carried meaning and every amount had to be read from text beside
it. A length is the most accurately read encoding of a quantity, so a bigger
spend now looks bigger, and over plan shows as a bar past its mark as well as
in rose.

**Costs:** the card is taller than the ring was.

## 013: A native widget through home_widget

**Superseded by 016.**

**Decided:** the home-screen widget is a small Android layout
(`BajetWidgetProvider`, `res/layout/bajet_widget.xml`) fed by the
`home_widget` package; launcher shortcuts use Flutter's own
`quick_actions`. Both open the app with a `bajet://log` link, optionally
naming a favourite.

**Why:** Android widgets cannot be drawn by Flutter, so some native code is
unavoidable. `home_widget` handles the data hand-over and the launch intents,
leaving only the layout and a short provider to write. One link format means
one parser serves both the widget and the shortcuts.

**Costs:** a third-party dependency with native code. Through AndroidX
WorkManager it adds four install-time permissions (wake lock, network state,
start at boot, foreground service), none of which Android asks the owner
about and none of which is internet access. The widget shows the week's
remaining allowance only; the balance stays inside the app.

## 014: The coach runs on the owner's own key

**Decided:** the in-app coach calls Anthropic's Messages API directly from
the phone with an API key the owner pastes into Settings → Coach, stored in
secure storage, with at most 10 questions a day.

**Why:** with no bajet server, there is nowhere else a key could live, and a
key shipped inside the app would be readable by anyone who unpacks it. The
owner's own key keeps the cost and the account in the owner's hands. The
daily cap protects that bill from a stuck retry or a long evening of
questions.

**Costs:** this is the app's only use of the network, and what is sent (the
question plus a summary of the week and month) goes to Anthropic under the
owner's account. The Coach screen says so before the first question. A
backup does not carry the key, so it is entered again after a restore.

## 015: Pay and bills that move around count cautiously

**Decided:** a bill or income can land anywhere in a window of up to 27
days, entered as its earliest and latest day. The projection counts income
on the window's last day and a bill on its first. Today offers it for
confirmation from the first day.

**Why:** pay and some bills do not arrive on the same date each month.
Counting each at its least convenient moment means Runway and the goal
outcome can only be beaten, never undercut, by when money really moves.
Twenty-seven days keeps one month's window closed before the next opens.

**Costs:** a projection with a window dips lower between a window's start and
end than the money usually does. Schema version 3 and backup format 3 add
`window_days`; older databases and backups read as fixed days.

## 016: No home-screen widget for now

**Decided:** the home-screen widget and the `home_widget` package are
removed. The launcher shortcuts stay, still opening the logger through a
`bajet://log` link.

**Why:** the widget looked out of place next to the rest of the app, and it
would show what is left of the week on a screen anyone can see, which the
app lock cannot cover. A widget will come back later, redesigned, and that
redesign has to settle how it behaves while the app is locked.

**Costs:** logging from the home screen now takes a long-press on the icon
instead of one tap.

## 017: App lock through local_auth

**Decided:** the optional app lock asks for the phone's own fingerprint,
face or screen lock through `local_auth`, published by the Flutter team.
bajet keeps no PIN of its own, and the phone's PIN, pattern or password is
always accepted when the fingerprint fails.

**Why:** the phone already holds a credential the owner knows and Android
already guards it, so a second PIN would only be something else to forget.
A first-party package is the safest bet for code that has to follow every
Android and iOS release.

**Costs:** Android needs a fragment activity, the `USE_BIOMETRIC`
permission (granted at install, never asked about) and AppCompat themes,
which bring in `androidx.appcompat`. iOS will need a Face ID purpose string.
The lock guards the screen only: the database is protected by Android's app
sandbox and storage encryption, not by the lock, and an exported backup is
as readable as before.

While the lock is on, Android 13 and later keep no picture of bajet for the
app switcher (`setRecentsScreenshotEnabled`), so the switcher shows a blank
card. `FLAG_SECURE` would cover older phones too, but it also blocks every
screenshot the owner takes, so it is not used.

## 018: bajet plays its opening itself

**Decided:** the opening animation runs in Flutter from the first frame.
Android's launch screen, including the Android 12 splash, shows plain
graphite and no icon while the app loads.

**Why:** the opening was approved as a mock-up and has to bounce exactly
as it did there. Android's splash can play an animated icon, but it crops
it to a circle, which the cards overshoot while bouncing, keeps it to
about a second, and ends it whenever the app is ready, which on a fast
start would cut the deal off halfway.

**Costs:** the deal starts once bajet has loaded, not the moment the icon
is tapped, so a slow start shows graphite for a moment first. The whole
opening runs about 2.85 s; a tap skips it, and it plays on a cold start
only.
