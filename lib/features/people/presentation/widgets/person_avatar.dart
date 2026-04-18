import 'package:flutter/material.dart';

import 'package:were_all_in_this_together/features/people/domain/person.dart';

/// A circular avatar for a [Person], rendered as initials on a deterministic
/// per-Person tinted background.
///
/// The tint is derived from the Person's id (not their name) so renaming a
/// Person doesn't change their colour, and so two people with the same
/// first name aren't forced to look identical.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    required this.person,
    this.size = 40,
    super.key,
  });

  final Person person;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = _tintFor(person.id, scheme);
    final foreground = scheme.onSurface;

    return Semantics(
      // Announced to VoiceOver as e.g. "Alex, avatar".
      label: '${person.displayName}, avatar',
      excludeSemantics: true,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: background,
        child: Text(
          initialsFor(person.displayName),
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  /// Extract up to two display initials from [displayName].
  ///
  /// Visible for testing so we can assert the hash-free, locale-safe
  /// behaviour (e.g. that an empty name still returns something reasonable,
  /// and that a single-word name returns one character).
  @visibleForTesting
  static String initialsFor(String displayName) {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    if (parts.length == 1) return first.toUpperCase();
    final last = parts.last.characters.first;
    return '${first.toUpperCase()}${last.toUpperCase()}';
  }

  /// Derive a stable, soft background tint from [personId].
  ///
  /// We rotate hue across the palette and keep saturation/lightness inside
  /// a narrow band so every Person gets a distinctive but calm colour that
  /// still contrasts acceptably with `onSurface` foreground text.
  Color _tintFor(String personId, ColorScheme scheme) {
    // Simple deterministic hash; we don't need cryptographic quality here.
    var hash = 0;
    for (final code in personId.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    final hue = (hash % 360).toDouble();
    final hsl = HSLColor.fromAHSL(
      1,
      hue,
      // Slightly desaturated in dark mode so the avatar isn't louder than
      // the surrounding surface; tuned empirically.
      scheme.brightness == Brightness.dark ? 0.35 : 0.55,
      scheme.brightness == Brightness.dark ? 0.32 : 0.85,
    );
    return hsl.toColor();
  }
}
