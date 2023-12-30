import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class AutoCompleteTextEdit extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final String labelText;
  final List<String> suggestions;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;

  const AutoCompleteTextEdit({
    Key? key,
    required this.controller,
    this.onChanged,
    required this.labelText,
    required this.suggestions, this.validator, this.autofillHints, this.onFieldSubmitted,
  }) : super(key: key);

  @override
  _AutoCompleteTextEditState createState() => _AutoCompleteTextEditState();
}

class _AutoCompleteTextEditState extends State<AutoCompleteTextEdit> {
  final Logger _logger = Logger('_AutoCompleteTextEditState');

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        _logger.fine("optionsBuilder content changed: ${textEditingValue.text}");
        List<String> suggestions;
        if (textEditingValue.text.isEmpty) {
          suggestions = widget.suggestions;
        } else {
          suggestions = widget.suggestions.where((String option) {
            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
          }).toList();
        }
        _logger.fine("optionsBuilder suggestions: $suggestions");
        return suggestions;
      },
      onSelected: (String selection) {
        _logger.finest("onSelected: $selection");
        widget.controller.text = selection;
        widget.onChanged?.call(selection);
      },
      fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
        return TextFormField(
          controller: fieldTextEditingController,
          autofillHints: widget.autofillHints,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            suffixIcon: IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                fieldFocusNode.unfocus();
              },
            ),
          ),
          validator: widget.validator,
          onChanged: (String val) {
            _logger.finest("fieldViewBuilder onChanged: $val");
            setState(() {
              widget.controller.text = val;
            });
            if (widget.onChanged != null) widget.onChanged!(val);
          },
          onFieldSubmitted: widget.onFieldSubmitted,
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
