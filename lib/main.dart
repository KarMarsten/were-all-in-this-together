import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:were_all_in_this_together/app.dart';

void main() {
  // Future: initialize timezone data, notifications, crypto keys,
  // database, and secure storage here before runApp.
  runApp(const ProviderScope(child: App()));
}
