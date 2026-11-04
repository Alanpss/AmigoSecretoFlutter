import 'package:amigo_secreto/app/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra uma mensagem segura quando o banco falha', (
    tester,
  ) async {
    await tester.pumpWidget(const DatabaseFailureApp());

    expect(find.text('Não foi possível abrir os dados'), findsOneWidget);
    expect(find.textContaining('Nada foi apagado'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Restaurar backup'), findsOneWidget);
  });

  testWidgets('permite tentar novamente', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(home: DatabaseFailurePage(onRetry: () => retries++)),
    );

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(retries, 1);
  });
}
