# Projection

`lib/features/plan/domain/projection.dart` answers one question: if the plan
holds, how much is left after buying each goal? It is pure Dart with no Flutter
or database imports, so it is tested directly.

## Inputs

| Input            | Meaning                                                        |
|------------------|----------------------------------------------------------------|
| `balance`        | The real balance now, from logged transactions                 |
| `today`          | The day the simulation starts                                  |
| `rules`          | Planned spend for each weekday (the weekly rhythm)             |
| `recurring`      | Monthly bills and income, each with its `nextDue` date         |
| `events`         | One-off planned income or expenses                             |
| `goals`          | Active goals with price, target date and priority              |
| `buffer`         | The minimum that must remain after buying                      |
| `flexSpentToday` | Flexible spending already logged today                         |

All amounts are integer sen. Days are UTC midnights, so stepping a day never
crosses a daylight-saving change.

## Algorithm

From `today` to the latest goal's target date (or 30 days ahead with no goal),
or on to `through` when that is later, for each day. The check-in passes a
day a week ahead, so its target exists even when buy day falls sooner:

1. Subtract that weekday's planned spend. On the first day, subtract only what
   is left of it after `flexSpentToday`, because logged spending is already in
   `balance`.
2. Apply each active recurring item whose day of month matches, from its
   `nextDue` date onward. An item with a window (`windowDays`) counts on the
   window's last day if it is income and its first day if it is a bill, so
   the plan never relies on pay arriving early or a bill going out late.
   On the first day, a bill whose `nextDue` has already passed unpaid is
   charged once for each month missed; late pay is not counted until it is
   marked received.
3. Apply planned events that are not done and are counted in the projection,
   a yearly one on its date in every year up to the end of the window. For
   an expense event's next occurrence only what is left of its budget
   counts, since what was already spent on it has left the balance.
4. Record the balance before goals, then subtract each goal due that day in
   priority order and record what is left.

A goal is **on track** when what is left after buying is at least the buffer.
Each outcome also carries its `RunwaySums`: the balance today, the planned
day-to-day spending, income, and bills and costs up to buy day, and goals
bought before it, which with the price add up exactly to what is left.

## What if

`project` also takes a `WhatIf`, for trying a change on Runway without saving
it:

| Field              | Effect                                                        |
|--------------------|---------------------------------------------------------------|
| `weeklyChange`     | Spread over the week with `spreadOverWeek` and added to each day's planned spend; a day never goes below zero |
| `monthlyCost`      | Subtracted on the 1st of every month after today              |
| `countUnconfirmed` | Planned events marked as not counted are counted too          |

`WhatIf.none` leaves the projection exactly as the plan has it.
`projectionProvider` is always the saved plan; Runway reads
`projectionWithProvider(whatIf)` with the levers' current `whatIfProvider`.

## Why `nextDue` and not "this month"

A bill paid early still falls due later in the same month. Giving each
recurring item the date of its next unpaid occurrence makes the rule exact:
nothing before `nextDue` is charged, and a `nextDue` already behind today is
a bill still owed. Confirming a payment moves `nextDue` forward a month. See [decision 008](decisions.md#008-recurring-items-track-their-next-due-date).

## Live inputs

`projectionProvider` in `features/plan/presentation/plan_providers.dart` feeds
the engine from the database: the balance from the ledger, settings, rhythm,
recurring items, events and active goals from the plan, and today's flexible
spending from recent entries. It returns null until setup is complete and
every stream has loaded, and recalculates whenever any of them changes.

Confirming a recurring item (`PlanRepository.confirmRecurring`) logs a real
entry and moves `nextDue` forward a month in one transaction, so the payment
is never counted twice. It takes the due day the user was shown and does
nothing once that day is no longer the next one, so a second tap, or an old
coach card, never pays it twice.

## On screen

The Runway tab draws the projected series with `RunwayChart`: the balance
line from today, the buffer as a dotted line across, and buy day as a dotted
step from the balance before buying to what is left. Below it sit what is
left after buying against the buffer, a "How it adds up" card listing those
sums (with a prompt to add monthly income when none is planned, since then
none is counted), and `upcoming()`'s bills, income, events and purchases
due before then, under one heading per date with that day's net. The
first four items show, and Show more and Show less open and close the rest.
A List | Calendar switch turns the card into a month grid (`UpcomingCalendar`)
from the first planned month to buy day: a green dot for money in, an ink
dot for money out, buy day ringed, and the items of a tapped day below.

## Tests

`test/features/plan/projection_test.dart` checks the daily series, the buy-day
step, the partial first day, `nextDue`, uncounted events and the no-goal
horizon against values computed independently, using demo figures only.
`test/features/plan/plan_providers_test.dart` runs the same logic end to end
through an in-memory database.
