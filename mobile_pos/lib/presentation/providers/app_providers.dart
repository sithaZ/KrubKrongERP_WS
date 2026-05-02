import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// App-level providers
final appLoadingProvider = StateProvider<bool>((ref) => false);
final appErrorProvider = StateProvider<String?>((ref) => null);

/// User greeting based on time of day
final greetingProvider = Provider<String>((ref) {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
});

/// Current user initials for avatar
final userInitialsProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.initials ?? '??';
});
