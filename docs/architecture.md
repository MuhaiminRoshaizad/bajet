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
planned network feature is the coach (v1.3), which will use the user's own API
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
    navigation/         route paths, so features can link without the router
    platform/           screens bajet opens outside itself (camera, pickers, share sheet)
    sharing/            the share sheet and the "Save to" screen, for backups and reports, and drawing a widget off screen as a picture
    storage/            yes-or-no device flags kept as files of the app's own, outside the database and backups
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
| `accounts` | The places money is kept (cash, banks, e-wallets), each one's balance and card, and money moved between them |
| `ledger` | Entries, categories and favourites, the log sheet, history, balance and flexible-spend maths |
| `plan`   | Settings, weekly rhythm, recurring items, planned events, goals, the projection and the Runway screen |
| `today`  | The Today screen: balance, today's rule, bills due, the week dial of wants with the week's needs under it, goal, recent entries |
| `settings` | The Settings hub behind Today's gear: the user's name for the coach, balance, accounts, allowance and buffer, goals with their listing links, bills and income, planned events, the weekly rhythm and favourites, and About bajet with the installed version |
| `backup` | JSON export saved to a folder or through the share sheet, and restore from a picked file |
| `checkin` | The Sunday check-in: compare each account with what it really holds (the bank app as a whole while there is one account), log any gap to that account (a starting adjustment at the first one), look back at the week, and finish it to save next week's target (decision 027) |
| `report` | Reports of a week, a month or all time, shared as text, PDF (the `pdf` package) or CSV; the current week as the weekly check-in |
| `launch` | Launcher shortcuts: one `bajet://log` link format, a pending launch held until the shell can open the logger, and keeping the shortcuts in step with the favourites |
| `insights` | The Insights tab: money in and out, spending by kind (planned, wants, needs) with each part's entries, categories, the last fourteen days and habits, for a week, a month or all time |
| `coach`  | The Coach tab: a list of chats, each opening on its own page, with questions answered by Anthropic with the user's own key from Settings → Coach, up to 10 a day. The model reads the user's figures through read-only lookups run on the phone (`coach_lookups.dart`, looped in `coach_answer.dart`); the week's summary can still be copied |
| `opening` | The opening played on a cold start: its timeline as plain data, the titanium cards and the lock screen's fan, and the cards' flight into Today's stack that the unlock shares; the overlay that plays it lives in `app/` because it draws Today's and the lock screen's cards |
| `lock`   | The app lock: the lock screen over the whole app, asking for the phone's fingerprint or PIN on a cold start and after time away, its fan flying into Today's stack once it passes, and the user's lock choices |
| `setup`  | First-run setup: a welcome asking what the coach should call the user (optional), where money is kept (at least one account, with what it holds now), weekly allowance, buffer, optional first goal, or a backup restore instead |

Shared providers live beside what they provide: `databaseProvider` and
`todayProvider` in `core/database/database_provider.dart`. Tests override both,
the first with an in-memory database and the second to pin the date.

## Navigation

`go_router` with a `StatefulShellRoute`: four top-level destinations behind
one floating bottom bar, each keeping its own stack and scroll position. The
shell's body runs under the bar (`extendBody`), so a tab's list pads its end
with `underBar` rather than sitting in a bottom `SafeArea`. Routes are
declared once in `lib/app/router.dart`; their paths live in
`lib/core/navigation/routes.dart` so a feature can link to another without
importing the router. A chat with the coach (`Routes.coachChat`) sits under
the Coach branch the same way. History (`Routes.history`), the check-in (`Routes.checkin`)
and Settings (`Routes.settings`) sit under Today's branch but open on the root
navigator (`parentNavigatorKey`), so they and every page under them fill the
screen without the bottom bar, which belongs to the four tabs alone. Your
accounts (`Routes.accounts`) opens the same way but over Today, which stays
underneath while the page draws its own arrival from where Today's stack was
(`StackPlaces`, passed as the route's `extra`). The report
(`Routes.report`) sits above the tabs, so it opens the same way from Settings,
Insights and the check-in, and takes the range as `?period=week|month|all`
plus `&offset=-n` for a week or month n back from the current one.

Until setup has saved its settings, every route redirects to
`/setup`; once settings exist, `/setup` redirects to Today. The router listens
to `settingsProvider`, so finishing setup moves on without the setup screen
navigating itself. Restoring a backup from setup works the same way: the
restored settings row is what moves the router on.

## Storage and backup

- **Database:** drift over SQLite, opened with `drift_flutter`. Money is stored
  as integer sen.
- **Android Auto Backup:** on. Android copies app data to the user's Google
  Drive about once a day, while the phone is idle, charging and on Wi-Fi.
  The coach's API key is left out (`res/xml/backup_rules.xml` and
  `data_extraction_rules.xml`): it is encrypted with a Keystore key that is
  never backed up, so a restored copy could not be read.
