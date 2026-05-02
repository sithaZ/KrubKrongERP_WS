import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Product provider (mock for scaffold)
final productProvider = FutureProvider<List<dynamic>>((ref) async {
  // This would fetch from GraphQL in production
  return [];
});
