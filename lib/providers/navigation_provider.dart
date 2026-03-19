import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the current bottom navigation index for technicians
final teknisiNavIndexProvider = StateProvider<int>((ref) => 0);
