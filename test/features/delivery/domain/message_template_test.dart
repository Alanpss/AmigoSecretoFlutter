import 'package:amigo_secreto/features/delivery/domain/message_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renderiza todas as variáveis permitidas', () {
    final template = MessageTemplate.parse(
      '{evento}|{participante}|{apelido}|{sorteado}|{responsavel}',
    );

    expect(
      template.render({
        'evento': 'Festa fictícia',
        'participante': 'Ana Exemplo',
        'apelido': 'Aninha',
        'sorteado': 'Beto',
        'responsavel': 'Carla',
      }),
      'Festa fictícia|Ana Exemplo|Aninha|Beto|Carla',
    );
  });

  test('rejeita variável desconhecida, chave aberta, fechada ou aninhada', () {
    for (final source in [
      'Olá, {desconhecida}',
      'Olá, {evento',
      'Olá, evento}',
      'Olá, {{evento}}',
    ]) {
      expect(
        () => MessageTemplate.parse(source),
        throwsA(isA<MessageTemplateException>()),
        reason: source,
      );
    }
  });

  test('não reprocessa chaves contidas no valor inserido', () {
    final template = MessageTemplate.parse('Evento: {evento}');

    expect(
      template.render({'evento': 'Evento {desconhecida}'}),
      'Evento: Evento {desconhecida}',
    );
  });

  test('rejeita modelo vazio e limites acima de 2000 caracteres', () {
    expect(
      () => MessageTemplate.parse('  \n'),
      throwsA(isA<MessageTemplateException>()),
    );
    expect(
      () => MessageTemplate.parse(List.filled(2001, 'a').join()),
      throwsA(isA<MessageTemplateException>()),
    );
    expect(
      MessageTemplate.parse(List.filled(2000, '🎁').join()).render({}),
      List.filled(2000, '🎁').join(),
    );
  });

  test('falha com erro tipado se faltar um valor usado pela variável', () {
    final template = MessageTemplate.parse('Olá, {responsavel}');

    expect(
      () => template.render(const {}),
      throwsA(isA<MessageTemplateException>()),
    );
  });
}
