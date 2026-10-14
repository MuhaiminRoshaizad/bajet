# Design system

Everything visual in bajet comes from the tokens in `lib/core/theme/`. Widgets
never use a raw colour, padding number or duration.

## Colour: the Ocean palette

One base hue, blue at 245°, for actions, charts and the selected state. Its
complement on the colour wheel, apricot at 65°, is kept for money you keep: the
goal card, the buffer line and savings figures. Sage (on track) and rose (over
the limit) are the only other meaning colours, and each is always paired with a
word or an icon, never used alone.

Contrast is deliberately softer than black on white (about 14:1 rather than
21:1), and dark mode uses a dark grey base with off-white text, following
Material's dark theme guidance. Every text pairing below passes WCAG AA.

| Token          | Light     | Dark      | Use                                   |
|----------------|-----------|-----------|---------------------------------------|
| `background`   | `#F3F7FA` | `#101418` | Screen background                     |
| `card`         | `#FFFFFF` | `#191F23` | Cards, sheets                         |
| `ink`          | `#1E2830` | `#E3E9EE` | Primary text                          |
| `muted`        | `#606A74` | `#9DA6AE` | Secondary text, labels                |
| `line`         | `#E2E7EB` | `#292F34` | Dividers, borders                     |
| `primary`      | `#0F68A2` | `#79C0F1` | Buttons, charts, selection            |
| `onPrimary`    | `#FFFFFF` | `#031C30` | Text on primary                       |
| `primarySoft`  | `#D4ECFD` | `#193043` | Tinted cards, selected tabs           |
| `keepSurface`  | `#FDDFC2` | `#2D2217` | Goal card                             |
| `keep`         | `#925019` | `#EFC093` | Money kept: text, meters, buffer line |
| `goodSurface`  | `#D0EED5` | `#1F3724` | On-track pills                        |
| `good`         | `#31693F` | `#9DD8A9` | On-track text, income amounts         |
| `badSurface`   | `#FFDFDE` | `#4B2727` | Over-limit pills                      |
| `bad`          | `#AF3C40` | `#F8A4A3` | Over-limit text                       |

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

## Type

Figtree, one family, weights 400 to 800, bundled under `assets/fonts/` (SIL OFL
1.1). Amounts always use tabular figures so digits line up and do not shift as
they change.

## Spacing and radii

A 4 pt scale: `AppSpacing.xs` 4, `s` 8, `m` 12, `l` 16, `xl` 20, `xxl` 24,
`xxxl` 32. Radii: `small` 12, `control` 16, `card` 24, `sheet` 30, `pill` 999.

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

## Interaction rules

- There is one way to log: the + in the centre of the bottom bar. The sheet
  reads top to bottom as amount, favourites, category, note and day, keypad,
  then a Log button that stays visible and names what it will save.
- Before saving, a pill says whether the amount fits the day's planned spend
  or how far over it goes. Income and fixed categories get no pill.
- Saving gives a light haptic and a snackbar with Undo.
- Nothing logs on a single tap or a hold. Favourites fill in the logger; the
  entry is saved only when Log is pressed. The same applies to widget and
  launcher shortcuts.
- Destructive actions ask for confirmation, then offer undo. In History,
  swiping an entry left asks before deleting it; tapping it edits it in the
  same sheet used for logging.
- Touch targets are at least 48 dp.
