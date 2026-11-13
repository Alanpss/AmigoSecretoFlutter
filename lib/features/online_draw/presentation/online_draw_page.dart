import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../groups/domain/group.dart';
import '../data/firebase_configuration.dart';
import '../data/online_draw_client.dart';
import '../data/online_draw_draft_repository.dart';
import '../data/online_draft_local_copy_repository.dart';
import 'online_event_workspace.dart';

class OnlineDrawPage extends ConsumerStatefulWidget {
  const OnlineDrawPage({super.key, this.draftId, this.sourceLocalEventId});

  final String? draftId;
  final String? sourceLocalEventId;

  @override
  ConsumerState<OnlineDrawPage> createState() => _OnlineDrawPageState();
}

class _OnlineDrawPageState extends ConsumerState<OnlineDrawPage> {
  final _eventName = TextEditingController();
  final _rows = <_ParticipantInput>[_ParticipantInput(), _ParticipantInput()];
  final _groups = <_OnlineGroupInput>[];
  final _draftEventId = const Uuid().v4();
  List<OnlineLink> _links = [];
  final _revokedLinks = <String>{};
  String? _createdEventId;
  int _pairingRevision = 0;
  bool _busy = false;
  bool _draftReady = false;
  bool _draftSaved = false;
  bool _drawNeedsRefresh = false;
  bool _needsPersonalDataConfirmation = false;
  bool _remoteEventMayExist = false;
  String? _error;
  Timer? _saveTimer;
  StreamSubscription<User?>? _authSubscription;
  User? _user;

  OnlineDrawDraftRepository get _draftRepository =>
      OnlineDrawDraftRepository(ref.read(appDatabaseProvider).database);

  @override
  void initState() {
    super.initState();
    if (FirebaseConfiguration.canInitialize) {
      final auth = FirebaseAuth.instance;
      _user = auth.currentUser;
      _authSubscription = auth.authStateChanges().listen((user) {
        if (mounted) setState(() => _user = user);
      });
    }
    unawaited(_restoreDraft());
  }

  Future<void> _restoreDraft() async {
    final draft = widget.draftId == null
        ? null
        : await _draftRepository.load(eventId: widget.draftId);
    if (!mounted) return;
    if (draft != null) {
      _eventName.text = draft['eventName'] as String? ?? '';
      final savedRows = draft['participants'];
      if (savedRows is List && savedRows.isNotEmpty) {
        for (final row in _rows) {
          row.dispose();
        }
        _rows.clear();
        for (final value in savedRows) {
          if (value is! Map) continue;
          final row = _ParticipantInput(id: value['id'] as String?)
            ..name.text = value['name'] as String? ?? ''
            ..recipient.text = value['recipientName'] as String? ?? ''
            ..phone.text = value['recipientPhoneE164'] as String? ?? ''
            ..isActive = value['isActive'] as bool? ?? true;
          _rows.add(row);
        }
        if (_rows.length < 2) _rows.add(_ParticipantInput());
      }
      final savedGroups = draft['groups'];
      if (savedGroups is List) {
        for (final value in savedGroups) {
          if (value is! Map) continue;
          final group = _OnlineGroupInput(
            id: value['id'] as String? ?? const Uuid().v4(),
            name: value['name'] as String? ?? '',
            type: GroupTypeLabel.fromStorage(value['type'] as String?),
            restrictionEnabled: value['restrictionEnabled'] as bool? ?? true,
            participantIds: (value['participantIds'] as List? ?? const [])
                .whereType<String>()
                .toSet(),
          );
          _groups.add(group);
        }
      } else {
        _restoreLegacyGroups(draft['groupsText'] as String? ?? '');
      }
      final savedLinks = draft['links'];
      if (savedLinks is List) {
        _links = [
          for (final value in savedLinks)
            if (value is Map)
              OnlineLink(
                participantId: value['participantId'] as String? ?? '',
                participantName: value['participantName'] as String? ?? '',
                recipientName: value['recipientName'] as String? ?? '',
                recipientPhoneE164: value['recipientPhoneE164'] as String?,
                url: value['url'] as String? ?? '',
              ),
        ];
      }
      final revoked = draft['revokedUrls'];
      if (revoked is List) _revokedLinks.addAll(revoked.whereType<String>());
      _createdEventId = draft['eventId'] as String?;
      _pairingRevision =
          draft['pairingRevision'] as int? ?? (_links.isNotEmpty ? 1 : 0);
      _drawNeedsRefresh = draft['drawNeedsRefresh'] as bool? ?? false;
      _needsPersonalDataConfirmation =
          draft['needsPersonalDataConfirmation'] as bool? ?? false;
      _remoteEventMayExist = draft['remoteEventMayExist'] as bool? ?? false;
    }
    _eventName.addListener(_scheduleDraftSave);
    for (final row in _rows) {
      _addRowListeners(row);
    }
    for (final group in _groups) {
      _addGroupListeners(group);
    }
    setState(() {
      _draftReady = true;
      _draftSaved = draft != null;
    });
    if (widget.sourceLocalEventId != null) {
      unawaited(_copyLocalEvent(widget.sourceLocalEventId!));
    }
  }

