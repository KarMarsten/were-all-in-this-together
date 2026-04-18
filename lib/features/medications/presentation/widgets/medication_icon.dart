import 'package:flutter/material.dart';

import 'package:were_all_in_this_together/features/medications/domain/medication.dart';

/// Small icon leading for a medication tile. Deliberately calm, low-
/// saturation imagery — never red/alarming — so scanning a long list
/// doesn't read as a list of problems.
class MedicationIcon extends StatelessWidget {
  const MedicationIcon({required this.form, this.size = 36, super.key});

  final MedicationForm? form;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        _iconFor(form),
        size: size * 0.55,
        color: scheme.onSecondaryContainer,
      ),
    );
  }

  static IconData _iconFor(MedicationForm? form) {
    return switch (form) {
      MedicationForm.pill => Icons.medication_outlined,
      MedicationForm.liquid => Icons.local_drink_outlined,
      MedicationForm.patch => Icons.healing_outlined,
      MedicationForm.inhaler => Icons.air_outlined,
      MedicationForm.injection => Icons.vaccines_outlined,
      MedicationForm.drops => Icons.water_drop_outlined,
      MedicationForm.cream => Icons.sanitizer_outlined,
      MedicationForm.other => Icons.medication_liquid_outlined,
      null => Icons.medication_liquid_outlined,
    };
  }
}

/// Human-readable label for a [MedicationForm], for dropdowns and tile
/// subtitles. Separate from [MedicationForm.wireName] on purpose — wire
/// names are stability-critical; these are localised display strings.
String medicationFormLabel(MedicationForm? form) {
  return switch (form) {
    MedicationForm.pill => 'Pill',
    MedicationForm.liquid => 'Liquid',
    MedicationForm.patch => 'Patch',
    MedicationForm.inhaler => 'Inhaler',
    MedicationForm.injection => 'Injection',
    MedicationForm.drops => 'Drops',
    MedicationForm.cream => 'Cream / ointment',
    MedicationForm.other => 'Other',
    null => 'Unspecified',
  };
}
