/// Short tips on wants, needs and the plan, one a week on Insights. Written
/// into the app, so they need no internet.
const tips = [
  'Plans slip on the spending nobody planned for: something runs out, or family asks for help. '
      'A little set aside each month keeps the rest of your plan standing.',
  'Not sure if it is a want? Ask: could I have skipped it, or waited a few weeks, without harm? If so, it is a want.',
  'Food is a need, but eating out is usually a want: where you eat and how much it costs is your choice.',
  'Needs do not count toward your allowance, but they still leave your balance. '
      'If your balance falls faster than the dial, look at Needs under it on Today.',
  'A treat you plan for is easier to enjoy. Give it room in a day of Weekly rhythm and it stops being a surprise.',
  'Something big coming up? Add it as a planned event, so Runway counts it before the day comes.',
  'Waiting a day before a want you did not plan gives you time to decide whether you still want it.',
  'A bill paid from its tile in the log sheet stays out of your allowance, whatever its category.',
  'Small wants add up: RM5 a day is RM150 over a 30-day month.',
  'Matching your bank on Sundays finds money that went unlogged, so your week stays honest.',
  'Logging right after you pay takes seconds; logging at night means guessing.',
  'A need that comes every month, such as a phone plan, is better as a bill: Runway then counts it ahead.',
];

/// This week's tip: a new one each Monday, going round the list.
String tipFor(DateTime day) => tips[_weeksSinceFirstMonday(day) % tips.length];

/// Weeks since Monday 5 January 1970, the first Monday of the epoch.
int _weeksSinceFirstMonday(DateTime day) => DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(1970, 1, 5)).inDays ~/ 7;
