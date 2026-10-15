import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../validation/ringgit_cents_formatter.dart';
import 'money_keypad.dart';

/// A labelled money field that fills from the right. Tapping it opens the
/// app's own keypad rather than the phone's, the same keys the logger uses.
/// It validates once a value is entered, then re-checks on every change
/// while an error shows, so the message clears the moment the value is fixed.
class MoneyField extends StatefulWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.helper,
    this.validator,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? helper;
  final String? Function(int sen)? validator;
  final bool enabled;
  final TextInputAction textInputAction;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  Future<void> _openKeypad() async {
    final sen = await showMoneyKeypad(
      context,
      label: widget.label,
      sen: RinggitCentsFormatter.parse(widget.controller.text),
      helper: widget.helper,
    );
    if (sen == null || !mounted) return;
    widget.controller.text = sen == 0 ? '' : RinggitCentsFormatter.format(sen);
    FocusScope.of(context).unfocus();
    if (widget.controller.text.isNotEmpty) _fieldKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: _fieldKey,
      controller: widget.controller,
      enabled: widget.enabled,
      // The phone's keyboard never opens; the keypad sheet does the typing.
      readOnly: true,
      showCursor: false,
      keyboardType: TextInputType.none,
      textInputAction: widget.textInputAction,
      onTap: _openKeypad,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, const RinggitCentsFormatter()],
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      validator: widget.validator == null ? null : (text) => widget.validator!(RinggitCentsFormatter.parse(text ?? '')),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helper,
        helperMaxLines: 3,
        prefixText: 'RM',
      ),
    );
  }
}
