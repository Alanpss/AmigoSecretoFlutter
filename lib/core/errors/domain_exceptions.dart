/// Erros de negócio esperados, com mensagens seguras para exibição.
///
/// As mensagens não devem conter telefone, nome completo ou qualquer outro
/// dado pessoal além do necessário para o organizador entender o problema.
sealed class DomainException implements Exception {
  const DomainException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Um campo ou combinação de campos não passou na validação.
class ValidationException extends DomainException {
  const ValidationException(super.message);
}

/// A pessoa selecionada já participa deste evento.
class DuplicateParticipationException extends DomainException {
  const DuplicateParticipationException()
    : super('Esta pessoa já participa deste evento.');
}

/// Já existe um grupo com o mesmo nome neste evento.
class DuplicateGroupNameException extends DomainException {
  const DuplicateGroupNameException()
    : super('Já existe um grupo com esse nome neste evento.');
}

/// A pessoa está vinculada a um participante ou é responsável por alguém.
class PersonInUseException extends DomainException {
  const PersonInUseException()
    : super(
        'Esta pessoa está vinculada a um evento e não pode ser excluída. '
        'Remova os vínculos primeiro.',
      );
}

/// O registro solicitado não existe mais.
class EntityNotFoundException extends DomainException {
  const EntityNotFoundException(super.message);
}

/// Um grupo recebeu um participante que não pertence ao evento.
class InvalidGroupMemberException extends DomainException {
  const InvalidGroupMemberException()
    : super('O grupo só pode conter participantes deste evento.');
}

/// O evento já tem um sorteio ativo e suas regras estão congeladas.
class ActiveDrawException extends DomainException {
  const ActiveDrawException()
    : super(
        'Este evento já foi sorteado. Invalide o sorteio antes de alterar '
        'participantes, pessoas ou grupos.',
      );
}

/// O evento mudou desde que a revisão do sorteio foi aberta.
class PairingRevisionConflictException extends DomainException {
  const PairingRevisionConflictException()
    : super(
        'Os dados do evento mudaram durante a revisão. Atualize a página e '
        'revise o sorteio novamente.',
      );
}

/// Já existe outro sorteio ativo no evento.
class ActiveDrawExistsException extends DomainException {
  const ActiveDrawExistsException()
    : super('Este evento já tem um sorteio ativo.');
}

/// Um ID de sorteio antigo não pode ser reutilizado, mesmo após invalidação.
class DrawIdConflictException extends DomainException {
  const DrawIdConflictException()
    : super(
        'Não foi possível salvar este sorteio. Gere um novo resultado e tente novamente.',
      );
}
