import 'package:sembast/sembast.dart';

/// Stores do banco local.
///
/// Apenas `meta` existe desde a Fase 1. Os demais stores são usados a partir da
/// Fase 2 e não exigem criação explícita no Sembast.
final StoreRef<String, Map<String, Object?>> metaStore = stringMapStoreFactory
    .store('meta');
final StoreRef<String, Map<String, Object?>> peopleStore = stringMapStoreFactory
    .store('people');
final StoreRef<String, Map<String, Object?>> eventsStore = stringMapStoreFactory
    .store('events');
final StoreRef<String, Map<String, Object?>> participantsStore =
    stringMapStoreFactory.store('participants');
final StoreRef<String, Map<String, Object?>> groupsStore = stringMapStoreFactory
    .store('groups');
final StoreRef<String, Map<String, Object?>> settingsStore =
    stringMapStoreFactory.store('settings');
final StoreRef<String, Map<String, Object?>> drawsStore = stringMapStoreFactory
    .store('draws');
final StoreRef<String, Map<String, Object?>> assignmentsStore =
    stringMapStoreFactory.store('assignments');
final StoreRef<String, Map<String, Object?>> deliveriesStore =
    stringMapStoreFactory.store('deliveries');
