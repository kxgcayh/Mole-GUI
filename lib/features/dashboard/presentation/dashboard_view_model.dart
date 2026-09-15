import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/system_info_service.dart';
import '../domain/system_metrics.dart';

final dashboardMetricsProvider = StreamProvider.autoDispose<SystemMetrics>((ref) {
  final service = ref.watch(systemInfoServiceProvider);
  return service.metricsStream;
});
