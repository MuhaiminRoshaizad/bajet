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
ways to do this:

| Widget       | Looks like                       | Used for                               |
|--------------|----------------------------------|----------------------------------------|
| `SoftCard`   | Raised `AppDepth.card` (6 px)    | Every card                             |
| `SoftWell`   | Pressed in `AppDepth.well` (3 px) | Notices, readouts, tracks              |
| `SoftButton` | Raised 3 px, sinks flat on press | Tiles, chips, quieter round buttons    |
| `SoftMeter`  | A well with a coloured fill      | Progress toward a goal                 |
| `MouldedButton` | A blue disc shaded by the same light | The + that logs                  |

A raised surface casts a `highlight` shadow up and left and a `shade` shadow
down and right, each offset by its depth and blurred to twice that. Flutter has
no inset shadow, so `SoftWell` paints one: the blurred outline of everything
outside the shape, nudged inward and clipped to it. Text fields get the same
idea more cheaply from the theme, as a `well` fill with no border.

A filled button is the one thing not the background's colour, so a flat fill
would sit on the page like a sticker. `MouldedButton` shades the primary blue
instead: `primaryLit` at the top left, `primary` in the middle and
`primaryDeep` at the bottom right, one OKLCH lightness step either side
(±0.08), the lit side 6° warmer and the shaded side 6° cooler, as light warms
what it touches. Its shadow, `mouldShadows`, is a deep blue on the light page
and near black on the dark one, where a blue glow would read as light.
An icon on it in `onPrimary` clears 4.5:1 across the whole fill in both themes.

Depth is decoration, never the only signal, because a shadow drawn from the
background colour cannot reach the 3:1 contrast WCAG 1.4.11 asks of a state:

- A selected tile or chip sits in a well **and** gets a 2 px `primary` outline.
- Segmented buttons fill the selected segment with `primary`.
- A focused `SoftButton` gets a 3 px `primary` ring; text fields outline in
  `primary` on focus and in `bad` on error.
- The main action of a screen stays a solid `primary` button.

### The bottom bar

The bar floats: a soft pill holding the four tabs and, beside it, the
moulded + that logs. Nothing fills the space around them, so the page shows
on every side and scrolls on underneath (`extendBody`). Each tab's list ends
with `underBar` of room, so its last row scrolls clear of the bar. The open
tab is pressed into the pill as a hollow that springs across to the next tab
(`AppMotion.spring`), and the opened tab's icon gives one small bounce.
Springing to the first or last tab, its overshoot squashes it against the
end of the pill, by up to a third of its width, instead of carrying it out
of the pill. Each tab sits in the middle of its hollow. The
pill's own shadow (`floatingShadows`) keeps it apart from the cards passing
beneath. On a tablet the bar keeps a phone's width. It never hides while
scrolling, so logging stays one tap away.

## Account cards

