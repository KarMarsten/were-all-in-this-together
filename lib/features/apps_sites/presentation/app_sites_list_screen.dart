import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:were_all_in_this_together/core/router/app_router.dart';
import 'package:were_all_in_this_together/features/apps_sites/domain/app_site.dart';
import 'package:were_all_in_this_together/features/apps_sites/presentation/providers.dart';
import 'package:were_all_in_this_together/features/people/presentation/active_person_providers.dart';
import 'package:were_all_in_this_together/features/providers/presentation/url_opener.dart';

/// Saved portal links and notes — never passwords (use a password manager).
class AppSitesListScreen extends ConsumerWidget {
  const AppSitesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePerson = ref.watch(activePersonProvider);
    final listAsync = ref.watch(activeAppSitesProvider);
    final archivedAsync = ref.watch(archivedAppSitesProvider);
    final opener = ref.watch(urlOpenerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apps & Sites'),
        bottom: activePerson.maybeWhen(
          data: (person) => person == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(24),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'for ${person.displayName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
          orElse: () => null,
        ),
      ),
      floatingActionButton: activePerson.maybeWhen(
        data: (person) => person == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push(Routes.appSiteNew),
                icon: const Icon(Icons.add),
                label: const Text('Add link'),
              ),
        orElse: () => null,
      ),
      body: activePerson.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (person) {
          if (person == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add someone to the roster first — saved links are scoped '
                  'per person.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (active) {
              final archived = archivedAsync.value ?? const <AppSite>[];
              if (active.isEmpty && archived.isEmpty) {
                return const _EmptyState();
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                children: [
                  ..._categoryGroups(context, active, opener),
                  if (archived.isNotEmpty)
                    _ArchivedSection(sites: archived),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static List<Widget> _categoryGroups(
    BuildContext context,
    List<AppSite> sites,
    UrlOpener opener,
  ) {
    final out = <Widget>[];
    for (final category in AppSiteCategory.values) {
      final group = sites.where((s) => s.category == category).toList()
        ..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      if (group.isEmpty) continue;
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Text(
            labelForAppSiteCategory(category),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      );
      for (final site in group) {
        out.add(_AppSiteTile(site: site, opener: opener));
      }
    }
    return out;
  }
}

class _AppSiteTile extends StatelessWidget {
  const _AppSiteTile({required this.site, required this.opener});

  final AppSite site;
  final UrlOpener opener;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(site.title),
      subtitle: Text(
        _subtitle(site),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Open link',
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              final ok = await opener.openWeb(site.url);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Couldn't open link.")),
                );
              }
            },
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => context.push(Routes.appSiteEdit(site.id)),
    );
  }

  static String _subtitle(AppSite site) {
    final parts = <String>[
      site.url,
      if (_notBlank(site.usernameHint))
        'Username hint: ${site.usernameHint!.trim()}',
      if (_notBlank(site.loginNote)) site.loginNote!.trim(),
      if (_notBlank(site.notes)) site.notes!.trim(),
    ];
    return parts.join(' · ');
  }

  static bool _notBlank(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No saved links yet. Add a portal, telehealth login page, or IEP '
          'tool — never store passwords here.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _ArchivedSection extends StatelessWidget {
  const _ArchivedSection({required this.sites});

  final List<AppSite> sites;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Archived (${sites.length})'),
      children: [
        for (final s in sites)
          ListTile(
            title: Text(s.title),
            subtitle: Text(
              '${labelForAppSiteCategory(s.category)} · ${s.url}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => context.push(Routes.appSiteEdit(s.id)),
          ),
      ],
    );
  }
}
