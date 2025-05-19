import 'package:flutter_riverpod/flutter_riverpod.dart';

final baseTimeProvider = StateProvider<DateTime>((ref) => DateTime.now());