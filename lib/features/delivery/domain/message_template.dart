import '../../../core/errors/domain_exceptions.dart';
import '../../events/domain/event.dart';

const Set<String> allowedMessageVariables = {
  'evento',
  'participante',
  'apelido',
  'sorteado',
  'responsavel',
};

/// Modelo validado, renderizado em uma única passada.
class MessageTemplate {
  MessageTemplate._(this._segments);

  final List<_TemplateSegment> _segments;

  factory MessageTemplate.parse(String source) {
    if (source.trim().isEmpty) {
      throw const MessageTemplateException(
        'Informe o modelo de mensagem antes de salvar.',
      );
    }
    if (source.runes.length > maxMessageTemplateLength) {
      throw const MessageTemplateException(
        'O modelo de mensagem deve ter no máximo 2000 caracteres.',
      );
    }

    final segments = <_TemplateSegment>[];
    var literalStart = 0;
    var index = 0;
    while (index < source.length) {
      final character = source[index];
      if (character == '}') {
        throw const MessageTemplateException(
          'O modelo contém uma chave de fechamento sem variável.',
        );
      }
      if (character != '{') {
        index++;
        continue;
      }

      final closingIndex = source.indexOf('}', index + 1);
      if (closingIndex < 0) {
        throw const MessageTemplateException(
          'O modelo contém uma variável sem a chave de fechamento.',
        );
      }

      final variable = source.substring(index + 1, closingIndex);
      if (variable.contains('{') ||
          !allowedMessageVariables.contains(variable)) {
        throw const MessageTemplateException(
          'O modelo contém uma variável não reconhecida. Use apenas evento, '
          'participante, apelido, sorteado ou responsavel entre chaves.',
        );
      }

      if (literalStart < index) {
        segments.add(_LiteralSegment(source.substring(literalStart, index)));
      }
      segments.add(_VariableSegment(variable));
      index = closingIndex + 1;
      literalStart = index;
    }

    if (literalStart < source.length) {
      segments.add(_LiteralSegment(source.substring(literalStart)));
    }
    return MessageTemplate._(List.unmodifiable(segments));
  }

  String render(Map<String, String> values) {
    final output = StringBuffer();
    for (final segment in _segments) {
      switch (segment) {
        case _LiteralSegment(:final value):
          output.write(value);
        case _VariableSegment(:final name):
          final value = values[name];
          if (value == null) {
            throw const MessageTemplateException(
              'Não foi possível montar a mensagem. Confira os dados do evento.',
            );
          }
          output.write(value);
      }
    }
    return output.toString();
  }
}

class MessageTemplateException extends ValidationException {
  const MessageTemplateException(super.message);
}

sealed class _TemplateSegment {
  const _TemplateSegment();
}

class _LiteralSegment extends _TemplateSegment {
  const _LiteralSegment(this.value);

  final String value;
}

class _VariableSegment extends _TemplateSegment {
  const _VariableSegment(this.name);

  final String name;
}
