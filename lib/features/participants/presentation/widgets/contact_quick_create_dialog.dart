import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/domain_exceptions.dart';
import '../../domain/phone_number.dart';
import '../../domain/person.dart';

/// Cadastro rápido de um contato que não participa do sorteio.
class ContactQuickCreateDialog extends ConsumerStatefulWidget {
  const ContactQuickCreateDialog({
    super.key,
    this.title = 'Novo contato',
    this.helperText,
  });

  final String title;
  final String? helperText;

  @override
  ConsumerState<ContactQuickCreateDialog> createState() =>
      _ContactQuickCreateDialogState();
}

class _ContactQuickCreateDialogState
    extends ConsumerState<ContactQuickCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }

    final parsed = parsePhoneNumber(_phoneController.text);
    if (!parsed.isValid) {
      setState(() => _error = parsed.error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final person = await ref
          .read(personRepositoryProvider)
          .create(
            name: _nameController.text,
            phoneE164: parsed.e164!.isEmpty ? null : parsed.e164,
          );
      if (mounted) {
        Navigator.of(context).pop<Person>(person);
      }
    } on DomainException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível salvar o contato. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.helperText != null) ...[
                Text(widget.helperText!),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) {
                    return 'Informe o nome.';
                  }
                  if (name.length > 120) {
                    return 'Use no máximo 120 caracteres.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone (opcional)',
                  hintText: '(11) 90000-0001',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar contato'),
        ),
      ],
    );
  }
}
