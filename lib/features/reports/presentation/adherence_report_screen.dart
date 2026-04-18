import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:were_all_in_this_together/features/medications/domain/dose_log.dart';
import 'package:were_all_in_this_together/features/people/domain/person.dart';
import 'package:were_all_in_this_together/features/people/presentation/providers.dart';
import 'package:were_all_in_this_together/features/reports/data/adherence_report_pdf.dart';
import 'package:were_all_in_this_together/features/reports/data/adherence_report_service.dart';
import 'package:were_all_in_this_together/features/reports/domain/adherence_report_row.dart';

/// Medication adherence report.
///
/// Layout:
/// * Range picker (from / to date). Defaults to the last 7 days.
/// * Optional Person filter (all / specific).
/// * Four-column table — Time, Medication, Person, ACK'd by.
/// * Share / Print actions in the app bar.
class AdherenceReportScreen extends ConsumerStatefulWidget {
  const AdherenceReportScreen({super.key});

  @override
  ConsumerState<AdherenceReportScreen> createState() =>
      _AdherenceReportScreenState();
}

class _AdherenceReportScreenState
    extends ConsumerState<AdherenceReportScreen> {
  /// Inclusive local calendar date selected as the start of the
  /// window. Stored as a date-only `DateTime` so the date picker
  /// round-trips cleanly.
  late DateTime _fromDate;
  late DateTime _toDate;
  String? _personId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate = DateTime(now.year, now.month, now.day);
    _fromDate = _toDate.subtract(const Duration(days: 6));
  }

  AdherenceReportQuery get _query {
    // Convert the local calendar window to a half-open UTC window.
    final fromLocal = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
    final toLocalExclusive = DateTime(
      _toDate.year,
      _toDate.month,
      _toDate.day,
    ).add(const Duration(days: 1));
    return AdherenceReportQuery(
      fromInclusive: fromLocal.toUtc(),
      toExclusive: toLocalExclusive.toUtc(),
      personId: _personId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleListProvider);
    final rowsAsync = ref.watch(adherenceReportProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adherence report'),
        actions: [
          IconButton(
            tooltip: 'Share or save as PDF',
            icon: const Icon(Icons.ios_share),
            onPressed: rowsAsync.hasValue && rowsAsync.value!.isNotEmpty
                ? () => _share(rowsAsync.value!)
                : null,
          ),
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print_outlined),
            onPressed: rowsAsync.hasValue && rowsAsync.value!.isNotEmpty
                ? () => _print(rowsAsync.value!)
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Filters(
              fromDate: _fromDate,
              toDate: _toDate,
              personId: _personId,
              people: peopleAsync.hasValue
                  ? peopleAsync.value!
                  : const <Person>[],
              onFromChanged: (d) => setState(() => _fromDate = d),
              onToChanged: (d) => setState(() => _toDate = d),
              onPersonChanged: (id) => setState(() => _personId = id),
            ),
            const Divider(height: 1),
            Expanded(
              child: rowsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorBody(error: e),
                data: (rows) {
                  if (rows.isEmpty) return const _EmptyBody();
                  return _ReportList(rows: rows);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildPdf(List<AdherenceReportRow> rows) async {
    final peopleAsync = ref.read(peopleListProvider);
    final people = peopleAsync.hasValue ? peopleAsync.value! : const <Person>[];
    final personName = _personId == null
        ? null
        : people
            .firstWhere(
              (p) => p.id == _personId,
              orElse: () => Person(
                id: _personId!,
                displayName: kUnknownPersonLabel,
                createdAt: DateTime.now().toUtc(),
                updatedAt: DateTime.now().toUtc(),
              ),
            )
            .displayName;
    final bytes = await buildAdherenceReportPdf(
      rows: rows,
      fromInclusive: _query.fromInclusive,
      toExclusive: _query.toExclusive,
      personName: personName,
    );
    return Uint8List.fromList(bytes);
  }

  Future<void> _share(List<AdherenceReportRow> rows) async {
    final pdf = await _buildPdf(rows);
    final dateFmt = DateFormat('yyyy-MM-dd');
    final from = dateFmt.format(_fromDate);
    final to = dateFmt.format(_toDate);
    await Printing.sharePdf(
      bytes: pdf,
      filename: 'adherence-$from-to-$to.pdf',
    );
  }

  Future<void> _print(List<AdherenceReportRow> rows) async {
    final pdf = await _buildPdf(rows);
    await Printing.layoutPdf(onLayout: (_) async => pdf);
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.fromDate,
    required this.toDate,
    required this.personId,
    required this.people,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPersonChanged,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final String? personId;
  final List<Person> people;
  final ValueChanged<DateTime> onFromChanged;
  final ValueChanged<DateTime> onToChanged;
  final ValueChanged<String?> onPersonChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'From',
                  value: fromDate,
                  onChanged: (d) {
                    // Swap the endpoints if the user picks a "from"
                    // after the current "to" — easier than flashing
                    // an error.
                    if (d.isAfter(toDate)) {
                      onToChanged(d);
                    }
                    onFromChanged(d);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'To',
                  value: toDate,
                  onChanged: (d) {
                    if (d.isBefore(fromDate)) {
                      onFromChanged(d);
                    }
                    onToChanged(d);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Who:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String?>(
                  value: personId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      child: Text('Everyone'),
                    ),
                    for (final p in people)
                      DropdownMenuItem<String?>(
                        value: p.id,
                        child: Text(p.displayName),
                      ),
                  ],
                  onChanged: onPersonChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(fmt.format(value)),
        ],
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.centerLeft,
      ),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          helpText: 'Choose $label',
        );
        if (picked != null) {
          onChanged(DateTime(picked.year, picked.month, picked.day));
        }
      },
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.rows});

  final List<AdherenceReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('yyyy-MM-dd HH:mm');
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: rows.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Row(
            children: [
              Expanded(flex: 3, child: _Header('Time')),
              Expanded(flex: 3, child: _Header('Medication')),
              Expanded(flex: 2, child: _Header('Person')),
              Expanded(flex: 2, child: _Header("ACK'd by")),
            ],
          );
        }
        final row = rows[index - 1];
        final skipped = row.outcome == DoseOutcome.skipped;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Text(timeFmt.format(row.scheduledAt.toLocal())),
            ),
            Expanded(
              flex: 3,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: row.medicationName),
                    if (skipped)
                      TextSpan(
                        text: '  · skipped',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(flex: 2, child: Text(row.personName)),
            Expanded(flex: 2, child: Text(row.ackedBy)),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'No doses logged in this range.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Expand the date range or switch the person filter to see more.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              "Couldn't build the report.",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
