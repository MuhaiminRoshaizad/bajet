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
for each day:

1. Subtract that weekday's planned spend. On the first day, subtract only what
   is left of it after `flexSpentToday`, because logged spending is already in
   `balance`.
2. Apply each active recurring item whose day of month matches, from its
   `nextDue` date onward.
3. Apply planned events that are not done and are counted in the projection.
4. Record the balance before goals, then subtract each goal due that day in
   priority order and record what is left.

A goal is **on track** when what is left after buying is at least the buffer.

## Why `nextDue` and not "this month"

A bill paid early still falls due later in the same month. Giving each
recurring item the date of its next unpaid occurrence makes the rule exact:
nothing before `nextDue` is charged. Confirming a payment moves `nextDue`
forward a month. See [decision 008](decisions.md#008-recurring-items-track-their-next-due-date).

## Live inputs

`projectionProvider` in `features/plan/presentation/plan_providers.dart` feeds
the engine from the database: the balance from the ledger, settings, rhythm,
recurring items, events and active goals from the plan, and today's flexible
spending from recent entries. It returns null until setup is complete and
every stream has loaded, and recalculates whenever any of them changes.

Confirming a recurring item (`PlanRepository.confirmRecurring`) logs a real
entry and moves `nextDue` forward a month in one transaction, so the payment
is never counted twice.

## On screen

The Runway tab draws the projected series with `RunwayChart`: the balance
line from today, the buffer as a dotted line across, and buy day as a dotted
step from the balance before buying to what is left. Below it sit what is
left after buying against the buffer, and `upcoming()`'s list of bills,
income, events and purchases due before then.

## Tests

`test/features/plan/projection_test.dart` checks the daily series, the buy-day
step, the partial first day, `nextDue`, uncounted events and the no-goal
horizon against values computed independently, using demo figures only.
`test/features/plan/plan_providers_test.dart` runs the same logic end to end
through an in-memory database.
