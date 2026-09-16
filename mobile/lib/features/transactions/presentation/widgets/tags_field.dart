import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';

/// Chip-style editor for up to 10 case-insensitive tag names.
class TagsField extends StatefulWidget {
  const TagsField({super.key, required this.tags, required this.onChanged});

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<TagsField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final name = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    _controller.clear();
    if (name.isEmpty || widget.tags.length >= 10) return;
    if (widget.tags.any((t) => t.toLowerCase() == name.toLowerCase())) return;
    widget.onChanged([...widget.tags, name.length > 40 ? name.substring(0, 40) : name]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '${l10n.tags} (${l10n.optional})',
        prefixIcon: const Icon(Icons.sell_outlined),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final tag in widget.tags)
            InputChip(
              label: Text(tag),
              visualDensity: VisualDensity.compact,
              onDeleted: () => widget.onChanged(widget.tags.where((t) => t != tag).toList()),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96, maxWidth: 220),
            child: TextField(
              key: const Key('tag-input'),
              controller: _controller,
              decoration: InputDecoration.collapsed(hintText: l10n.addTag),
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                if (value.endsWith(',') || value.endsWith('،')) _commit(value.substring(0, value.length - 1));
              },
              onSubmitted: _commit,
            ),
          ),
        ],
      ),
    );
  }
}
