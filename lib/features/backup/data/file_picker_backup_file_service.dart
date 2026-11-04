import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../domain/backup_document.dart';
import 'backup_service.dart';

class FilePickerBackupFileService implements BackupFileService {
  const FilePickerBackupFileService();

  @override
  Future<BackupSaveResult> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final result = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/json',
    );
    // In download mode, the Web implementation starts a browser download and
    // returns null because browsers do not expose the destination file path.
    if (kIsWeb) return BackupSaveResult.downloadStarted;
    return result == null ? BackupSaveResult.cancelled : BackupSaveResult.saved;
  }

  @override
  Future<Uint8List?> pick({required int maxBytes}) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    final fileLength = file.lengthSync() ?? await file.length();
    if (fileLength != null && fileLength > maxBytes) {
      throw const BackupFormatException(
        'O arquivo excede o limite de 10 MB. Escolha um backup menor.',
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw const BackupFormatException(
        'O arquivo excede o limite de 10 MB. Escolha um backup menor.',
      );
    }
    return bytes;
  }
}
