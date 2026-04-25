import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/apps_sites/domain/app_site.dart';
import 'package:were_all_in_this_together/features/apps_sites/presentation/providers.dart';
import 'package:were_all_in_this_together/features/programs/domain/program.dart';
import 'package:were_all_in_this_together/features/programs/presentation/providers.dart';
import 'package:were_all_in_this_together/features/providers/domain/care_provider.dart';
import 'package:were_all_in_this_together/features/providers/presentation/care_providers_list_screen.dart'
    show iconForKind, labelForKind;
import 'package:were_all_in_this_together/features/providers/presentation/url_opener.dart';

/// Read-focused detail view for a single [CareProvider].
///
/// Renders every populated field as its own readable row and offers
/// one-tap actions for the things caregivers most often need to do with a
/// provider record: call, email, open the portal, and navigate to the office.
///
/// An "Edit" action in the app bar jumps straight to the shared
/// `CareProviderFormScreen` so the detail view stays focused on
/// reading; editing lives in one place.
class CareProviderDetailScreen extends ConsumerWidget {
  const CareProviderDetailScreen({required this.provider, super.key});

  final CareProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final opener = ref.watch(urlOpenerProvider);
    final isArchived = provider.deletedAt != null;
    final linkedProgramsAsync = ref.watch(
      allProgramsForPersonProvider(provider.personId),
    );
    final linkedSitesAsync = ref.watch(
      allAppSitesForPersonProvider(provider.personId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.name),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push(Routes.careProviderEdit(provider.id)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Icon(iconForKind(provider.kind), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.name, style: text.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        [
                          labelForKind(provider.kind),
                          if (provider.specialty != null &&
                              provider.specialty!.trim().isNotEmpty)
                            provider.specialty!.trim(),
                          if (provider.role != null &&
                              provider.role!.trim().isNotEmpty)
                            provider.role!.trim(),
                        ].join(' · '),
                        style: text.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isArchived) ...[
              const SizedBox(height: 16),
              _ArchivedBanner(archivedAt: provider.deletedAt!),
            ],
            const SizedBox(height: 24),
            _TapAction(
              icon: Icons.call_outlined,
              label: 'Call',
              value: provider.phone,
              onTap: provider.phone == null
                  ? null
                  : () => _open(
                        context,
                        () => opener.openTel(provider.phone!),
                        failureMessage: "Couldn't start the call.",
                      ),
            ),
            _TapAction(
              icon: Icons.email_outlined,
              label: 'Email',
              value: provider.email,
              onTap: provider.email == null
                  ? null
                  : () => _open(
                        context,
                        () => opener.openEmail(provider.email!),
                        failureMessage: "Couldn't open Mail.",
                      ),
            ),
            _TapAction(
              icon: Icons.print_outlined,
              label: 'Fax',
              value: provider.fax,
              onTap: null,
            ),
            _TapAction(
              icon: Icons.public,
              label: _portalLabel(provider),
              value: provider.portalUrl,
              onTap: provider.portalUrl == null
                  ? null
                  : () => _open(
                        context,
                        () => opener.openWeb(provider.portalUrl!),
                        failureMessage: "Couldn't open the portal URL.",
                      ),
            ),
            _TapAction(
              icon: Icons.contact_page_outlined,
              label: 'Contact person',
              value: provider.contactName,
              onTap: null,
            ),
            _TapAction(
              icon: Icons.place_outlined,
              label: 'Address',
              value: provider.address,
              multiline: true,
              onTap: provider.address == null
                  ? null
                  : () => _open(
                        context,
                        () => opener.openMap(provider.address!),
                        failureMessage: "Couldn't open Maps.",
                      ),
            ),
            _TapAction(
              icon: Icons.nightlight_outlined,
              label: 'After-hours phone',
              value: provider.afterHoursPhone,
              onTap: provider.afterHoursPhone == null
                  ? null
                  : () => _open(
                        context,
                        () => opener.openTel(provider.afterHoursPhone!),
                        failureMessage: "Couldn't start the call.",
                      ),
            ),
            _TapAction(
              icon: Icons.info_outline,
              label: 'After-hours instructions',
              value: provider.afterHoursInstructions,
              multiline: true,
              onTap: null,
            ),
            if (provider.notes != null && provider.notes!.trim().isNotEmpty)
              _NotesBlock(notes: provider.notes!.trim()),
            _LinkedRecordsSection(
              providerId: provider.id,
              programsAsync: linkedProgramsAsync,
              sitesAsync: linkedSitesAsync,
            ),
          ],
        ),
      ),
    );
  }

  /// Launches a URL action and surfaces a SnackBar on failure. Wrapped
  /// so each tap-row has identical failure handling without repeating
  /// the try/catch in the widget tree.
  Future<void> _open(
    BuildContext context,
    Future<bool> Function() action, {
    required String failureMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await action();
      if (!ok && context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(failureMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$failureMessage ($e)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _portalLabel(CareProvider provider) {
    final label = provider.portalLabel?.trim();
    if (label == null || label.isEmpty) return 'Portal';
    return label;
  }
}

class _LinkedRecordsSection extends StatelessWidget {
  const _LinkedRecordsSection({
    required this.providerId,
    required this.programsAsync,
    required this.sitesAsync,
  });

  final String providerId;
  final AsyncValue<List<Program>> programsAsync;
  final AsyncValue<List<AppSite>> sitesAsync;

  @override
  Widget build(BuildContext context) {
    final programs = (programsAsync.value ?? const <Program>[])
        .where((program) => program.providerId == providerId)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final sites = (sitesAsync.value ?? const <AppSite>[])
        .where((site) => site.providerId == providerId)
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    if (programsAsync.isLoading && sitesAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (programs.isEmpty && sites.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Linked records',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final program in programs)
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text(program.name),
                subtitle: const Text('Program'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.programEdit(program.id)),
              ),
            for (final site in sites)
              ListTile(
                leading: const Icon(Icons.link_outlined),
                title: Text(site.title),
                subtitle: const Text('App/Site'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.appSiteEdit(site.id)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Prominent-but-calm banner shown on archived providers so the user
/// knows they're looking at a historical record rather than a live
/// contact.
class _ArchivedBanner extends StatelessWidget {
  const _ArchivedBanner({required this.archivedAt});

  final DateTime archivedAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.archive_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This provider is archived. They still show up on '
              'records that reference them.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _TapAction extends StatelessWidget {
  const _TapAction({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.multiline = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = value?.trim();
    final hasValue = display != null && display.isNotEmpty;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        subtitle: Text(
          hasValue ? display : 'Not set',
          style: Theme.of(context).textTheme.bodyLarge,
          maxLines: multiline ? null : 1,
          overflow: multiline ? null : TextOverflow.ellipsis,
        ),
        trailing: hasValue && onTap != null ? const Icon(Icons.launch) : null,
        onTap: hasValue ? onTap : null,
      ),
    );
  }
}

class _NotesBlock extends StatelessWidget {
  const _NotesBlock({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notes',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
