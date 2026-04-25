import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CalmResourceKind {
  mindfulness,
  music
  ;

  String get label {
    switch (this) {
      case CalmResourceKind.mindfulness:
        return 'Mindfulness';
      case CalmResourceKind.music:
        return 'Calming music';
    }
  }

  static CalmResourceKind fromWireName(String? value) {
    for (final kind in CalmResourceKind.values) {
      if (kind.name == value) return kind;
    }
    return CalmResourceKind.mindfulness;
  }
}

@immutable
class CalmResource {
  const CalmResource({
    required this.id,
    required this.kind,
    required this.label,
    required this.url,
  });

  factory CalmResource.fromJson(Map<String, dynamic> json) {
    return CalmResource(
      id: json['id'] as String? ?? '',
      kind: CalmResourceKind.fromWireName(json['kind'] as String?),
      label: json['label'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  final String id;
  final CalmResourceKind kind;
  final String label;
  final String url;

  CalmResource copyWith({
    String? id,
    CalmResourceKind? kind,
    String? label,
    String? url,
  }) {
    return CalmResource(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'kind': kind.name,
    'label': label,
    'url': url,
  };
}

@immutable
class CalmResourcePreferences {
  const CalmResourcePreferences({
    required this.resources,
    required this.setupComplete,
  });

  final List<CalmResource> resources;
  final bool setupComplete;

  List<CalmResource> resourcesFor(CalmResourceKind kind) {
    return resources.where((resource) => resource.kind == kind).toList();
  }

  CalmResourcePreferences copyWith({
    List<CalmResource>? resources,
    bool? setupComplete,
  }) {
    return CalmResourcePreferences(
      resources: resources ?? this.resources,
      setupComplete: setupComplete ?? this.setupComplete,
    );
  }
}

abstract class CalmResourcePreferencesRepository {
  Future<CalmResourcePreferences> load();

  Future<void> save(CalmResourcePreferences preferences);
}

class SharedPreferencesCalmResourcePreferencesRepository
    implements CalmResourcePreferencesRepository {
  SharedPreferencesCalmResourcePreferencesRepository({
    required Future<SharedPreferences> Function() preferencesLoader,
  }) : _load = preferencesLoader;

  final Future<SharedPreferences> Function() _load;

  static const String setupCompleteKey = 'calm.resources.setupComplete';
  static const String resourcesKey = 'calm.resources.items';

  @override
  Future<CalmResourcePreferences> load() async {
    final prefs = await _load();
    final raw = prefs.getString(resourcesKey);
    final resources = raw == null
        ? defaultCalmResources
        : _decodeResources(raw);
    return CalmResourcePreferences(
      resources: resources,
      setupComplete: prefs.getBool(setupCompleteKey) ?? false,
    );
  }

  @override
  Future<void> save(CalmResourcePreferences preferences) async {
    final prefs = await _load();
    await prefs.setString(
      resourcesKey,
      jsonEncode([
        for (final resource in preferences.resources) resource.toJson(),
      ]),
    );
    await prefs.setBool(setupCompleteKey, preferences.setupComplete);
  }

  static List<CalmResource> _decodeResources(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return defaultCalmResources;
      final resources = [
        for (final item in decoded)
          if (item is Map<String, dynamic>) CalmResource.fromJson(item),
      ].where(_isUsable).toList();
      return resources.isEmpty ? defaultCalmResources : resources;
    } on FormatException {
      return defaultCalmResources;
    }
  }

  static bool _isUsable(CalmResource resource) {
    return resource.label.trim().isNotEmpty && resource.url.trim().isNotEmpty;
  }
}

const defaultCalmResources = <CalmResource>[
  CalmResource(
    id: 'default-breathing',
    kind: CalmResourceKind.mindfulness,
    label: 'Five-minute breathing practice',
    url:
        'https://www.youtube.com/results?search_query=5+minute+breathing+exercise',
  ),
  CalmResource(
    id: 'default-grounding',
    kind: CalmResourceKind.mindfulness,
    label: 'Grounding exercise search',
    url:
        'https://www.youtube.com/results?search_query=5+4+3+2+1+grounding+exercise',
  ),
  CalmResource(
    id: 'default-calm-music',
    kind: CalmResourceKind.music,
    label: 'Calming music on Spotify',
    url: 'https://open.spotify.com/search/calming%20music',
  ),
  CalmResource(
    id: 'default-sleep-music',
    kind: CalmResourceKind.music,
    label: 'Low-stimulation music on YouTube',
    url:
        'https://www.youtube.com/results?search_query=calming+music+low+stimulation',
  ),
];

final calmResourcePreferencesRepositoryProvider =
    Provider<CalmResourcePreferencesRepository>((ref) {
      return SharedPreferencesCalmResourcePreferencesRepository(
        preferencesLoader: SharedPreferences.getInstance,
      );
    });

final calmResourcePreferencesProvider = FutureProvider<CalmResourcePreferences>(
  (ref) async {
    final repo = ref.watch(calmResourcePreferencesRepositoryProvider);
    return repo.load();
  },
);