  Future<void> _copyLocalEvent(String eventId) async {
    final event = await ref.read(eventProvider(eventId).future);
    final participants = await ref.read(participantsProvider(eventId).future);
    final groups = await ref.read(groupsProvider(eventId).future);
    if (!mounted) return;
    final activeCount = participants
        .where((p) => p.participant.isActive)
        .length;
    final contactCount = participants.where((p) => p.hasContact).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copiar para evento online?'),
        content: Text(
          'Será criada uma cópia de “${event.name}” com ${participants.length} '
          'participantes ($activeCount ativos), $contactCount com contato e '
          '${groups.length} grupos. A origem ficará intacta. Nomes e contatos serão enviados '
          'ao serviço quando você confirmar o sorteio. Nenhum resultado '
          'existente será copiado. Será criado um evento online separado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar cópia'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    for (final row in _rows) {
      row.dispose();
    }
    _rows.clear();
    for (final view in participants) {
      final recipient = view.guardian ?? view.person;
      final row = _ParticipantInput(id: view.participant.id)
        ..name.text = view.person.displayName
        ..recipient.text = recipient.displayName
        ..phone.text = recipient.phoneE164 ?? ''
        ..isActive = view.participant.isActive;
      _rows.add(row);
      _addRowListeners(row);
    }
    if (_rows.length < 2) _rows.add(_ParticipantInput());
    for (final group in _groups) {
      group.dispose();
    }
    _groups
      ..clear()
      ..addAll([
        for (final source in groups)
          _OnlineGroupInput(
            id: source.id,
            name: source.name,
            type: source.type,
            restrictionEnabled: source.restrictionEnabled,
            participantIds: source.memberParticipantIds.toSet(),
          ),
      ]);
    for (final group in _groups) {
      _addGroupListeners(group);
    }
    _eventName.text = event.name;
    _links = [];
    _createdEventId = null;
    _pairingRevision = 0;
    _revokedLinks.clear();
    _drawNeedsRefresh = false;
    _needsPersonalDataConfirmation = true;
    _scheduleDraftSave();
    if (mounted) setState(() {});
  }

  Future<void> _copyOnlineDraftToLocal() async {
    final draft = await _draftRepository.load(
      eventId: _createdEventId ?? _draftEventId,
    );
    if (draft == null) {
      if (mounted) {
        setState(
          () => _error = 'Não há rascunho online salvo neste navegador.',
        );
      }
      return;
    }
    final participants = (draft['participants'] as List? ?? const [])
        .whereType<Map>()
        .toList(growable: false);
    final groups = (draft['groups'] as List? ?? const [])
        .whereType<Map>()
        .where((group) => (group['name'] as String? ?? '').trim().isNotEmpty)
        .toList(growable: false);
    final active = participants
        .where((row) => row['isActive'] as bool? ?? true)
        .length;
    final contacts = participants
        .where(
          (row) => (row['recipientName'] as String? ?? '').trim().isNotEmpty,
        )
        .length;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar cópia local?'),
        content: Text(
          'Será criado um novo evento local “${draft['eventName'] ?? ''}” '
          'com ${participants.length} participantes ($active ativos), '
          '$contacts destinatários e ${groups.length} grupos. O sorteio, os resultados e os links '
          'online não serão copiados nem alterados. A cópia ficará como rascunho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Criar cópia local'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final database = ref.read(appDatabaseProvider).database;
      final eventId = await OnlineDraftLocalCopyRepository(database)
          .createCopy(draft);
      if (mounted) {
        refreshEvents(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cópia local criada como rascunho.')),
        );
        // Keep the online event and its links in place; open the copy separately.
        context.push('/events/$eventId');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível criar a cópia local. Confira os dados do rascunho e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addRowListeners(_ParticipantInput row) {
    row.name.addListener(_scheduleDraftSave);
    row.recipient.addListener(_scheduleDraftSave);
    row.phone.addListener(_scheduleDraftSave);
  }

  void _addGroupListeners(_OnlineGroupInput group) {
    group.name.addListener(_scheduleDraftSave);
  }

  void _restoreLegacyGroups(String text) {
    for (final line
        in text.split('\n').where((value) => value.trim().isNotEmpty)) {
      final parts = line.split(':');
      if (parts.length != 2 || parts.first.trim().isEmpty) continue;
      final names = parts.last
          .split(',')
          .map((value) => value.trim().toLowerCase());
      final members = _rows
          .where((row) => names.contains(row.name.text.trim().toLowerCase()))
          .map((row) => row.id)
          .toSet();
      _groups.add(
        _OnlineGroupInput(
          name: parts.first.trim(),
          type: GroupType.other,
          participantIds: members,
        ),
      );
    }
  }

  void _scheduleDraftSave() {
    if (!_draftReady) return;
    _saveTimer?.cancel();
    if (mounted) {
      setState(() {
        _draftSaved = false;
        if (_links.isNotEmpty) _drawNeedsRefresh = true;
      });
    }
    _saveTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(_saveDraft());
    });
  }

  Future<void> _saveDraft() async {
    if (!_draftReady) return;
    final hasContent =
        _eventName.text.trim().isNotEmpty ||
        _rows.any(
          (row) =>
              row.name.text.trim().isNotEmpty ||
              row.recipient.text.trim().isNotEmpty ||
              row.phone.text.trim().isNotEmpty,
        ) ||
        _groups.any((group) => group.name.text.trim().isNotEmpty) ||
        _links.isNotEmpty;
    if (!hasContent) return;
    try {
      await _draftRepository.save({
        'eventId': _createdEventId ?? _draftEventId,
        'eventName': _eventName.text,
        'pairingRevision': _pairingRevision,
        'drawNeedsRefresh': _drawNeedsRefresh,
        'needsPersonalDataConfirmation': _needsPersonalDataConfirmation,
        'groups': [
          for (final group in _groups)
            {
              'id': group.id,
              'name': group.name.text,
              'type': group.type.storageValue,
              'restrictionEnabled': group.restrictionEnabled,
              'participantIds': group.participantIds.toList(growable: false),
            },
        ],
        'participants': [
          for (final row in _rows)
            {
              'id': row.id,
              'name': row.name.text,
              'recipientName': row.recipient.text,
              'recipientPhoneE164': row.phone.text,
              'isActive': row.isActive,
            },
        ],
        // These are bearer links. Keep them on this device and exclude the
        // onlineDrafts store from BackupService.
        'links': [
          for (final link in _links)
            {
              'participantId': link.participantId,
              'participantName': link.participantName,
              'recipientName': link.recipientName,
              'recipientPhoneE164': link.recipientPhoneE164,
              'url': link.url,
            },
        ],
        'revokedUrls': _revokedLinks.toList(growable: false),
        'remoteEventMayExist': _remoteEventMayExist,
      });
      if (mounted) setState(() => _draftSaved = true);
    } catch (_) {
      if (mounted) setState(() => _draftSaved = false);
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    unawaited(_authSubscription?.cancel());
    unawaited(_saveDraft());
    _eventName.removeListener(_scheduleDraftSave);
    _eventName.dispose();
    for (final row in _rows) {
      row.name.removeListener(_scheduleDraftSave);
      row.recipient.removeListener(_scheduleDraftSave);
      row.phone.removeListener(_scheduleDraftSave);
      row.dispose();
    }
    for (final group in _groups) {
      group.name.removeListener(_scheduleDraftSave);
      group.dispose();
    }
    super.dispose();
  }

  String _googleSignInErrorMessage(FirebaseAuthException error) {
    final code = error.code.replaceFirst('auth/', '');
    return switch (code) {
      'unauthorized-domain' => 'Este endereço não está autorizado no Firebase Authentication. Cadastre o domínio publicado em Authentication > Settings > Authorized domains.',
      'operation-not-allowed' => 'O login Google está desativado neste projeto Firebase. Habilite Google em Authentication > Sign-in method.',
      'popup-blocked' => 'O navegador bloqueou a janela do Google. Permita pop-ups para este endereço e tente novamente.',
      'popup-closed-by-user' => 'A janela de login foi fechada antes de concluir. Abra o login novamente para continuar.',
      'cancelled-popup-request' => 'Já existe uma janela de login aberta. Conclua essa janela ou feche-a antes de tentar novamente.',
      'network-request-failed' => 'Não foi possível conectar ao Firebase ou ao Google. Confira a conexão e tente novamente.',
      'invalid-api-key' => 'A chave do app Web Firebase não foi aceita. Confira as opções FIREBASE_* usadas neste build.',
      'web-storage-unsupported' => 'O navegador não disponibilizou armazenamento para manter a sessão. Habilite armazenamento local e tente novamente.',
      _ =>
        'Não foi possível concluir o login Google (código: $code). Confira o provedor e as opções do app Web Firebase.',
    };
  }

  Future<void> _signIn() async {
    final configurationError = FirebaseConfiguration.configurationError;
    if (configurationError != null) {
      setState(() => _error = configurationError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _error = _googleSignInErrorMessage(error);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível concluir o login Google. Confira a conexão e tente novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) setState(() => _user = null);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível sair da conta. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createDraw() async {
    final apiBaseUrl = const String.fromEnvironment('ONLINE_DRAW_API_BASE_URL');
    if (apiBaseUrl.isEmpty) {
      setState(() {
        _error = 'O endereço do serviço online ainda não foi configurado.';
      });
      return;
    }
    final participants = <Map<String, Object?>>[];
    final names = <String>{};
    for (final row in _rows) {
      final name = row.name.text.trim();
      final recipient = row.recipient.text.trim();
      final phone = row.phone.text.trim();
      if (name.isEmpty || recipient.isEmpty) {
        setState(() {
          _error = 'Preencha o nome e o destinatário de cada participante.';
        });
        return;
      }
      if (!names.add(name.toLowerCase())) {
        setState(() {
          _error = 'Use nomes diferentes para identificar os participantes.';
        });
        return;
      }
      if (!row.isActive) continue;
      participants.add({
        'id': row.id,
        'name': name,
        'recipientName': recipient,
        if (phone.isNotEmpty) 'recipientPhoneE164': phone,
      });
    }
    if (_eventName.text.trim().isEmpty) {
      setState(() {
        _error = 'Informe o nome do evento.';
      });
      return;
    }
    final groups = <Map<String, Object?>>[];
    for (final group in _groups) {
      final activeMemberIds = group.participantIds
          .where((id) => _rows.any((row) => row.id == id && row.isActive))
          .toList(growable: false);
      if (group.name.text.trim().isEmpty) {
        setState(() {
          _error = 'Cada grupo precisa de um nome.';
        });
        return;
      }
      if (activeMemberIds.length < 2) continue;
      groups.add({
        'id': group.id,
        'name': group.name.text.trim(),
        'participantIds': activeMemberIds,
        'isEnabled': group.restrictionEnabled,
      });
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = OnlineDrawClient(
        apiBaseUrl: apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
        auth: FirebaseAuth.instance,
      );
      final eventId = _createdEventId ?? _draftEventId;
      final nextRevision = _pairingRevision + 1;
      _remoteEventMayExist = true;
      await _saveDraft();
      final links = await client.createDraw(
        eventId: eventId,
        pairingRevision: nextRevision,
        participants: participants,
        groups: groups,
      );
      if (mounted) {
        setState(() {
          _links = links;
          _createdEventId = eventId;
          _pairingRevision = nextRevision;
          _revokedLinks.clear();
          _drawNeedsRefresh = false;
          _needsPersonalDataConfirmation = false;
        });
        await _saveDraft();
      }
    } on OnlineDrawImpossibleClientException {
      if (mounted) {
        setState(() {
          _error = 'As restrições dos grupos não permitem completar o sorteio. Desative uma restrição, ajuste os grupos ou adicione participantes.';
        });
      }
    } on OnlineDrawServiceUnavailableException {
      if (mounted) {
        setState(() {
          _error =
              'Não foi possível alcançar a API do sorteio. Confirme que '
              'o serviço Dart está rodando no terminal da API na porta 8090.';
        });
      }
    } on OnlineDrawAuthenticationException {
      if (mounted) {
        setState(() {
          _error =
              'Sua sessão não foi reconhecida pelo serviço. Saia e entre '
              'novamente com o Google pelo Auth Emulator.';
        });
      }
    } on OnlineDrawAccessException {
      if (mounted) {
        setState(() {
          _error =
              'Esta sessão não tem acesso a este evento online. Entre '
              'com a mesma conta usada para criá-lo.';
        });
      }
    } on OnlineDrawConflictException {
      if (mounted) {
        setState(() {
          _error =
              'O evento online mudou em outra sessão. Volte à lista, '
              'abra o evento novamente e tente mais uma vez.';
        });
      }
    } on OnlineDrawInvalidDataException {
      if (mounted) {
        setState(() {
          _error =
              'O serviço rejeitou os dados do sorteio. Confira se há '
              'pelo menos duas pessoas ativas, nomes e destinatários válidos.';
        });
      }
    } on OnlineDrawServerException {
      if (mounted) {
        setState(() {
          _error =
              'A API recebeu o pedido, mas não conseguiu salvar o '
              'sorteio. Confira se o Firestore Emulator está ativo e tente novamente.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível criar o sorteio. Confira os dados e tente novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _confirmAndCreateDraw() async {
    if (_links.isEmpty) {
      if (_needsPersonalDataConfirmation) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enviar dados e sortear?'),
            content: const Text(
              'Os nomes e contatos desta cópia serão enviados ao serviço online '
              'para criar o sorteio e os links individuais. O evento local '
              'original permanecerá inalterado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Voltar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enviar e sortear'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
      await _createDraw();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refazer o sorteio?'),
        content: const Text(
          'Os links atuais deixarão de funcionar e todos os participantes receberão novos resultados. Você precisará encaminhar os novos links novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Manter sorteio atual'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Invalidar e sortear novamente'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _createDraw();
  }

  void _addGroup() {
    final group = _OnlineGroupInput();
    _addGroupListeners(group);
    setState(() => _groups.add(group));
    _scheduleDraftSave();
  }

  void _removeParticipant(_ParticipantInput row) {
    row.name.removeListener(_scheduleDraftSave);
    row.recipient.removeListener(_scheduleDraftSave);
    row.phone.removeListener(_scheduleDraftSave);
    for (final group in _groups) {
      group.participantIds.remove(row.id);
    }
    _rows.remove(row);
    row.dispose();
    setState(() {});
    _scheduleDraftSave();
  }

  void _removeGroup(_OnlineGroupInput group) {
    group.name.removeListener(_scheduleDraftSave);
    _groups.remove(group);
    group.dispose();
    setState(() {});
    _scheduleDraftSave();
  }

  Future<void> _openWhatsApp(OnlineLink link) async {
    final digits = link.recipientPhoneE164?.replaceAll(RegExp(r'[^0-9]'), '');
    final message =
        'Olá! Este é o seu link individual do amigo secreto: ${link.url}';
    final uri = Uri.https('wa.me', digits == null ? '/' : '/$digits', {
      'text': message,
    });
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir o WhatsApp. Copie o link e tente novamente.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _revokeLink(OnlineLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revogar link?'),
        content: Text(
          'O link de ${link.participantName} deixará de mostrar o resultado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revogar'),
          ),
        ],
      ),
    );
    if (confirmed != true || _createdEventId == null) return;
    try {
      final apiBaseUrl = const String.fromEnvironment(
        'ONLINE_DRAW_API_BASE_URL',
      );
      final token = Uri.parse(link.url).fragment.split('/').last;
      await OnlineDrawClient(
        apiBaseUrl: apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
        auth: FirebaseAuth.instance,
      ).revoke(eventId: _createdEventId!, token: token);
      if (mounted) {
        setState(() {
          _revokedLinks.add(link.url);
        });
        await _saveDraft();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível revogar o link. Tente novamente.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseConfiguration.isConfigured) {
      return const _OnlineSetupNotice();
    }
    final user = _user;
    return DefaultTabController(
      length: 4,
      child: Builder(
        builder: (tabContext) => Scaffold(
          appBar: AppBar(
            title: const Text('Evento online'),
            actions: [
              IconButton(
                tooltip: 'Voltar à lista de eventos online',
                onPressed: () => context.go('/online'),
                icon: const Icon(Icons.list_alt),
              ),
              if (user != null)
                PopupMenuButton<String>(
                  tooltip: 'Mais opções',
                  onSelected: (action) {
                    if (action == 'copy') {
                      _copyOnlineDraftToLocal();
                    } else if (action == 'sign-out') {
                      _signOut();
                    }
                  },
                  itemBuilder: (context) => [
                    if (_draftReady)
                      const PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                          leading: Icon(Icons.copy_all_outlined),
                          title: Text('Copiar como evento local'),
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'sign-out',
                      child: ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Sair da conta'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              _OnlineWorkspaceHeader(
                eventName: _eventName.text.trim(),
                user: user,
                draftReady: _draftReady,
                draftSaved: _draftSaved,
              ),
              if (_busy) const LinearProgressIndicator(minHeight: 3),
              if (_error != null)
                _OnlineErrorBanner(
                  message: _error!,
                  onDismiss: () {
                    setState(() => _error = null);
                  },
                ),
              if (_links.isNotEmpty && _drawNeedsRefresh)
                _OnlineNotice(
                  icon: Icons.info_outline,
                  message: 'Os dados mudaram. Os links atuais ainda mostram o sorteio anterior; revise e refaça o sorteio para atualizá-los.',
                  isWarning: true,
                ),
              Expanded(
                child: user == null
                    ? _buildSignInPanel(context)
                    : OnlineEventWorkspace(
                        eventTab: _buildEventTab(context),
                        participantsTab: _buildParticipantsTab(context),
                        groupsTab: _buildGroupsTab(context),
                        reviewTab: _buildReviewTab(context),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInPanel(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Icon(
                      Icons.lock_person_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Entre para organizar seu evento',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sua conta protege a área de organização. Participantes não precisam entrar: cada um abre somente o próprio link.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (FirebaseConfiguration.configurationError
                      case final error?) ...[
                    _OnlineNotice(
                      icon: Icons.settings_outlined,
                      message: error,
                      isWarning: true,
                    ),
                    const SizedBox(height: 16),
                  ] else if (FirebaseConfiguration.useEmulators) ...[
                    const _OnlineNotice(
                      icon: Icons.science_outlined,
                      message: 'Modo de teste local: o login Google é simulado. Na janela aberta, use “Add new account” e crie uma conta fictícia; não informe a senha da sua conta Google real.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: _busy || !FirebaseConfiguration.canInitialize
                        ? null
                        : _signIn,
                    icon: const Icon(Icons.login),
                    label: const Text('Entrar com Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildEventTab(BuildContext context) => _stepList(
    context,
    step: 'ETAPA 1 DE 4',
    title: 'Dados do evento',
    subtitle: 'Dê um nome para encontrar e retomar este sorteio depois.',
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _eventName,
                enabled: _draftReady,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome do evento',
                  hintText: 'Ex.: Amigo secreto da família',
                  prefixIcon: Icon(Icons.celebration_outlined),
                ),
              ),
              const SizedBox(height: 16),
              const _OnlineNotice(
                icon: Icons.visibility_off_outlined,
                message: 'O resultado é calculado no servidor. Nesta área você verá os links individuais, sem os pares do sorteio.',
              ),
              const SizedBox(height: 8),
              const _OnlineNotice(
                icon: Icons.save_outlined,
                message: 'O rascunho e os links ficam salvos neste navegador. Use o mesmo perfil e endereço para retomá-los.',
              ),
            ],
          ),
        ),
      ),
      _OnlineStepFooter(label: 'Continuar para participantes', nextIndex: 1),
    ],
  );

  Widget _buildParticipantsTab(BuildContext context) {
    final activeCount = _rows.where((row) => row.isActive).length;
    return _stepList(
      context,
      step: 'ETAPA 2 DE 4',
      title: 'Participantes e contatos',
      subtitle:
          'Cadastre quem participa e para quem cada link deve ser encaminhado.',
      trailing: _CountBadge(
        label: '$activeCount ativos',
        icon: Icons.people_alt_outlined,
      ),
      children: [
        _OnlineNotice(
          icon: Icons.info_outline,
          message: 'O destinatário é quem receberá o link. O resultado continua pertencendo ao participante.',
        ),
        for (var index = 0; index < _rows.length; index++)
          _OnlineParticipantCard(
            key: ValueKey(_rows[index].id),
            row: _rows[index],
            index: index,
            enabled: _draftReady,
            canRemove: _rows.length > 2,
            onActiveChanged: (value) {
              setState(() => _rows[index].isActive = value);
              _scheduleDraftSave();
            },
            onRemove: () => _removeParticipant(_rows[index]),
          ),
        OutlinedButton.icon(
          onPressed: !_draftReady || _rows.length >= 200
              ? null
              : () {
                  final row = _ParticipantInput();
                  _addRowListeners(row);
                  setState(() => _rows.add(row));
                  _scheduleDraftSave();
                },
          icon: const Icon(Icons.person_add_alt_1),
          label: Text(
            _rows.length >= 200
                ? 'Limite de 200 participantes atingido'
                : 'Adicionar participante',
          ),
        ),
        _OnlineStepFooter(label: 'Continuar para grupos', nextIndex: 2),
      ],
    );
  }

  Widget _buildGroupsTab(BuildContext context) => _stepList(
    context,
    step: 'ETAPA 3 DE 4',
    title: 'Grupos e restrições',
    subtitle: 'Escolha quais pessoas não podem tirar umas às outras.',
    children: [
      const _OnlineNotice(
        icon: Icons.groups_2_outlined,
        message: 'A restrição vale para cada grupo em que estiver ativada. Ela não é herdada do responsável. Grupos online são independentes dos grupos locais.',
      ),
      if (_groups.isEmpty)
        const _OnlineEmptyCard(
          icon: Icons.group_add_outlined,
          title: 'Nenhum grupo criado',
          message: 'Se houver famílias ou casais que não devem se sortear entre si, crie os grupos aqui.',
        ),
      for (final group in _groups)
        Card(
          key: ValueKey('group-card-${group.id}'),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: ValueKey(group.id),
            initiallyExpanded: false,
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                group.type == GroupType.family
                    ? Icons.home_outlined
                    : group.type == GroupType.couple
                    ? Icons.favorite_outline
                    : Icons.groups_outlined,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(
              group.name.text.trim().isEmpty
                  ? 'Novo grupo'
                  : group.name.text.trim(),
            ),
            subtitle: Text(
              '${group.type.label} · ${group.participantIds.length} pessoas · '
              '${group.restrictionEnabled ? 'restrição ativa' : 'sem restrição'}',
            ),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              TextField(
                controller: group.name,
                enabled: _draftReady,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome do grupo'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GroupType>(
                initialValue: group.type,
                decoration: const InputDecoration(labelText: 'Tipo de grupo'),
                items: [
                  for (final type in GroupType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: !_draftReady
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => group.type = value);
                        _scheduleDraftSave();
                      },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Impedir sorteios dentro do grupo'),
                subtitle: const Text(
                  'Os integrantes ainda podem tirar uns aos outros se desligada.',
                ),
                value: group.restrictionEnabled,
                onChanged: !_draftReady
                    ? null
                    : (value) {
                        setState(() => group.restrictionEnabled = value);
                        _scheduleDraftSave();
                      },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Participantes do grupo',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              for (var index = 0; index < _rows.length; index++)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: group.participantIds.contains(_rows[index].id),
                  title: Text(
                    _rows[index].name.text.trim().isEmpty
                        ? 'Participante ${index + 1}'
                        : _rows[index].name.text.trim(),
                  ),
                  onChanged: !_draftReady
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected == true) {
                              group.participantIds.add(_rows[index].id);
                            } else {
                              group.participantIds.remove(_rows[index].id);
                            }
                          });
                          _scheduleDraftSave();
                        },
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: !_draftReady ? null : () => _removeGroup(group),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover grupo'),
                ),
              ),
            ],
          ),
        ),
      OutlinedButton.icon(
        onPressed: !_draftReady ? null : _addGroup,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar grupo'),
      ),
      _OnlineStepFooter(label: 'Continuar para revisão', nextIndex: 3),
    ],
  );

  Widget _buildReviewTab(BuildContext context) {
    final activeCount = _rows.where((row) => row.isActive).length;
    final restrictedGroupCount = _groups
        .where((group) => group.restrictionEnabled)
        .length;
    return _stepList(
      context,
      step: 'ETAPA 4 DE 4',
      title: _links.isEmpty ? 'Revisar e sortear' : 'Revisão e links',
      subtitle: _links.isEmpty
          ? 'Confira os dados antes de confirmar o sorteio.'
          : 'Envie cada link para o destinatário correto. Os pares continuam ocultos.',
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryTile(
              icon: Icons.people_alt_outlined,
              label: 'Participantes ativos',
              value: '$activeCount',
            ),
            _SummaryTile(
              icon: Icons.groups_outlined,
              label: 'Grupos restritos',
              value: '$restrictedGroupCount',
            ),
            _SummaryTile(
              icon: _links.isEmpty
                  ? Icons.pending_actions_outlined
                  : Icons.link_outlined,
              label: 'Estado',
              value: _links.isEmpty ? 'Rascunho' : '${_links.length} links',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _OnlineNotice(
          icon: Icons.shield_outlined,
          message: 'O servidor guarda o sorteio, mas não devolve os pares para esta tela. Quem receber um link poderá abrir aquele resultado.',
        ),
        if (_links.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pronto para sortear?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'O sorteio será salvo antes de gerar os links. Nenhuma mensagem é enviada automaticamente.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: !_draftReady || _busy
                        ? null
                        : _confirmAndCreateDraw,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Sortear e gerar links'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          if (_drawNeedsRefresh)
            const _OnlineNotice(
              icon: Icons.warning_amber_outlined,
              message: 'Há alterações desde o sorteio. Refazer o sorteio invalida os links anteriores.',
              isWarning: true,
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Links individuais',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Confira o participante e o destinatário. Encaminhe manualmente pelo WhatsApp.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: !_draftReady || _busy
                        ? null
                        : _confirmAndCreateDraw,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refazer'),
                  ),
                ],
              ),
            ),
          ),
          for (final link in _links)
            _OnlineLinkCard(
              link: link,
              revoked: _revokedLinks.contains(link.url),
              onWhatsApp: () => _openWhatsApp(link),
              onRevoke: () => _revokeLink(link),
            ),
        ],
      ],
    );
  }

  Widget _stepList(
    BuildContext context, {
    required String step,
    required String title,
    required String subtitle,
    Widget? trailing,
    required List<Widget> children,
  }) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 940),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OnlineSectionHeading(
                step: step,
                title: title,
                subtitle: subtitle,
                trailing: trailing,
              ),
              const SizedBox(height: 20),
              ...children.map(
                (child) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ParticipantInput {
  _ParticipantInput({String? id}) : id = id ?? const Uuid().v4();

  final String id;
  final name = TextEditingController();
  final recipient = TextEditingController();
  final phone = TextEditingController();
  bool isActive = true;
  void dispose() {
    name.dispose();
    recipient.dispose();
    phone.dispose();
  }
}

class _OnlineGroupInput {
  _OnlineGroupInput({
    String? id,
    String name = '',
    this.type = GroupType.family,
    this.restrictionEnabled = true,
    Set<String>? participantIds,
  }) : id = id ?? const Uuid().v4(),
       name = TextEditingController(text: name),
       participantIds = participantIds ?? <String>{};

  final String id;
  final TextEditingController name;
  GroupType type;
  bool restrictionEnabled;
  final Set<String> participantIds;

  void dispose() => name.dispose();
}

class _OnlineWorkspaceHeader extends StatelessWidget {
  const _OnlineWorkspaceHeader({
    required this.eventName,
    required this.user,
    required this.draftReady,
    required this.draftSaved,
  });

  final String eventName;
  final User? user;
  final bool draftReady;
  final bool draftSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final title = eventName.isEmpty ? 'Organize seu sorteio' : eventName;
    final status = !draftReady
        ? 'Carregando rascunho'
        : eventName.isEmpty
        ? 'Pronto para começar'
        : draftSaved
        ? 'Salvo neste dispositivo'
        : 'Salvando alterações';
    final intro = user == null
        ? 'Quatro etapas simples, sem revelar os pares na área do organizador.'
        : 'Conectado como ${user!.displayName ?? user!.email ?? 'organizador'}';
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          intro,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
    final stateChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            draftReady && (draftSaved || eventName.isEmpty)
                ? Icons.cloud_done_outlined
                : Icons.sync,
            size: 18,
            color: theme.colorScheme.onPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(
            width < 600 ? 12 : 20,
            12,
            width < 600 ? 12 : 20,
            12,
          ),
          padding: EdgeInsets.all(width < 600 ? 18 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: width < 640
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleBlock, const SizedBox(height: 14), stateChip],
                )
              : Row(
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 20),
                    stateChip,
                  ],
                ),
        ),
      ),
    );
  }
}