Each account is drawn as a card 1.9 times as wide as it is tall
(`cardAspectRatio`), a little wider than a real bank card's 1.59, so cards take
less of the screen; the radius is 16 px (`card_face.dart`). A card is one
colour the user picked, lit from the top left, under one of six finishes
(`card_finishes.dart`): matte, gloss (a fixed diagonal sheen), mirror (a
bright band of polished metal), pearl (a milky pink-to-blue shimmer),
frosted glass (fine frost with an etched edge) or guilloché (engraved
waves, like a banknote's). Mirror and pearl catch the light as the card
turns: their shine follows a tilt from -1 to 1, which comes from the swipe
between cards on the account view, from scrolling Your accounts, and from
a finger dragged across the designer's preview; there is no motion sensor.
Only those two repaint when it changes (`finishMoves`), and the frost and
suede textures are small squares made once and tiled. Text is dark on light cards and white on dark ones unless
the user picked its colour, such as gold on black. The provider's name is
plain text, at the top and again as the wordmark; there are no logos or
issuers' card designs, which are trademarks. Cash is a stitched leather or suede
wallet instead, with one to five plain green bills sticking out of the top
as the balance grows (`billsFor`) and none when it is empty. The colours come from the app's own palette (`card_palette.dart`): sixteen
for cards, eight leathers for the wallet, and "Match the app" for the total
card. A card's look is changed from the pencil on its account view, the
total card's by tapping it on Your accounts, and every card's from
Settings → Accounts, which lists them with the total card first. Adding an account (Your accounts → Add an account) asks
whether it is cash, a bank account or an e-wallet, then which bank or
e-wallet, from a searchable dropdown (`ProviderPicker`) of Bank Negara
Malaysia's lists grouped as most used, digital and other banks
(`known_providers.dart`), each with a dot in its starting colour. Typing
filters it; a name not listed is used from its last row ("Not listed? Use
…") or simply left typed. A well-known one starts on a swatch near its
colour (`startingSwatch`). The sheet goes in the order it is filled in:
provider, amount, nickname, then finish, colour and photo match, with its
Add or Save button pinned below the scroll. "Match my card" (or "Match my
wallet") asks, with two large buttons, to take or choose a photo of the
user's real card, then shows it full screen (`PhotoMatchScreen`) with a
card-shaped frame, 80% of the photo's width and 1.9 times as wide as tall.
The three most common colours inside the frame (`commonColours`) are offered
first, and a tap or drag anywhere takes the colour under the finger,
averaged over the pixels around it and shown in a magnifier held above it,
with a selection click as it changes. The photo is read at most 480 px on
its long side and held in memory only; only the chosen colour is saved, and
the picker's copy is deleted at once, so no card number is ever kept. These card
colours are the user's data, so they are the one place colours do not come
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
| `spring`           | stiffness 180, damping 0.6 | A shape settling on a new value |

When a screen opens, its cards rise and fade in one after another. `RiseIn`
in `core/widgets/rise_in.dart` does this for any list of cards. Tabs keep their
state, so the shell bumps `screenEntryProvider` on every tab tap and `RiseIn`
keys its entrance on it, replaying it each visit without resetting scroll.
When the system's reduce-motion setting is on (`MediaQuery.disableAnimationsOf`),
all of it is skipped and content appears in place.

A chart that changes value settles on it with `AppMotion.spring`, passing it
by about a tenth first, like a needle with some weight: Insights' category
ring swells a touch past its size as it sweeps in, and the week dial on Today
springs past a newly logged amount, glows over the stretch just added for
500 ms, and dips to 0.97 as if pressed before springing back. Its arc and
figures fade to rose over `fast` once the week is ahead of its plan. Figures written in words
never overshoot, since a number that reads wrong for a moment is a wrong
number.

The coach has a face (`CoachAvatar`): the titanium orb bajety, in the total
card's own shades with a graphite face, or one of three finance people,
Aina, Hafiz and Mei, drawn in code. Each mood (idle, thinking, happy,
concerned, cheer, hello, stare) morphs its mouth, brows and eyes from the
last over 420 ms with `easeOutBack`, and every change starts with a jelly
wobble on a looser spring than the app's (damping 0.42, stiffness 220).
Happy and cheer hop, concerned shakes, cheer sparkles, thinking floats a
thought bubble or circling sparks, and a tap says hello. At rest it breathes
and blinks every three to five seconds, and stops after a minute with
nothing happening. It sits in its own `RepaintBoundary`; with reduce motion
on, or `animate` off, it is a still picture. The people's skin, hair and clothes are artwork in fixed colours,
like a card's face, on a background tint from the theme.

A coach given a `CoachAttention` also notices the user. Its eyes glance
where the attention looks, on a quick spring with barely any overshoot
(stiffness 140, damping 0.75), on top of whatever the mood is doing, and a
nudge squashes it into one jelly wobble. `ScrollAttention` feeds it from a
scrolling list: the faces look the way the page moves, further the faster
it goes up to `ScrollAttention.fast` (900 px/s), look ahead again when it
stops, and wobble once after a fling. Inside a chat the coach at the top
looks up as the user scrolls back through older messages, and down at the
question box while they type, until the question is sent. A still coach
notices nothing.

### Chats with the coach

The Coach tab is a list of chats, as a messaging app keeps them: pinned
ones first, then the most recent, each with its coach's face, its name,
when it was last used (`14:05`, `Yesterday`, `Sat`, `17/10`) and its last
line. A chat that has something new said in it springs into its place at
the top. Search finds chats by name or by anything said in them. A soft
round button above the log button, centred on it and the lighter of the
two, starts a new chat, which opens on its own page over the bottom bar
and is dropped if it is left before anything is asked. A chat opens at its
newest message, beside the question box, with older ones above; the list
is laid out from the bottom, so it is there from the first frame rather
than scrolled to. Each new message is brought into view: a reply taller
than the chat stops with its first line under the header, to be read
down from there, and anything shorter lands at the bottom. Holding a chat, or
the ⋮ inside it, pins, renames or deletes it; delete asks first and offers
Undo. The list's own ⋮ copies the week's summary and opens Coach settings.
Each chat keeps its own coach and personality. The top of a chat shows
who is talking and how, the coach's name with the personality under it
(`thinking…` while an answer comes), and tapping it, or Chat settings in
its ⋮, opens the chat's settings: the four coaches in a row, the one in use
pressed into the surface, and the six personalities. Changing the coach is
said in the chat by the new coach's hello; changing the personality leaves
a short note line, such as `bajety is now Strict`, which the model is never
sent. Coach settings holds the coach and personality new chats start with.
Both sides of the chat have a tail at the bottom corner nearest the
speaker, the user's on the right and the coach's on the left. A reply has
no face beside it, since the coach is named at the top, so it takes the
full width.
The coach writes in Markdown, and a reply is drawn as it reads
(`CoachReplyText`, from `parseReply`): bold and italic where it marked
them, a heading as a bold line, and lists with real bullets or numbers
hanging beside their wrapped lines. Links, code, quotes and rules keep
their words and lose their marks. Only the look changes; the coach's
instructions say nothing about formatting, so its voice is its own. The
user's own messages are shown exactly as typed.
Sheets a tab opens go over the bottom bar (`useRootNavigator`), or their
last rows would sit beneath it.

Every avatar keeps at least 3:1 against the page in both themes (WCAG 1.4.11,
non-text contrast), since the tints and the orb's lit silver are within a
shade of the page on their own. The orb is drawn one titanium step deeper on
the light page (F4F6F8 / C3C8CE / 8A9199 / 535960) with a 7A818A rim, 3.2:1;
on the dark page it keeps the card's shades with a 9AA0A8 rim, 6:1. A
person's circle gets a ring in its own hue, the tint's ink mixed into its
fill (80% on light, 60% on dark), about 3:1 and 5:1. Sparkles, thought
puffs and the orbiting spark are white on dark and the muted ink on light.

Insights shows where the money went as a ring (`CategoryRing`): every
category of money out, fixed ones labelled Fixed, the total in the middle and
a key with each one's amount and share. Slices take their colours by size, so
neighbours never match; past six, the smallest share one "Everything else".

### Account cards in motion

Where the app bounces most. Today stacks the total with at most two
accounts peeking out behind it. Your accounts leaves the total on Today and
shows every account overlapped like a wallet, each with a strip for its name
and balance (wider above a cash wallet, so its bills never cover a balance);
arriving, the total lifts away and fades while the cards slide out from
behind it, from exactly where they sat in Today's stack, down into their
strips, each a little after the one above (`Curves.easeOutBack`); leaving,
they slide back behind it without a bounce. Today's stack hides while its
cards are away (`accountsOnTopProvider`), so no card is ever seen twice.
Pressing and holding Today's stack or a card here (`HoldSwell`) swells it to
×1.06 and raises it 4 px after 140 ms, with a light haptic tick
(`easeOutBack`, 260 ms), then a firmer tick 420 ms later; it springs back
over 380 ms when let go or when the finger moves. A press counts as a hold,
not a tap, only once the firmer tick has come; that tick is a long press,
so it takes the finger from the scroll. On Your accounts it picks the card
up: it lifts to ×1.08, the other cards dim to 82%, and a dashed outline
marks its slot. Dragged up or down, it rides over the others, which slide
out of its way over 220 ms with a selection click each; let go, it settles
into the slot and the order is saved (`reorderAccounts`), with no Done
button. That one order drives Today's peeking cards and dots, Your
accounts, the swipe between cards and every account picker. Today's stack
only swells and ticks; it is never picked up. Scrolling opens them downward:
the first 220 px of scroll are held, so the top card stays put while the
cards below drop away until each is whole with a 14 px gap, and only then
does the page scroll (`AccountListLayout`). Tapping a card opens the
account view over 700 ms, and every card flies, one copy of each, while the
list's own copies hide. For the first 300 ms the tapped card flies from its
place and turns from flat to upright (90°, growing to the upright size,
`fastOutSlowIn`, no overshoot) while the page washes over; the cards beside
it glide a beat behind to the edges where the page shows them, smaller and
faded, and the rest slide away down. The name and balance fade in from
300 ms and the dots from 400 ms. Leaving reverses the flight over 300 ms,
every card back to its own place, whichever account is showing by then. Swiping follows the motion
study: with `t` pages from the centre, a card coming in from the right turns
`t × 360°` about its upright axis under a 0.0015 perspective and shows its
plain back while facing away, one leaving to the left only slides, and every
card off centre scales by `1 − 0.15|t|` and fades by `1 − 0.4|t|`. The
balance line swaps once the swipe passes halfway, with a selection click.
Below the card screen's buttons, a scroll away under a pinned top bar, is
the showing account's activity (`AccountActivity`): its latest 20 entries
and transfers, newest first, each transfer signed from this account's side
("Moved to Cash −RM20.00", "Moved from Bank +RM50.00").

## App icon

Three cards fanned like a hand, on a graphite tile that is a little lighter
at the top (`#1F232A` to `#121418`). The cards step in lightness from back to
front, gunmetal `#5F656D`, steel `#9AA0A8` and titanium `#D8DBDF`, so they part
by lightness alone with no second hue. The front card carries a chip and a
line engraved in the tile colour. They turn −20°, 0° and 20° about a point
below them, and the fan drops 4.65 dp so its centre of mass sits on the
icon's centre, inside the 66 dp circle every launcher keeps whole.

Android 8 and later draw it from vectors (`res/drawable/ic_launcher_*.xml`,
`mipmap-anydpi-v26/ic_launcher.xml`); the themed-icon layer separates the
cards by opacity, since the system tints it one colour. Older phones use
the PNGs in `mipmap-*dpi`, rendered from the same drawing.

## Opening

A cold start opens in two parts, timed in `OpeningTimes`
(`features/opening/domain`). First, Android's own splash plays the deal
the moment the icon is tapped, within a second: the front titanium card
pops in with a tilt, a second and third slide out from behind it to the
lower left, all three spring into the icon's fan, swinging to 1.42 of
their angle and back twice, and "bajet" rises letter by letter over a
titanium line that draws out from the middle. That animation
(`res/drawable-v31/splash_deal.xml`) is generated from the same timeline,
and a test fails if they drift apart. Then bajet draws the same fan in the
same place and has Android's splash taken away: the word lifts off and the
cards arc into Today's stack, front card onto the total, or land small on
the lock screen's fan. Today's entrance waits for them (`EntranceHold`).
Easing is the soft `Cubic(.33, 0, .3, 1)` throughout, with the keyframes
doing the bouncing.

Android keeps only a circle 192 dp across of its splash in view, so the
whole opening is drawn at `OpeningPlan.zoom` (0.82) of the mock-up's size.
Phones older than Android 12 have no animated splash; there bajet plays
the deal itself after a plain graphite launch screen. A tap skips the
hand-over, and with the system's remove animations setting on nothing
moves.

Unlocking plays the same flight the other way round (`UnlockPlan`,
`features/lock/domain`). Once the fingerprint passes, the app goes to
Today, the lock screen's words fade and sink, its fan's three cards arc
into Today's stack front card first, turning into the real cards on the
way down, and the lock's background lifts under them. It takes under 0.9
seconds. With no accounts to stack, the fan fades where it is. A tap lands
at once, and with remove animations on the lock simply goes.

## Empty screens

A screen with nothing else to show (Insights for an empty period, History,
Coach without a key) fills its space with `EmptyState`: an icon in a round
well, a line saying what is missing, one saying what to do, and the action
that does it. It sits a little above the middle, because true centre looks
low above the bottom bar, and scrolls only when large text no longer fits.
An empty spot inside a busy screen, such as Today's Recent card, stays an
inline line of text where it is.

## Interaction rules

- Back at the top of the app never closes bajet by surprise
  (`LeaveGuard`): on Runway, Insights or Coach it goes to Today, and on
  Today it asks "Leave bajet?" under the app icon, saying what App lock
  will ask for on the way back in. Stay is the text button and Leave the
  filled one, not the warning colour, since leaving loses nothing. Back
  inside a screen or a sheet goes back as usual. Catching Back on Today
  gives up Android's back-to-home preview there.
- A header's ⋮ (`SpringMenuButton`) holds what does not need a button of
  its own on that screen. Its menu grows out of the button's corner on
  `easeOutBack`, passing its size a little before it settles, and closes on
  a tap outside; a choice that removes something is in the warning colour.
- Tapping anywhere outside the field being typed in puts the keyboard
  away, on every screen and sheet (`DismissKeyboardOnTap`, set once on the
  app); a drag that starts outside it, such as a scroll, leaves it up.
- There is one way to log: the + beside the tabs in the bottom bar. The sheet
  reads top to bottom as amount, favourites, category, note and day, then a
  Log button that names what it will save. A new entry opens with the amount
  focused on the phone's number pad, filling from the right; the amount and
  the Log button stay in view above it, and only favourites, categories,
  note and day scroll between them. Every money field uses the same number
  pad. Under the note, the day and the receipt sit as a matched pair of
  raised tiles (`DetailTile`); the receipt tile opens a sheet with Camera and
  Photos as large tiles, and once one is attached, a look at it and Remove.
  The day is today unless the user taps it and picks another
  in the calendar, any day of the past year up to today. A day before the
  opening date shows a line under the tiles saying it counts in that week
  and Insights but not in the balance (decision 020).
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
- An account is deleted from the foot of its Edit card sheet. One with
  history asks where that goes, moving it to another account by default so
  no past figure changes; *Delete them too* names the bills it takes. From
  the card page, the page closes first so the card leaves Your accounts in
  view. The last account's Delete is disabled, with the reason under it.
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
  screen is seen by anyone holding the phone. Favourites are the user's own, managed under
  Settings → Favourites and reachable from the logger's Edit link.
- Destructive actions ask for confirmation, then offer undo. In History,
  swiping an entry left asks before deleting it; tapping it edits it in the
  same sheet used for logging. Money moved between accounts shows there too,
  in its own primary-blue row ("Bank → Cash", "Moved, not spent") under its
  day, never counted in that day's spending; swiping one left deletes it,
  with undo.
- Goals are reordered by holding one and dragging it; a drag that starts
  at once would lose the gesture to the page's scrolling. Reorderable lists
  also expose move up and move down to TalkBack. Bought goals move to a Done
  list with their date and price.
- The Sunday check-in compares bajet's balance with the bank. Money missing
  from the bank is logged in one tap as Untracked, with undo; extra money in
  the bank opens the logger as income, filled in, so the user still picks
  what it was. Today shows a check-in card on Sundays; Settings always links
  to it.
- Insights and the report pick their range with `PeriodPicker`: Week, Month
  or All, and under Week or Month one arrow row that steps back as far as the
  week or month of the first day logged and forward to the current one. Away
  from the current one, the row's middle says "Back to this week" (or month)
  and jumps there. Switching between Week and Month lands on the current one.
  Content slides 24 points in from the side it came from (`PeriodSlide`,
  `AppMotion.fast`). A past period is whole; only the current one says "so
  far". Its habits are judged against today's rhythm, the only one kept.
- A report is shared as text, PDF or CSV, picked with radio buttons, for the
  same ranges as Insights; opened from Insights it starts on the range shown.
  The Share button is pinned to the bottom so it stays in view however long
  the preview runs. Every format names each entry's account and lists money
  out by every category, fixed ones marked; with two or more accounts, text
  and PDF also give each account's money in and out for the period and what
  it holds now (`byAccount`). Moves between the user's own accounts are
  neither in nor out. The balance shown is today's, whatever the period.
  Lines with nothing to say, such as Fixed RM0.00, are left out, and a week
  shows no Kept or "Spent more than came in", since a week rarely holds a
  payday.
- The current week is reported as the weekly check-in (`weeklyCheckin`),
  verdict first: the week against the target the last check-in saved for
  today, "In progress" before that day comes, or "Baseline set" with no
  target coming, and the goal judged apart from it,
  then the week's spending against the allowance, finished days within plan
  (today counts once it is over), the rhythm's rules kept or missed, the
  goal, the next seven days and anything flagged. Lines with nothing to say
  are left out. A fasting day is kept when nothing is spent on Food that
  day; transport and bills do not break it.
- The check-in's PDF (`checkinDocument`) is A4 in the light palette, led by
  the app icon (`AppIconTile`) and with the coach's face beside the verdict,
  happy on track, concerned when short. Both are the app's own widgets drawn
  off screen (`widgetToPng`) in the light theme, since paper is light. The
  summary comes first in blocks that never split across pages; the entries
  follow and run on to more pages with their title and column names
  repeated, never splitting a row.
- This week can also be shared as an image (`CheckinCard`), a 4:5 card in
  the app's current theme, light or dark, shared as 1080 × 1350 pixels: the
  week's spending against the allowance, a dot a day (filled within plan, a
  ring for a day with nothing spent, red over plan, dashed for today, with a
  small mark on a fasting day), fasting kept, untracked money, and the goal's
  days to go and how far the week moved it. The preview springs in
  (`SpringIn`) when Image is picked. The app icon carries a hairline in the
  theme's line colour so the graphite tile stays clear of a dark card.
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
  suggested questions while it is empty. The header shows the coach's face
  and name over its personality; tapping it opens Choose your coach, a sheet
  of the four faces that switches the look only, after which the new face
  says hello in the chat. Picking bajety offers Sees Everything. An empty
  chat greets with a large face. Replies carry the face that gave them,
  once per run, and the face reacts: thinking while waiting, happy at an
  answer, concerned (or staring, for Sees Everything) at a message turned
  away, cheering when a card is confirmed. The header also counts the
  questions left today.
- A message springs in on `AppMotion.spring` from 24 pt below at 0.55 of
  its size, growing out of its own side, whenever it comes into view: when
  it is said, and each time scrolling brings it back on screen. Messages
  are built only as they come into view so the spring is seen. What is on
  screen as the chat opens is simply there. While the
  coach works, a reply bubble reads "Thinking", then "Looking at: July
  2026" for each lookup, worded as the reply's "Looked at:" line, with three
  bobbing dots after the words standing in for their "…". The bubble
  springs to the width of each new status. Reduce motion turns both into plain
  appearances. A failed question says why (offline, key refused, busy) and offers
  Try again; nothing is counted until an answer arrives. It is one ongoing
  chat, not separate sessions: with memory on (the default) it is still there
  after a restart, with "Remembered on this phone only" at the top and a day
  label (Today, Yesterday, Sat 17/10) above the first message of each day.
  Settings → Coach has the Remember our chats switch and Forget everything,
  which asks first and offers Undo. Each reply's footer, under a hairline inside its bubble,
  says "Looked at:" and names what the coach looked up for it, such as
  "This week · September 2026". Without a key, the tab
  explains and links to Settings → Coach.
- Settings → Coach puts the key first, since nothing works without it, then
  the personality as a radio list: each option's name, one line about it,
  and what it would say about the same RM45 of bubble tea, so the
  difference shows rather than being described.
- A message the coach will not take, such as asking for code, or a question
  asked again within a minute, gets a reply in the chosen personality's own
  voice straight away, without the typing wait, and it grows firmer the more
  it is pushed. These replies cost nothing and leave the day's count alone.
- A change the coach suggests arrives as a card under its reply: the
  question ("Log this spend?"), the amount large, then what, from which
  account and which day, with Not now and the action (Log it, Move it, Mark
  paid). Nothing is written until the action is tapped. A done card turns
  green with a tick and offers Undo, except a bill marked paid; a declined
  or undone card fades and stays in the chat as a record.
- Touch targets are at least 48 dp.
