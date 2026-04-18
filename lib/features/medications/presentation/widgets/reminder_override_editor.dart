import 'package:flutter/material.dart';

import 'package:were_all_in_this_together/features/medications/domain/notification_preferences.dart';

/// Per-medication override editor for nag interval + cap.
///
/// Renders as a compact, collapsed-by-default card — most medications
/// will use the global defaults and we don't want to clutter the
/// form. Expanding surfaces the two knobs; collapsing back with the
/// "Clear" action resets both to `null` (use global default).
class ReminderOverrideEditor extends StatefulWidget {
  const ReminderOverrideEditor({
    required this.intervalMinutesOverride,
    required this.capOverride,
    required this.onIntervalChanged,
    required this.onCapChanged,
    super.key,
  });

  final int? intervalMinutesOverride;
  final int? capOverride;
  final ValueChanged<int?> onIntervalChanged;
  final ValueChanged<int?> onCapChanged;

  @override
  State<ReminderOverrideEditor> createState() => _ReminderOverrideEditorState();
}

class _ReminderOverrideEditorState extends State<ReminderOverrideEditor> {
  late bool _expanded = _hasOverride;

  bool get _hasOverride =>
      widget.intervalMinutesOverride != null || widget.capOverride != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom nag for this medication',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _hasOverride
                              ? _summary(
                                  widget.intervalMinutesOverride,
                                  widget.capOverride,
                                )
                              : 'Using global defaults',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IntervalPicker(
                    value: widget.intervalMinutesOverride,
                    onChanged: widget.onIntervalChanged,
                  ),
                  const SizedBox(height: 16),
                  _CapPicker(
                    value: widget.capOverride,
                    onChanged: widget.onCapChanged,
                  ),
                  if (_hasOverride) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Use global defaults'),
                        onPressed: () {
                          widget.onIntervalChanged(null);
                          widget.onCapChanged(null);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _summary(int? interval, int? cap) {
    final bits = <String>[];
    if (interval != null) bits.add('retry every $interval min');
    if (cap != null) bits.add('up to $cap ${cap == 1 ? 'retry' : 'retries'}');
    return bits.isEmpty ? 'Using global defaults' : bits.join(' · ');
  }
}

class _IntervalPicker extends StatelessWidget {
  const _IntervalPicker({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    const choices = <int?>[null, 1, 5, 10, 15, 30, 60, 120];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Retry every',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in choices)
              ChoiceChip(
                label: Text(_label(c)),
                selected: c == value,
                onSelected: (on) {
                  if (on) onChanged(c);
                },
              ),
          ],
        ),
      ],
    );
  }

  String _label(int? v) {
    if (v == null) return 'Default';
    if (v < 60) return '$v min';
    final h = v ~/ 60;
    return h == 1 ? '1 h' : '$h h';
  }
}

class _CapPicker extends StatelessWidget {
  const _CapPicker({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final choices = <int?>[
      null,
      0,
      1,
      2,
      3,
      5,
      NotificationPreferences.maxNagCap,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Retries after the first alert',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in choices)
              ChoiceChip(
                label: Text(_label(c)),
                selected: c == value,
                onSelected: (on) {
                  if (on) onChanged(c);
                },
              ),
          ],
        ),
      ],
    );
  }

  String _label(int? v) {
    if (v == null) return 'Default';
    if (v == 0) return 'None';
    return '$v';
  }
}
