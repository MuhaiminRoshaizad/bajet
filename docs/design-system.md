# Design system

Everything visual in bajet comes from the tokens in `lib/core/theme/`. Widgets
never use a raw colour, padding number or duration.

## Colour: the Ocean palette

One base hue, blue at 245°, for actions, charts and the selected state. Its
complement on the colour wheel, apricot at 65°, is kept for money you keep: the
goal card, the buffer line and savings figures. Sage (on track) and rose (over
the limit) are the only other meaning colours, and each is always paired with a
word or an icon, never used alone.

Everything sits on one blue-grey surface (see [Surfaces](#surfaces)). Dark
mode uses a dark slate rather than black, so shadows still have somewhere
darker to go, and off-white text, following Material's dark theme guidance.
The app follows the phone's setting unless Settings → Appearance picks light
or dark; that choice is a device preference kept in a file of its own
(`theme_mode.dart`), outside the database and backups.
Every text colour passes WCAG AA against both `background` and `well`.

| Token          | Light       | Dark        | Use                                   |
|----------------|-------------|-------------|---------------------------------------|
| `background`   | `#E3E9EF`   | `#1D2329`   | The one surface: screens, cards, sheets |
| `card`         | `#E3E9EF`   | `#1D2329`   | Cards; equal to `background` by design |
| `well`         | `#D7DFE7`   | `#161B20`   | Inputs, tracks, notices, selected keys |
| `highlight`    | white 90%   | white 5%    | Lit edge of a soft surface            |
| `shade`        | `#A3B1C0` 60% | black 90% | Shadowed edge of a soft surface       |
| `ink`          | `#1E2830`   | `#E3E9EE`   | Primary text                          |
| `muted`        | `#545E68`   | `#A3ACB4`   | Secondary text, labels                |
| `line`         | `#D0D9E2`   | `#2B333B`   | Dividers inside cards                 |
| `primary`      | `#0C5F96`   | `#79C0F1`   | Buttons, charts, selection, focus     |
| `onPrimary`    | `#FFFFFF`   | `#031C30`   | Text on primary                       |
| `primarySoft`  | `#D4ECFD`   | `#193043`   | Today's rule chip, tonal buttons      |
| `keepSurface`  | `#FDDFC2`   | `#2D2217`   | Goal number badges                    |
| `keep`         | `#88491A`   | `#EFC093`   | Money kept: text, meters, buffer line |
| `goodSurface`  | `#D0EED5`   | `#1F3724`   | On-track pills                        |
| `good`         | `#2E643B`   | `#9DD8A9`   | On-track text, income amounts         |
| `badSurface`   | `#FFDFDE`   | `#4B2727`   | Over-limit pills                      |
| `bad`          | `#A8383C`   | `#F8A4A3`   | Over-limit text, destructive buttons  |
| `onBad`        | `#FFFFFF`   | `#2A0D0E`   | Text on `bad`                         |

### Tints

Icon backgrounds use eight tints that share one lightness in the OKLCH colour
space, so no category looks louder than another. The theme names them by colour
(`Tint.apricot`, `Tint.sky`, …); each feature maps its own categories onto them.

| Tint      | Fill (light / dark)   | Ink (light / dark)    |
|-----------|-----------------------|-----------------------|
| apricot   | `#FADFC6` / `#473018` | `#8A5619` / `#EFC093` |
| sky       | `#CBE9FF` / `#1B394C` | `#1F6A96` / `#9BD2FA` |
| sage      | `#D0EED5` / `#223D27` | `#337344` / `#A6DAAF` |
| teal      | `#C3EFEB` / `#0D3D3B` | `#007570` / `#8BDCD6` |
| rose      | `#FFD9D8` / `#4C2B2B` | `#944A4B` / `#FBB6B5` |
| pink      | `#FCD9EB` / `#482B3B` | `#8B4A70` / `#F1B6D6` |
| olive     | `#EBE6C4` / `#3B3615` | `#71640B` / `#D6CC8F` |
| neutral   | `#E2E7EB` / `#292F34` | `#606A74` / `#9DA6AE` |

Purple and indigo are deliberately absent.

## Surfaces

bajet is soft UI: nothing is drawn on top of the background, it is moulded out
of it. The light comes from the top left. `core/widgets/soft.dart` holds the
only four ways to do this:

| Widget       | Looks like                       | Used for                               |
|--------------|----------------------------------|----------------------------------------|
| `SoftCard`   | Raised `AppDepth.card` (6 px)    | Every card                             |
| `SoftWell`   | Pressed in `AppDepth.well` (3 px) | Notices, readouts, tracks              |
| `SoftButton` | Raised 3 px, sinks flat on press | Tiles, chips, the + button             |
| `SoftMeter`  | A well with a coloured fill      | Progress toward a goal                 |

A raised surface casts a `highlight` shadow up and left and a `shade` shadow
down and right, each offset by its depth and blurred to twice that. Flutter has
no inset shadow, so `SoftWell` paints one: the blurred outline of everything
outside the shape, nudged inward and clipped to it. Text fields get the same
idea more cheaply from the theme, as a `well` fill with no border.

Depth is decoration, never the only signal, because a shadow drawn from the
background colour cannot reach the 3:1 contrast WCAG 1.4.11 asks of a state:

- A selected tile or chip sits in a well **and** gets a 2 px `primary` outline.
- Segmented buttons fill the selected segment with `primary`.
- A focused `SoftButton` gets a 3 px `primary` ring; text fields outline in
  `primary` on focus and in `bad` on error.
- The main action of a screen stays a solid `primary` button.

## Account cards

Each account is drawn as a card 1.9 times as wide as it is tall
(`cardAspectRatio`), a little wider than a real bank card's 1.59, so cards take
less of the screen; the radius is 16 px (`card_face.dart`). A card is one
colour the owner picked, lit from the top left, under a finish that never
moves: brushed metal (fine vertical streaks), matte or gloss (a fixed
diagonal sheen). Text is dark on light cards and white on dark ones unless
the owner picked its colour, such as gold on black. The provider's name is
plain text, at the top and again as the wordmark; there are no logos or
issuers' card designs, which are trademarks. Cash is a stitched leather
wallet instead, with one to five plain green bills sticking out of the top
as the balance grows (`billsFor`) and none when it is empty. The colours come from the app's own palette (`card_palette.dart`): sixteen
for cards, eight leathers for the wallet, and "Match the app" for the total
card. A card's look is changed from the pencil on its account view, the
total card's by tapping it on Your accounts, and every card's from
Settings → Accounts, which lists them with the total card first. Adding an account (Your accounts → Add an account) asks
whether it is cash, a bank account or an e-wallet, then which bank or
e-wallet from Bank Negara Malaysia's lists (`known_providers.dart`), or any
name typed; a well-known one starts on a swatch near its colour
(`startingSwatch`). "Match my card" takes up to five colours
from a photo of the owner's real card (`commonColours`) to pick from; the
photo is read small, only the chosen colour is saved, and the picker's copy
is deleted at once, so no card number is ever kept. These card
colours are the owner's data, so they are the one place colours do not come
from the theme; the total card, with no colour of its own, takes the app's
surface.

## Type

Figtree, one family, weights 400 to 800, bundled under `assets/fonts/` (SIL OFL
1.1). Amounts always use tabular figures so digits line up and do not shift as
they change.

## Spacing and radii

A 4 pt scale: `AppSpacing.xs` 4, `s` 8, `m` 12, `l` 16, `xl` 20, `xxl` 24,
`xxxl` 32. Radii: `small` 12, `control` 16, `card` 24, `sheet` 30, `pill` 999.
Depth: `AppDepth.card` 6, `control` 3, `well` 3. Cards need at least `l` of
space around them, or their shadows run into each other.

## Motion

| Token              | Value      | Use                                  |
|--------------------|------------|--------------------------------------|
| `AppMotion.ease`   | easeOutQuint | Every transition                   |
| `press`            | 120 ms     | Press-in on buttons and keys         |
| `fast`             | 250 ms     | Toggles, tab indicator               |
| `enter`            | 480 ms     | Cards rising into place, sheets      |
| `stagger`          | 55 ms      | Delay between consecutive cards      |
| `rise`             | 18 px      | Distance a card travels on entry     |

When a screen opens, its cards rise and fade in one after another. `RiseIn`
in `core/widgets/rise_in.dart` does this for any list of cards. Tabs keep their
state, so the shell bumps `screenEntryProvider` on every tab tap and `RiseIn`
keys its entrance on it, replaying it each visit without resetting scroll.
When the system's reduce-motion setting is on (`MediaQuery.disableAnimationsOf`),
all of it is skipped and content appears in place.

### Account cards in motion

The one place the app bounces. Today stacks the total with at most two
accounts peeking out behind it; opening Your accounts flies the stack up
(a shared `Hero`) and springs the cards apart with `Curves.easeOutBack`, each
a little after the one above, folding back without a bounce on the way out.
Tapping a card opens the account view over 700 ms: for the first 300 ms the
card flies from its place and turns from flat to upright (90°, growing to
the upright size, `fastOutSlowIn`, no overshoot) while the page washes over;
neighbours fade in from 50 ms, the name and balance from 300 ms and the dots
from 400 ms. Leaving reverses the flight over 300 ms back to the card's
place, whichever account is showing by then. Swiping follows the motion
study: with `t` pages from the centre, a card coming in from the right turns
`t × 360°` about its upright axis under a 0.0015 perspective and shows its
plain back while facing away, one leaving to the left only slides, and every
card off centre scales by `1 − 0.15|t|` and fades by `1 − 0.4|t|`. The
balance line swaps once the swipe passes halfway, with a selection click.

## Empty screens

A screen with nothing else to show (Insights for an empty period, History,
Coach without a key) fills its space with `EmptyState`: an icon in a round
well, a line saying what is missing, one saying what to do, and the action
that does it. It sits a little above the middle, because true centre looks
low above the bottom bar, and scrolls only when large text no longer fits.
An empty spot inside a busy screen, such as Today's Recent card, stays an
inline line of text where it is.

## Interaction rules

- There is one way to log: the + in the centre of the bottom bar. The sheet
  reads top to bottom as amount, favourites, category, note and day, then a
  Log button that names what it will save. A new entry opens with the amount
  focused on the phone's number pad, filling from the right; the amount and
  the Log button stay in view above it, and only favourites, categories,
  note and day scroll between them. Every money field uses the same number
  pad. Under the note, the day and the receipt sit as a matched pair of
  raised tiles (`DetailTile`); the receipt tile opens a sheet with Camera and
  Photos as large tiles, and once one is attached, a look at it and Remove.
  The day is today unless the owner taps it and picks another
  in the calendar, from the opening date up to today.
- When a planned expense event falls within two weeks of the entry's day, a
  spend can be marked *For* it. The pill then shows what is left of that
  event's budget instead of the day's plan, and the spend stays out of the
  weekly allowance.
- Before saving, a pill says whether the amount fits the day's planned spend
  or how far over it goes. Income and fixed categories get no pill.
- Saving gives a light haptic and a snackbar with Undo.
- Anything that can be added can be changed and removed: tapping a goal,
  event, bill, income, favourite or entry opens its form, with Delete at the
  foot (`DeleteButton`). Deleting always asks first (`confirmDelete`) and
  then offers Undo.
- Tapping Today's stack opens Your accounts. Settings → Balance opens the
  balance sheet: *Match what you really have* goes to the check-in, which
  logs any difference to its account; *Fix the starting balance* rewrites
  one account's opening balance for a figure given wrongly.
- Nothing logs on a single tap or a hold. Favourites fill in the logger; the
  entry is saved only when Log is pressed. The same applies to widget and
  launcher shortcuts: long-pressing the icon offers Log a spend and up to
  three favourites, and the widget shows what is left of the week with a
  Log button and two favourites. Each opens the logger, filled in where it
  names a favourite. The widget never shows the balance, since a home
  screen is seen by anyone holding the phone. Favourites are the owner's own, managed under
  Settings → Favourites and reachable from the logger's Edit link.
- Destructive actions ask for confirmation, then offer undo. In History,
  swiping an entry left asks before deleting it; tapping it edits it in the
  same sheet used for logging.
- Goals are reordered by holding one and dragging it; a drag that starts
  at once would lose the gesture to the page's scrolling. Reorderable lists
  also expose move up and move down to TalkBack. Bought goals move to a Done
  list with their date and price.
- The Sunday check-in compares bajet's balance with the bank. Money missing
  from the bank is logged in one tap as Untracked, with undo; extra money in
  the bank opens the logger as income, filled in, so the owner still picks
  what it was. Today shows a check-in card on Sundays; Settings always links
  to it.
- A report is shared as text, PDF or CSV, picked with radio buttons, for the
  same three periods as Insights. The Share button is pinned to the bottom so
  it stays in view however long the preview runs.
- An entry can carry a receipt, attached in the logger from the camera or the
  gallery and always optional. Entries with one show a small receipt mark;
  the thumbnail in the logger opens it full screen, pinch to zoom.
- Runway's What if… card tries a weekly change in spending, a new monthly
  cost and, when there are any, events not yet counted. The chart and the
  outcome redraw as the levers move, with the difference from the plan in
  words; Reset puts the plan back, and nothing is ever saved. The weekly
  slider runs both ways, so its track is one colour rather than filling from
  the left.
- The coach is a chat with the question box pinned to the bottom and three
  suggested questions while it is empty. The header counts the questions left
  today. A failed question says why (offline, key refused, busy) and offers
  Try again; nothing is counted until an answer arrives. The conversation is
  never stored. Without a key, the tab explains and links to Settings → Coach.
- Touch targets are at least 48 dp.
