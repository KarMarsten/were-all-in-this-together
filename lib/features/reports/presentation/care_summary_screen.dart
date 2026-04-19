import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/profile/domain/profile_entry.dart';
import 'package:were_all_in_this_together/features/profile/presentation/providers.dart';
import 'package:were_all_in_this_together/features/reports/data/care_summary_pdf.dart';

/// One-tap PDF handoff: baselines + active structured profile + crisis lines.
class CareSummaryScreen extends ConsumerWidget {
  const CareSummaryScreen({super.key});

  Future<Uint8List> _buildBytes(WidgetRef ref) async {
    final person = await ref.read(activePersonProvider.future);
    if (person == null) {
      throw StateError('No active person');
    }
    final profile = await ref.read(activePersonProfileProvider.future);
    final all = await ref.read(profileEntriesForActivePersonProvider.future);
    final active = all
        .where((e) => e.status == ProfileEntryStatus.active)
        .toList();
    final raw = await buildCareSummaryPdf(
      personName: person.displayName,
      activeEntries: active,
      profile: profile,
    );
    return Uint8List.fromList(raw);
  }

  String _filename(String personName) {
    final slug = personName
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    final day = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final safe = slug.isEmpty ? 'person' : slug;
    return 'care-summary-$safe-$day.pdf';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(activePersonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Care summary'),
        actions: [
          IconButton(
            tooltip: 'Share or save as PDF',
            icon: const Icon(Icons.ios_share),
            onPressed: personAsync.hasValue && personAsync.value != null
                ? () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final person = personAsync.value!;
                      final bytes = await _buildBytes(ref);
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: _filename(person.displayName),
                      );
                    } on Object catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Couldn't build PDF: $e")),
                      );
                    }
                  }
                : null,
          ),
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print_outlined),
            onPressed: personAsync.hasValue && personAsync.value != null
                ? () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final bytes = await _buildBytes(ref);
                      await Printing.layoutPdf(onLayout: (_) async => bytes);
                    } on Object catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Couldn't print: $e")),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
      body: personAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (person) {
          if (person == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Pick someone on Home first — the summary follows the '
                  'active person.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'For babysitters, grandparents, and respite',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Exports communication, sleep, and appetite baselines, every '
                'active structured profile line (grouped by section), and '
                'national crisis resources. Paused or resolved lines stay in '
                'the app but are omitted here.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final bytes = await _buildBytes(ref);
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: _filename(person.displayName),
                    );
                  } on Object catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text("Couldn't build PDF: $e")),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Share PDF'),
              ),
            ],
          );
        },
      ),
    );
  }
}
