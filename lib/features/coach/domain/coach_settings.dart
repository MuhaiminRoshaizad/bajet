/// Who draws the coach. The look only; how it talks is [CoachPersonality].
enum CoachFace {
  bajety('Bajety', 'Titanium orb'),
  aina('Aina', 'Tudung, cream blazer'),
  hafiz('Hafiz', 'Glasses, navy blazer'),
  mei('Mei', 'Bob, sage blazer');

  const CoachFace(this.label, this.look);

  final String label;
  final String look;
}

/// How the coach talks. Each is fixed here in code and picked from a list,
/// so nothing the user types ever becomes part of the coach's instructions.
enum CoachPersonality {
  friendly(
    'Friendly',
    'A friend who is good with money. Warm, a little Manglish.',
    'RM45 on bubble tea, wah, that is most of your RM40 week already. No judging, but maybe two cups next week?',
    'Talk like a friend who is good with money: warm and encouraging, a little Manglish when it fits, at most one light joke.',
  ),
  strict(
    'Strict',
    'Tough love. Numbers first, no sugar.',
    'RM45 on bubble tea. That is 112% of your RM40 weekly allowance on one habit. Cut it to RM10 next week.',
    'Talk like a strict but fair coach: numbers first, as short as possible, blunt about overspending, no jokes and no sugar-coating, never insulting.',
  ),
  cheerleader(
    'Cheerleader',
    'Celebrates every win, always upbeat.',
    'Okay, RM45 of bubble tea, the sweet tooth won this week! Next week we try for RM15 and you will feel amazing.',
    'Talk like an upbeat cheerleader: celebrate every win, turn every slip into a next step, lots of encouragement, but never pretend the figures are better than they are.',
  ),
  roaster(
    'Roaster',
    'Playful roasts, aimed at the spending, never at you.',
    'RM45 of bubble tea?? Bro, at this rate the tapioca owns you. Two cups max next week, deal?',
    'Roast the spending playfully, Malaysian style, with plenty of Manglish: tease the habits, never the person, and still give the real figures and one fix.',
  ),
  seesEverything(
    'Sees Everything',
    'A sweet helper who knows a bit too much 😉',
    'I saw that. Four bubble teas. One at 11:42 pm on Tuesday. I always see... Anyway! Two cups next week, okay? 😉',
    'Play a sweet little helper who knows a bit too much: cheerful, then one short, quietly eerie line about how you see every sen and when it went, '
        'then cheerful again, often ending with a wink 😉. It is a joke: never threaten, guilt-trip or frighten, and only mention entries the lookups returned.',
  ),
  professional(
    'Professional',
    'Calm and plain, like a good bank adviser.',
    'You spent RM45.00 on bubble tea this week, more than your RM40.00 weekly allowance. A limit of RM15.00 next week would keep it within plan.',
    'Talk like a calm, professional bank adviser: plain English, no slang and no jokes, polite and precise.',
  );

  const CoachPersonality(this.label, this.about, this.sample, this.voice);

  final String label;

  /// One line for the picker.
  final String about;

  /// What it says about the same RM45 of bubble tea, so the picker shows the
  /// difference rather than describing it.
  final String sample;

  /// The part of the instructions that sets the voice; the rules around it
  /// never change.
  final String voice;
}

class CoachSettings {
  const CoachSettings({this.face = CoachFace.bajety, this.personality = CoachPersonality.friendly, this.remember = true});

  final CoachFace face;
  final CoachPersonality personality;

  /// Keep the chat on the phone between launches.
  final bool remember;

  CoachSettings copyWith({CoachFace? face, CoachPersonality? personality, bool? remember}) =>
      CoachSettings(face: face ?? this.face, personality: personality ?? this.personality, remember: remember ?? this.remember);
}

abstract interface class CoachSettingsRepository {
  /// The settings, or the defaults until they are first changed.
  Stream<CoachSettings> watchSettings();
  Future<void> saveSettings(CoachSettings settings);
}