- **Secrets:** the coach's Anthropic key is the only secret, kept with
  `flutter_secure_storage` (Android Keystore, iOS Keychain). It never enters
  the database, a backup file or the code.
- **JSON export and import:** Settings → Backup exports every table as one
  JSON file, saved where the user picks or sent through the share sheet, and
  restores one picked with the system file picker, after confirming. Saving
  (also offered for PDF and CSV reports) opens Android's own "Save to" screen
  through `MainActivity`'s files channel, so it needs no storage permission;
  on iPhone the share sheet's Save to Files does the same job. It is the backup the user controls, and the
  way a set-up plan is loaded onto a new phone. See the
  [backup format](data-model.md#backup-format).

## Network

The only network traffic is the coach: HTTPS requests to
`api.anthropic.com/v1/messages`, made from the phone with the user's own
key. A question is one quick request to `claude-haiku-5-5`, the gatekeeper
(decision 025), then one to the coach, plus one more for each round of
lookups the model asks for (at most four, decision 022); each carries the last 20 messages
of the chat and the results of the lookups so far, never the whole database. Nothing
else leaves the phone, and without a key nothing does at all. `INTERNET` is
in the manifest for this alone.

The coach's lookups (`coachLookups`) are Anthropic tool definitions:
`bajet_overview`, `bajet_period`, `bajet_entries`, `bajet_accounts` and
`bajet_plan`. `runLookup` answers them from a `CoachData` snapshot that
`coachDataProvider` builds from the loaded providers, and `coachAnswer`
runs the loop: send, run any lookups the reply asks for, send their results
back as `tool_result` blocks with the assistant turn unchanged, and after
four rounds send `tool_choice: none` so the model must answer. Requests use
`claude-sonnet-5-5` at `effort: low` with server-side `fallbacks: "default"`;
a `refusal` stop reason becomes `CoachProblem.refused`.

The coach's voice is one of six fixed personalities (`CoachPersonality` in
`coach_settings.dart`: Friendly, Strict, Cheerleader, Roaster, Sees
Everything, Professional), stored with the chosen avatar and the memory
switch in `coach_settings` through `CoachSettingsRepository`. Those are
the defaults a new chat starts with; each chat then keeps its own coach and
personality.
`coachSystemPrompt(today, personality, face:, userName:)` puts the same
fixed rules first in every request (only bajet's money, refuse anything
else in character, do the money half of a mixed request, no investment
picks, whatever the user asks it to pretend) and only the last paragraph,
the voice, changes (decision 024). It opens with the chat's coach by name
and the name the user gave in setup or Settings, or an instruction to use
none, and says the coaches are never the user: with neither, a model once
took a coach's hello in the chat for the user's name.

Every message passes `coach_guard.dart` first. A message the same as the
last one, sent again within a minute, is answered on the phone. `gate` then
asks Haiku 5.5, with thinking off and a JSON schema, whether the message is
`money`, `mixed`, `off_topic` or an `attack`; the last two are answered on
the phone with the personality's `declineLine`, and never reach the coach
or count against the day's questions. A reply that comes back as code
(`replyLooksWrong`) is shown as a `declineLine` instead. A long reply is
shown in full, however long; only the API's `maxTokens` bounds it. Both line
sets get firmer the more often they are used. `test/eval/coach_eval_test.dart`
sends real attacks to the real models; it runs only by hand with
`--dart-define=COACH_EVAL_KEY=...`, so CI skips it.

The Coach tab lists chats (`CoachScreen`), pinned ones first, then the
most recent; each opens on its own page (`CoachChatScreen`,
`Routes.coachChat`) over the bottom bar. `CoachChatsController` holds every
chat (`CoachThread`: name, pin, coach, personality and messages) and saves
each change behind it through `CoachChatRepository`: to `coach_threads` and
`coach_messages` while the memory switch is on (decision 026), and to a
session-only `MemoryCoachChatRepository` while it is off, so switching moves
the chats across rather than dropping them. A chat is named after its first
question by the app, not the model, and a new chat left before anything is
asked in it is dropped. `CoachController`, one per chat, runs the asking and
answering in that chat's own coach and voice, and sends the model only the
chat's last 20 messages (`forModel`). Its older messages and every other
chat's stay on the phone; the `bajet_past_chats` lookup searches them when a
question needs them. The pushback against spam (`CoachPushback`) is shared,
so a new chat is no way round it. Turning memory off forgets what was kept,
and Forget everything clears every chat with an Undo. Neither the chats nor
the coach settings go into a backup.

