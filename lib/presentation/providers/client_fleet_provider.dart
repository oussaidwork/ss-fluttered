import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/client_fleet.dart';
import 'repository_providers.dart';

final clientFleetByClientProvider = StreamProvider.family<List<ClientFleet>, String>((ref, clientId) {
  return ref.watch(clientFleetRepositoryProvider).watchClientFleet(clientId);
});

final allClientFleetProvider = StreamProvider<List<ClientFleet>>((ref) {
  return ref.watch(clientFleetRepositoryProvider).watchAllClientFleet();
});
