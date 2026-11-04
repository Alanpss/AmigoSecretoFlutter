import 'package:amigo_secreto/app/providers.dart';
import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/features/delivery/data/delivery_repository.dart';
import 'package:amigo_secreto/features/delivery/domain/delivery_status.dart';
import 'package:amigo_secreto/features/delivery/presentation/delivery_queue_page.dart';
import 'package:amigo_secreto/features/delivery/presentation/whatsapp_launcher.dart';
import 'package:amigo_secreto/features/draw/data/draw_records.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  late AppDatabase database;
  late _FakeDeliveryRepository repository;
  late _RecordingWhatsAppLauncher launcher;

  setUp(() async {
    database = await createTestDatabase();
    repository = _FakeDeliveryRepository(database.database, _delivery());
    launcher = _RecordingWhatsAppLauncher();
  });

  tearDown(() => database.close());

  Future<void> pumpQueue(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveryRepositoryProvider.overrideWithValue(repository),
          whatsAppLauncherProvider.overrideWithValue(launcher),
          activeDeliveriesProvider('event-1')
              .overrideWith((ref) => Future.value(repository.deliveries)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DeliveryQueuePage(eventId: 'event-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('abrir WhatsApp registra conversa aberta sem confirmar envio', (
    tester,
  ) async {
    await pumpQueue(tester);

    await tester.tap(find.text('Abrir WhatsApp'));
    await tester.pumpAndSettle();

    expect(launcher.openedUris, hasLength(1));
    expect(launcher.openedUris.single.host, 'wa.me');
    expect(launcher.openedUris.single.path, '/5511900000001');
    expect(
      launcher.openedUris.single.queryParameters['text'],
      'Mensagem fictícia para Beto Exemplo.',
    );
    expect(repository.markedOpened, 1);
    expect(repository.confirmedMethods, isEmpty);
    expect(find.text('Conversa aberta'), findsOneWidget);
    expect(
      find.text(
        'Conversa aberta. O envio ainda precisa ser feito no WhatsApp.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('falha ao abrir mantém pendente e oferece cópia', (tester) async {
    launcher.result = false;
    await pumpQueue(tester);

    await tester.tap(find.text('Abrir WhatsApp'));
    await tester.pumpAndSettle();

    expect(repository.markedOpened, 0);
    expect(repository.confirmedMethods, isEmpty);
    expect(find.text('Pendente'), findsOneWidget);
    expect(
      find.text(
        'Não foi possível abrir o WhatsApp. A entrega continua pendente.',
      ),
      findsOneWidget,
    );
    expect(find.text('Copiar'), findsOneWidget);
  });

  testWidgets('copiar não muda o estado da entrega', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await pumpQueue(tester);

    await tester.tap(find.text('Copiar mensagem'));
    await tester.pumpAndSettle();

    expect(find.text('Mensagem copiada.'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(repository.markedOpened, 0);
    expect(repository.confirmedMethods, isEmpty);
  });

  testWidgets('filtro mostra apenas entregas pendentes', (tester) async {
    repository.deliveries = [
      _delivery(),
      _delivery(
        ownerName: 'Beto Exemplo',
        id: 'delivery-2',
      ).copyWith(status: DeliveryStatus.opened.name),
    ];
    await pumpQueue(tester);

    expect(find.text('Ana Exemplo'), findsOneWidget);
    expect(find.text('Beto Exemplo'), findsOneWidget);
    await tester.tap(find.text('Mostrar somente pendentes'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Exemplo'), findsOneWidget);
    expect(find.text('Beto Exemplo'), findsNothing);
  });

  testWidgets('contato ausente só permite confirmação manual', (tester) async {
    repository.deliveries = [_delivery(phone: null)];
    await pumpQueue(tester);

    expect(
      find.text('Sem telefone: faça a entrega manualmente.'),
      findsOneWidget,
    );
    expect(find.text('Abrir WhatsApp'), findsNothing);
    await tester.tap(find.text('Confirmar envio'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar envio'), findsWidgets);
    await tester.tap(find.text('Confirmar envio').last);
    await tester.pumpAndSettle();

    expect(repository.confirmedMethods, [DeliveryConfirmationMethod.manual]);
  });

  testWidgets('confirmação por WhatsApp exige ação explícita', (tester) async {
    await pumpQueue(tester);

    await tester.tap(find.text('Confirmar envio'));
    await tester.pumpAndSettle();
    expect(find.text('Enviei pelo WhatsApp'), findsOneWidget);
    await tester.tap(find.text('Enviei pelo WhatsApp'));
    await tester.pumpAndSettle();

    expect(repository.confirmedMethods, [DeliveryConfirmationMethod.whatsapp]);
    expect(find.text('Envio confirmado pelo organizador'), findsOneWidget);
  });
}

DeliveryRecord _delivery({
  String? phone = '+5511900000001',
  String id = 'delivery-1',
  String ownerName = 'Ana Exemplo',
}) => DeliveryRecord(
  id: id,
  drawId: 'draw-1',
  assignmentId: 'assignment-1',
  eventId: 'event-1',
  ownerParticipantId: 'participant-1',
  ownerNameSnapshot: ownerName,
  drawnNameSnapshot: 'Beto Exemplo',
  createdAt: DateTime.utc(2026, 11, 3),
  recipientKind: 'self',
  recipientNameSnapshot: ownerName,
  recipientPhoneSnapshot: phone,
  channel: phone == null ? 'manual' : 'whatsapp',
  status: DeliveryStatus.pending.name,
  messageSnapshot: 'Mensagem fictícia para Beto Exemplo.',
);

class _RecordingWhatsAppLauncher implements WhatsAppLauncher {
  bool result = true;
  final openedUris = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    openedUris.add(uri);
    return result;
  }
}

class _FakeDeliveryRepository extends DeliveryRepository {
  _FakeDeliveryRepository(super.database, DeliveryRecord initial)
    : deliveries = [initial];

  List<DeliveryRecord> deliveries;
  int markedOpened = 0;
  final confirmedMethods = <DeliveryConfirmationMethod>[];

  @override
  Future<DeliveryRecord> markOpened({
    required String eventId,
    required String deliveryId,
  }) async {
    markedOpened++;
    final index = deliveries.indexWhere((item) => item.id == deliveryId);
    final current = deliveries[index];
    deliveries[index] = current.copyWith(
      status: DeliveryStatus.opened.name,
      openedAt: DateTime.utc(2026, 11, 3),
    );
    return deliveries[index];
  }

  @override
  Future<DeliveryRecord> confirmSent({
    required String eventId,
    required String deliveryId,
    required DeliveryConfirmationMethod method,
  }) async {
    confirmedMethods.add(method);
    final index = deliveries.indexWhere((item) => item.id == deliveryId);
    deliveries[index] = deliveries[index].copyWith(
      status: DeliveryStatus.confirmed.name,
      confirmedAt: DateTime.utc(2026, 11, 3),
      confirmationMethod: method.name,
    );
    return deliveries[index];
  }
}