The coach changes nothing itself (decision 023). Three more tools,
`proposalTools` in `coach_proposals.dart`, only suggest: `bajet_propose_log`,
`bajet_propose_move` and `bajet_propose_bill_paid`. `propose` checks each
against the same `CoachData` (a real category and account, an amount above
RM0.00 and at most RM100,000.00, a move no larger than the source account
holds, a day no later than today and within the last year, an active bill)
and either returns a `CoachProposal` or tells the model why not. A
proposal becomes a `CoachCard` on the reply; `CoachController.confirm`
writes it through the ledger, account or plan repository, and `undo`
deletes the entry or transfer it made. A bill marked paid from a card
logs its planned amount and has no Undo; Today's Paid and Received open
the log sheet with the bill picked instead, so the real amount is logged
(`EntryDraft.billId`).

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
| v1.1  | Insights, text, PDF and CSV reports, Sunday check-in, receipts        |
| v1.2  | What-if sliders, launcher shortcuts                                   |
| v1.3  | Coach                                                                 |
| v1.4  | Accounts and transfers, deleting accounts, logging forgotten days, app lock, the opening animation, the week dial, past weeks and months, the category ring, reports by account, saving files to the phone, demo mode (`--dart-define=BAJET_DEMO=true`, in-memory made-up data) and CI on every push; the coach looks up any period and suggests changes to confirm |
| v1.5  | The coach as a character: four coaches to pick from (bajety and three finance people) with moods that react to the chat, six personalities, one chat remembered on the phone, a gatekeeper that turns away off-topic messages, attacks and spam, springy chat motion, and capitals at the start of every name and note |
| v1.6  | The weekly check-in: finishing it saves next week's target, so each week is judged against the last one's target and the goal apart from it; a first check-in sets the baseline and its gap is a starting adjustment; the week shared as verdict-first text, an A4 PDF with the app icon and the coach's face, or a 4:5 image card in the app's theme; the general report drops empty lines |
| v1.7  | A floating bottom bar, a soft pill of tabs beside a moulded + that the page scrolls under; the Coach as a list of chats to search, pin, rename and delete, each opening on its own page with its own coach and personality, a note when the personality changes, tailed bubbles across the full width, and faces that look the way you scroll and down at the box as you type |
| v1.8  | Where the money went opens up: tap a slice of the ring, or its row, and it springs out while the category's entries open beneath it, newest first, each opening in the edit sheet; the key's amounts line up on the card's edge. Also since 1.7: coach replies drawn with their formatting, chats opening at the newest message, long replies opening at their first line, status and sources inside the bubbles, messages springing in as they scroll into view, and the bar's tabs centred in a hollow that squashes at the ends |
| v1.9  | The coach knows who is talking: setup opens on a welcome that asks, optionally, what to call the user, Settings keeps it under You, backups carry it, and the coach is told its own name and the user's, so it never borrows a coach's name for them; questions about the chat get past the gatekeeper. The keyboard waits for a tap: the log sheet opens with the number pad down, and the bank and e-wallet list is a sheet to scroll, with search on tap. Also since 1.8: the picked coach's slot filled and outlined, and the ⋮ menu growing out of its own button over a dimmed screen |
| v1.10 | A goal keeps the listing it is saving for: a pasted web link, shown in Settings → Goals as a small preview with what it showed when last looked at; tapping opens it in another app, and back in bajet a sheet asks whether it is still for sale. Also since 1.9: no field opens the keyboard by itself, and no text field offers the phone's autofill |
| v1.11 | Every save says so: one bar at the foot of the page names what was done, offers Undo where it can be put back, and leaves by itself after five seconds; Paid and Received on Today and Done on an event can now be undone, and switching the coach's memory off asks first. The goal's listing also shows on Insights' goal card, and the still-for-sale question is asked wherever the user comes back, after the lock if it came down |
| v1.12 | Real amounts: the log sheet's row of tiles offers the bills, income and planned events due near the day, and an entry logged for one pays that bill or receives that income for the month at the amount typed, or closes an income event such as a cash-out; Today's Paid and Received open the sheet with it picked. Also since 1.11: the bar keeps one clock across pages and moves once, and text is kept as typed, with no forced capitals |
| v1.13 | Wants and needs: each spend is a want or a need, Family starting as a need, and only wants count toward the allowance, the day's plan, the check-in and the habits; the log sheet asks with a What kind? row, Today shows the week's needs under the dial, Insights splits spending into planned, wants and needs with each part's entries and gives a tip a week, and an explainer opens once. Also: a bill paid from its tile stays out of the allowance whatever its category |
