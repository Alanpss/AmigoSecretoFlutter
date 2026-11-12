import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../groups/domain/group.dart';
import '../data/firebase_configuration.dart';
import '../data/online_draw_client.dart';
import '../data/online_draw_draft_repository.dart';

class OnlineDrawPage extends ConsumerStatefulWidget {
  const OnlineDrawPage({super.key});

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
  String? _error;
  Timer? _saveTimer;

  OnlineDrawDraftRepository get _draftRepository =>
      OnlineDrawDraftRepository(ref.read(appDatabaseProvider).database);

  @override
  void initState() {
    super.initState();
    unawaited(_restoreDraft());
  }

  Future<void> _restoreDraft() async {
    final draft = await _draftRepository.load();
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
            ..phone.text = value['recipientPhoneE164'] as String? ?? '';
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
    try {
      await _draftRepository.save({
        'eventId': _createdEventId ?? _draftEventId,
        'eventName': _eventName.text,
        'pairingRevision': _pairingRevision,
        'drawNeedsRefresh': _drawNeedsRefresh,
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
      });
      if (mounted) setState(() => _draftSaved = true);
    } catch (_) {
      if (mounted) setState(() => _draftSaved = false);
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
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

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Não foi possível entrar com Google. Tente novamente.';
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
      if (group.name.text.trim().isEmpty || group.participantIds.length < 2) {
        setState(() {
          _error = 'Cada grupo precisa de um nome e pelo menos duas pessoas.';
        });
        return;
      }
      groups.add({
        'id': group.id,
        'name': group.name.text.trim(),
        'participantIds': group.participantIds.toList(growable: false),
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
        });
        await _saveDraft();
      }
    } on OnlineDrawImpossibleClientException {
      if (mounted) {
        setState(() {
          _error = 'As restrições dos grupos não permitem completar o sorteio. Desative uma restrição, ajuste os grupos ou adicione participantes.';
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
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Sorteio online')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Evento online',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'O sorteio fica no servidor. Esta tela recebe links de entrega, sem mostrar os pares.',
              ),
              const SizedBox(height: 16),
              if (user == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'O login é necessário para organizar o evento. Os participantes abrem seus links individuais sem entrar na conta.',
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _busy ? null : _signIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Entrar com Google'),
                    ),
                  ],
                )
              else ...[
                Text(
                  'Conectado como ${user.displayName ?? user.email ?? 'organizador'}',
                ),
                const SizedBox(height: 4),
                Text(
                  !_draftReady
                      ? 'Carregando rascunho…'
                      : _draftSaved
                      ? 'Rascunho salvo neste dispositivo.'
                      : 'Salvando rascunho…',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_links.isNotEmpty && _drawNeedsRefresh)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text(
                          'Os dados mudaram; os links atuais ainda mostram o sorteio anterior até você refazer o sorteio.',
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _eventName,
                  enabled: _draftReady,
                  decoration: const InputDecoration(
                    labelText: 'Nome do evento',
                  ),
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < _rows.length; index++)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _rows[index].name,
                            enabled: _draftReady,
                            decoration: InputDecoration(
                              labelText: 'Participante ${index + 1}',
                            ),
                          ),
                          TextField(
                            controller: _rows[index].recipient,
                            enabled: _draftReady,
                            decoration: const InputDecoration(
                              labelText: 'Destinatário direto',
                            ),
                          ),
                          TextField(
                            controller: _rows[index].phone,
                            enabled: _draftReady,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp do destinatário (opcional, formato +5511999999999)',
                            ),
                          ),
                          if (_rows.length > 2)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: !_draftReady
                                    ? null
                                    : () => _removeParticipant(_rows[index]),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remover participante'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: !_draftReady || _rows.length >= 200
                        ? null
                        : () {
                            final row = _ParticipantInput();
                            _addRowListeners(row);
                            setState(() {
                              _rows.add(row);
                            });
                            _scheduleDraftSave();
                          },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Adicionar participante'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Grupos e restrições',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pessoas de um grupo com restrição ativa não podem tirar umas às outras. Os grupos online são independentes dos grupos dos eventos locais.',
                ),
                for (final group in _groups)
                  Card(
                    child: ExpansionTile(
                      key: ValueKey(group.id),
                      initiallyExpanded: true,
                      title: Text(
                        group.name.text.trim().isEmpty
                            ? 'Novo grupo'
                            : group.name.text.trim(),
                      ),
                      subtitle: Text(
                        '${group.participantIds.length} participantes · ${group.restrictionEnabled ? 'restrição ativa' : 'sem restrição'}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: group.name,
                            enabled: _draftReady,
                            decoration: const InputDecoration(
                              labelText: 'Nome do grupo',
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonFormField<GroupType>(
                            initialValue: group.type,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de grupo',
                            ),
                            items: [
                              for (final type in GroupType.values)
                                DropdownMenuItem(
                                  value: type,
                                  child: Text(type.label),
                                ),
                            ],
                            onChanged: !_draftReady
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() => group.type = value);
                                    _scheduleDraftSave();
                                  },
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Impedir sorteios dentro do grupo'),
                          subtitle: const Text(
                            'Quando desligada, os integrantes ainda podem tirar uns aos outros.',
                          ),
                          value: group.restrictionEnabled,
                          onChanged: !_draftReady
                              ? null
                              : (value) {
                                  setState(
                                    () => group.restrictionEnabled = value,
                                  );
                                  _scheduleDraftSave();
                                },
                        ),
                        const ListTile(
                          dense: true,
                          title: Text('Participantes do grupo'),
                          subtitle: Text('Selecione pelo menos duas pessoas.'),
                        ),
                        for (var index = 0; index < _rows.length; index++)
                          CheckboxListTile(
                            value: group.participantIds.contains(
                              _rows[index].id,
                            ),
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
                                        group.participantIds.add(
                                          _rows[index].id,
                                        );
                                      } else {
                                        group.participantIds.remove(
                                          _rows[index].id,
                                        );
                                      }
                                    });
                                    _scheduleDraftSave();
                                  },
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: !_draftReady
                                ? null
                                : () => _removeGroup(group),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remover grupo'),
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: !_draftReady ? null : _addGroup,
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('Adicionar grupo'),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: !_draftReady || _busy
                      ? null
                      : _confirmAndCreateDraw,
                  icon: const Icon(Icons.shuffle),
                  label: Text(
                    _links.isEmpty
                        ? 'Sortear e gerar links'
                        : 'Refazer sorteio e invalidar links atuais',
                  ),
                ),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Sair'),
                ),
              ],
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_links.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Links individuais',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text(
                  'Confira a pessoa e o destinatário antes de encaminhar. O WhatsApp abrirá com somente o link; confirme o envio manualmente.',
                ),
                for (final link in _links)
                  Card(
                    child: ListTile(
                      title: Text(link.participantName),
                      subtitle: SelectableText(
                        _revokedLinks.contains(link.url)
                            ? 'Link revogado'
                            : 'Enviar para ${link.recipientName}\n${link.url}',
                      ),
                      trailing: _revokedLinks.contains(link.url)
                          ? const Icon(Icons.link_off)
                          : Wrap(
                              children: [
                                IconButton(
                                  tooltip: 'Abrir WhatsApp',
                                  icon: const Icon(Icons.chat),
                                  onPressed: () => _openWhatsApp(link),
                                ),
                                IconButton(
                                  tooltip: 'Revogar link',
                                  icon: const Icon(Icons.link_off),
                                  onPressed: () => _revokeLink(link),
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantInput {
  _ParticipantInput({String? id}) : id = id ?? const Uuid().v4();

  final String id;
  final name = TextEditingController();
  final recipient = TextEditingController();
  final phone = TextEditingController();
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
