import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Staff provider (mock for scaffold)
final staffProvider = FutureProvider<List<dynamic>>((ref) async {
  // This would fetch from GraphQL in production
  return [];
});
