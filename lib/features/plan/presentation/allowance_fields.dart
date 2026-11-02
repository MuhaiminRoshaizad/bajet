import 'package:flutter/material.dart';

import '../../../core/widgets/money_field.dart';

/// The weekly allowance, as setup and Settings both ask for it.
class AllowanceField extends StatelessWidget {
  const AllowanceField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => MoneyField(
        controller: controller,
        label: 'Weekly allowance, for your own calls',
        hint: 'e.g. 50.00',
        helper: 'What you let yourself spend Monday to Sunday when it is your call: food, transport and extras. Spending that is not your call, and bills, do not count.',
        validator: (sen) => sen > 0 ? null : 'Enter how much you allow each week',
      );
}

/// What to set aside each month for needs, so Runway plans for them.
class NeedsReserveField extends StatelessWidget {
  const NeedsReserveField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => MoneyField(
        controller: controller,
        label: 'Not my call, a month (optional)',
        hint: 'e.g. 80.00',
        helper: 'Set aside for spending you have no real say in. Runway takes it off each month. Leave empty for none.',
      );
}

/// The least to keep after buying a goal, as setup and Settings both ask
/// for it. It ends the form, so the keyboard's action is Done.
class BufferField extends StatelessWidget {
  const BufferField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => MoneyField(
        controller: controller,
        label: 'Keep at least (optional)',
        hint: 'e.g. 1,000.00',
        helper: 'The least you want left in your account after buying a goal. A goal is on track only if this much remains. Leave empty for none.',
        textInputAction: TextInputAction.done,
      );
}