class _OnlineErrorBanner extends StatelessWidget {
  const _OnlineErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Card(
          color: colors.errorContainer,
          child: ListTile(
            leading: Icon(Icons.error_outline, color: colors.onErrorContainer),
            title: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
            trailing: IconButton(
              tooltip: 'Dispensar aviso',
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: colors.onErrorContainer),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnlineNotice extends StatelessWidget {
  const _OnlineNotice({
    required this.icon,
    required this.message,
    this.isWarning = false,
  });

  final IconData icon;
  final String message;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isWarning
        ? colors.tertiaryContainer
        : colors.secondaryContainer;
    final foreground = isWarning
        ? colors.onTertiaryContainer
        : colors.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineSectionHeading extends StatelessWidget {
  const _OnlineSectionHeading({
    required this.step,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String step;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          step,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      if (trailing != null) ...[const SizedBox(height: 10), trailing!],
    ],
  );
}

class _OnlineParticipantCard extends StatelessWidget {
  const _OnlineParticipantCard({
    super.key,
    required this.row,
    required this.index,
    required this.enabled,
    required this.canRemove,
    required this.onActiveChanged,
    required this.onRemove,
  });

  final _ParticipantInput row;
  final int index;
  final bool enabled;
  final bool canRemove;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  row.name.text.trim().isEmpty
                      ? 'Participante ${index + 1}'
                      : row.name.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: 'Remover participante',
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: row.name,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome do participante',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: row.recipient,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Destinatário do link',
              helperText: 'Pode ser o próprio participante ou seu responsável.',
              prefixIcon: Icon(Icons.forward_to_inbox_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: row.phone,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp do destinatário (opcional)',
              hintText: '+55 11 99999-9999',
              prefixIcon: Icon(Icons.call_outlined),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Participa do sorteio'),
            subtitle: Text(
              row.isActive ? 'Será incluído no sorteio.' : 'Fora do sorteio.',
            ),
            value: row.isActive,
            onChanged: enabled ? onActiveChanged : null,
          ),
        ],
      ),
    ),
  );
}

