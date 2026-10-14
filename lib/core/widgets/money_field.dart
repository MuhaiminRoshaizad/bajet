import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../validation/ringgit_cents_formatter.dart';

/// A labelled money field that fills from the right. It validates when the
/// user leaves it with something typed, then re-checks on every keystroke
/// once an error shows, so the message clears the moment the value is fixed.
class MoneyField extends StatefulWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.helper,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? helper;
  final String? Function(int sen)? validator;
  final TextInputAction textInputAction;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Focus(
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        if (!hasFocus && widget.controller.text.isNotEmpty) _fieldKey.currentState?.validate();
      },
      child: TextFormField(
        key: _fieldKey,
        controller: widget.controller,
        keyboardType: TextInputType.number,
        textInputAction: widget.textInputAction,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, const RinggitCentsFormatter()],
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        validator: widget.validator == null ? null : (text) => widget.validator!(RinggitCentsFormatter.parse(text ?? '')),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          helperText: widget.helper,
          helperMaxLines: 2,
          prefixText: 'RM',
          filled: true,
          fillColor: c.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.l),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.control), borderSide: BorderSide(color: c.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.control), borderSide: BorderSide(color: c.line)),
        ),
      ),
    );
  }
}
