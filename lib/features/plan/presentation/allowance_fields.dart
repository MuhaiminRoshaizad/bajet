import 'package:flutter/material.dart';

import '../../../core/widgets/money_field.dart';

/// The weekly allowance, as setup and Settings both ask for it.
class AllowanceField extends StatelessWidget {
  const AllowanceField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => MoneyField(
        controller: controller,
        label: 'Weekly allowance',
        hint: 'e.g. 50.00',
        helper: 'What you let yourself spend Monday to Sunday on food, transport and extras. Bills and other fixed costs do not count.',
        validator: (sen) => sen > 0 ? null : 'Enter how much you allow each week',
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