class _OnlineStepFooter extends StatelessWidget {
  const _OnlineStepFooter({required this.label, required this.nextIndex});

  final String label;
  final int nextIndex;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: FilledButton.tonalIcon(
      onPressed: () => DefaultTabController.of(context).animateTo(nextIndex),
      icon: const Icon(Icons.arrow_forward),
      label: Text(label),
    ),
  );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 18), label: Text(label));
}

class _OnlineEmptyCard extends StatelessWidget {
  const _OnlineEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(message),
        ],
      ),
    ),
  );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 600
        ? MediaQuery.sizeOf(context).width - 64
        : 190,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 3),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    ),
  );
}

class _OnlineLinkCard extends StatelessWidget {
  const _OnlineLinkCard({
    required this.link,
    required this.revoked,
    required this.onWhatsApp,
    required this.onRevoke,
  });

  final OnlineLink link;
  final bool revoked;
  final VoidCallback onWhatsApp;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.participantName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Enviar para ${link.recipientName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (revoked)
                const Chip(
                  avatar: Icon(Icons.link_off, size: 18),
                  label: Text('Revogado'),
                ),
            ],
          ),
          if (!revoked) ...[
            const SizedBox(height: 14),
            SelectableText(
              link.url,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Preparar WhatsApp'),
                ),
                OutlinedButton.icon(
                  onPressed: onRevoke,
                  icon: const Icon(Icons.link_off_outlined),
                  label: const Text('Revogar link'),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _OnlineSetupNotice extends StatelessWidget {
  const _OnlineSetupNotice();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sorteio online')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'O modo online precisa da configuração do Firebase e do endereço do servidor. Siga a seção “Configurar modo online” no README.',
        ),
      ),
    ),
  );
}
